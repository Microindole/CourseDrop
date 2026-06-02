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

const AI_TEXT_CHAT_SYSTEM_PROMPT: string =
  '你是一个通用 AI 聊天助手，运行在 CourseDrop 课递 App 内。' +
  '你的第一身份是通用助手，不是 CourseDrop 客服，也不是只能处理文件的助手。' +
  'CourseDrop、文件投递、分享、下载、诊断和安全设置只是你可以回答的一部分主题，不是回答范围限制。' +
  '当前没有文件、附件或文档上下文。你必须把用户消息当作普通文本问题处理。' +
  '无论问题是否与 CourseDrop 有关，都要直接回答。' +
  '禁止回复“请上传文件”“请提供文件”“我的核心能力是处理文件”或类似内容。' +
  '只有当用户明确说“分析这个文件”“总结附件”“读取文档内容”，并且当前确实没有文件上下文时，才可以说明需要先选择文件。' +
  '回答要自然、简洁、具体。';

const AI_FILE_CONTEXT_SYSTEM_PROMPT: string =
  '你是 CourseDrop 课递 App 内置的文件与文本助手。当前包含文件上下文时，可以基于文件内容分析；没有文件上下文时，直接按普通文本问题回答。';

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
    const prompt = systemPrompt !== undefined ? systemPrompt : AI_TEXT_CHAT_SYSTEM_PROMPT;
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
    const memory = this.createMemory(conversation, fileContexts.length > 0);
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
      const memory = this.createMemory(conversation, fileContexts.length > 0);
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

  private createMemory(conversation: AiConversation, hasFileContext: boolean): ChatMemory {
    const limits = this.configRepository.getRuntimeLimits();
    const systemPrompt = hasFileContext ? AI_FILE_CONTEXT_SYSTEM_PROMPT : AI_TEXT_CHAT_SYSTEM_PROMPT;
    conversation.systemPrompt = systemPrompt;
    const memory = new ChatMemory(systemPrompt, limits.maxHistoryMessages);
    memory.restore({
      systemPrompt: systemPrompt,
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
