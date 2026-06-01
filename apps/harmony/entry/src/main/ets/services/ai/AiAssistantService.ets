import type { LocalFileEntry } from '../../models/LocalFileEntry';
import {
  AiMessageFactory,
  ChatMemory,
} from './core';
import type {
  AiFileContext,
  AiMessage,
  LlmStreamCallbacks,
  SseConnection
} from './core';
import type { AiConfigRepository } from './config';
import { AiConversationFactory } from './memory';
import type { AiConversation, AiMemoryRepository } from './memory';
import type { AiDocumentService } from './parsers';
import { LlmProviderFactory } from './providers';

export interface AiSendMessageCommand {
  conversationId?: string;
  content: string;
  files?: LocalFileEntry[];
}

export interface AiSendMessageResult {
  conversation: AiConversation;
  assistantMessage: AiMessage;
  fileContexts: AiFileContext[];
}

export interface AiAssistantService {
  createConversation(systemPrompt?: string, title?: string): AiConversation;
  sendMessage(command: AiSendMessageCommand): Promise<AiSendMessageResult>;
  streamMessage(command: AiSendMessageCommand, callbacks: LlmStreamCallbacks): SseConnection | undefined;
}

export class DefaultAiAssistantService implements AiAssistantService {
  private configRepository: AiConfigRepository;
  private memoryRepository: AiMemoryRepository;
  private documentService: AiDocumentService;
  private providerFactory: LlmProviderFactory;

  constructor(
    configRepository: AiConfigRepository,
    memoryRepository: AiMemoryRepository,
    documentService: AiDocumentService,
    providerFactory?: LlmProviderFactory
  ) {
    this.configRepository = configRepository;
    this.memoryRepository = memoryRepository;
    this.documentService = documentService;
    this.providerFactory = providerFactory !== undefined ? providerFactory : new LlmProviderFactory();
  }

  createConversation(systemPrompt?: string, title?: string): AiConversation {
    const prompt = systemPrompt !== undefined ? systemPrompt : '你是 CourseDrop 的文件投递与文档分析助手。';
    const conversation = AiConversationFactory.create(prompt, title);
    this.memoryRepository.save(conversation);
    return conversation;
  }

  async sendMessage(command: AiSendMessageCommand): Promise<AiSendMessageResult> {
    const providerConfig = this.configRepository.getProviderConfig();
    if (!providerConfig.enabled || providerConfig.apiKey.length === 0) {
      throw new Error('AI 服务未配置或未启用');
    }
    const conversation = this.loadOrCreate(command.conversationId);
    const fileContexts = this.parseFileContexts(command.files);
    const memory = this.createMemory(conversation);
    memory.addUserMessage(command.content);

    const provider = this.providerFactory.create(providerConfig);
    const assistantMessage = await provider.chat(memory.getMessagesForModel(fileContexts), {
      temperature: providerConfig.temperature,
      maxTokens: providerConfig.maxTokens
    });
    memory.addMessage(assistantMessage);
    this.persistConversation(conversation, memory.snapshot().messages, fileContexts);
    return {
      conversation: conversation,
      assistantMessage: assistantMessage,
      fileContexts: fileContexts
    };
  }

  streamMessage(command: AiSendMessageCommand, callbacks: LlmStreamCallbacks): SseConnection | undefined {
    try {
      const providerConfig = this.configRepository.getProviderConfig();
      if (!providerConfig.enabled || providerConfig.apiKey.length === 0) {
        callbacks.onError(new Error('AI 服务未配置或未启用'));
        return undefined;
      }
      const conversation = this.loadOrCreate(command.conversationId);
      const fileContexts = this.parseFileContexts(command.files);
      const memory = this.createMemory(conversation);
      memory.addUserMessage(command.content);
      let assistantText = '';

      const provider = this.providerFactory.create(providerConfig);

      return provider.chatStream(memory.getMessagesForModel(fileContexts), {
        onChunk: (text) => {
          assistantText += text;
          callbacks.onChunk(text);
        },
        onToolCall: callbacks.onToolCall,
        onComplete: (_fullText) => {
          memory.addMessage(AiMessageFactory.assistant(assistantText));
          this.persistConversation(conversation, memory.snapshot().messages, fileContexts);
          callbacks.onComplete(assistantText);
        },
        onError: (error) => callbacks.onError(error)
      }, {
        temperature: providerConfig.temperature,
        maxTokens: providerConfig.maxTokens
      });
    } catch (error) {
      callbacks.onError(new Error(String(error)));
      return undefined;
    }
  }

  private loadOrCreate(conversationId?: string): AiConversation {
    if (conversationId !== undefined) {
      const existing = this.memoryRepository.findById(conversationId);
      if (existing !== undefined) {
        return existing;
      }
    }
    return this.createConversation();
  }

  private createMemory(conversation: AiConversation): ChatMemory {
    const limits = this.configRepository.getRuntimeLimits();
    const memory = new ChatMemory(conversation.systemPrompt, limits.maxHistoryMessages);
    memory.restore({
      systemPrompt: conversation.systemPrompt,
      messages: conversation.messages
    });
    return memory;
  }

  private parseFileContexts(files?: LocalFileEntry[]): AiFileContext[] {
    if (files === undefined || files.length === 0) {
      return [];
    }
    const limits = this.configRepository.getRuntimeLimits();
    return files.map((file) => this.documentService.toFileContext(this.documentService.parseLocalFile(file, limits)));
  }

  private persistConversation(conversation: AiConversation, messages: AiMessage[], fileContexts: AiFileContext[]): void {
    conversation.messages = messages;
    fileContexts.forEach((context) => {
      if (!conversation.documentIds.includes(context.id)) {
        conversation.documentIds.push(context.id);
      }
    });
    this.memoryRepository.save(conversation);
  }
}
