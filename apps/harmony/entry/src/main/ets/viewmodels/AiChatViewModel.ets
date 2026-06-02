import type { AiConversation, AiConversationSummary, AiMessage, AiProviderConfig, SseConnection } from '../services/ai';
import { aiAssistantService, aiConfigRepository, aiMemoryRepository, DefaultAiProviderConfig } from '../services/ai';

export type AiChatRole = 'user' | 'assistant';

export interface AiChatMessage {
  id: string;
  role: AiChatRole;
  content: string;
  streaming: boolean;
}

export interface AiChatConfigForm {
  enabled: boolean;
  apiKey: string;
  baseUrl: string;
  model: string;
  thinkingEnabled: boolean;
  autoAnalyzeFiles: boolean;
}

const AI_CHAT_SYSTEM_PROMPT: string =
  '你是一个通用 AI 聊天助手，运行在 CourseDrop 课递 App 内。' +
  '你的第一身份是通用助手，不是 CourseDrop 客服，也不是只能处理文件的助手。' +
  'CourseDrop、文件投递、分享、下载、诊断和安全设置只是你可以回答的一部分主题，不是回答范围限制。' +
  '当前没有文件、附件或文档上下文。你必须把用户消息当作普通文本问题处理。' +
  '无论问题是否与 CourseDrop 有关，都要直接回答。' +
  '禁止回复“请上传文件”“请提供文件”“我的核心能力是处理文件”或类似内容。' +
  '只有当用户明确说“分析这个文件”“总结附件”“读取文档内容”，并且当前确实没有文件上下文时，才可以说明需要先选择文件。' +
  '回答要自然、简洁、具体。';

export class AiChatViewModel {
  messages: AiChatMessage[] = [
    {
      id: 'assistant-welcome',
      role: 'assistant',
      content: '你好，我是课递助手。可以帮你整理传输思路、解释功能，或回答使用问题。',
      streaming: false
    }
  ];
  loading: boolean = false;
  errorMessage: string = '';

  private conversationId: string = '';
  private activeConnection?: SseConnection;

  getCurrentConversationId(): string {
    return this.conversationId;
  }

  getConfig(): AiChatConfigForm {
    const config = aiConfigRepository.getProviderConfig();
    const form: AiChatConfigForm = {
      enabled: config.enabled,
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      model: config.model,
      thinkingEnabled: config.thinkingEnabled,
      autoAnalyzeFiles: config.autoAnalyzeFiles
    };
    return form;
  }

  saveConfig(form: AiChatConfigForm): void {
    const defaults: AiProviderConfig = DefaultAiProviderConfig.create();
    const config: AiProviderConfig = {
      enabled: form.enabled,
      provider: 'DEEPSEEK',
      baseUrl: form.baseUrl.trim().length > 0 ? form.baseUrl.trim() : defaults.baseUrl,
      apiKey: form.apiKey.trim(),
      model: form.model.trim().length > 0 ? form.model.trim() : defaults.model,
      temperature: defaults.temperature,
      maxTokens: defaults.maxTokens,
      thinkingEnabled: form.thinkingEnabled,
      reasoningEffort: defaults.reasoningEffort,
      autoAnalyzeFiles: form.autoAnalyzeFiles
    };
    aiConfigRepository.saveProviderConfig(config);
  }

  listConversations(): AiConversationSummary[] {
    return aiMemoryRepository.list();
  }

  removeConversation(id: string): void {
    aiMemoryRepository.remove(id);
    if (this.conversationId === id) {
      this.clear();
    }
  }

  loadConversation(id: string): boolean {
    const conversation = aiMemoryRepository.findById(id);
    if (conversation === undefined) {
      return false;
    }
    this.conversationId = conversation.id;
    this.loading = false;
    this.errorMessage = '';
    const loaded: AiChatMessage[] = [];
    conversation.messages.forEach((message: AiMessage) => {
      if (message.role === 'user' || message.role === 'assistant') {
        const chatMessage: AiChatMessage = {
          id: message.id,
          role: message.role,
          content: message.content,
          streaming: false
        };
        loaded.push(chatMessage);
      }
    });
    this.messages = loaded.length > 0 ? loaded : this.createWelcomeMessages();
    return true;
  }

  getMessages(): AiChatMessage[] {
    return this.messages.map((message) => {
      const copy: AiChatMessage = {
        id: message.id,
        role: message.role,
        content: message.content,
        streaming: message.streaming
      };
      return copy;
    });
  }

  send(text: string, onUpdate: () => void): void {
    const content = text.trim();
    if (content.length === 0 || this.loading) {
      return;
    }
    this.ensureConversation();
    this.errorMessage = '';
    this.loading = true;

    const assistantId = this.createId('assistant');
    this.messages.push({
      id: this.createId('user'),
      role: 'user',
      content: content,
      streaming: false
    });
    this.messages.push({
      id: assistantId,
      role: 'assistant',
      content: '',
      streaming: true
    });
    onUpdate();

    const connection = aiAssistantService.streamMessage({
      conversationId: this.conversationId,
      content: content
    }, {
      onChunk: (chunk: string) => {
        this.appendToAssistant(assistantId, chunk);
        onUpdate();
      },
      onComplete: (_fullText: string) => {
        this.finishAssistant(assistantId);
        onUpdate();
      },
      onError: (error: Error) => {
        this.errorMessage = String(error.message);
        this.failAssistant(assistantId, this.errorMessage);
        onUpdate();
      }
    });

    if (connection !== undefined) {
      this.activeConnection = connection;
    }
  }

  stop(): void {
    if (this.activeConnection !== undefined) {
      this.activeConnection.close();
      this.activeConnection = undefined;
    }
    this.loading = false;
    this.messages = this.messages.map((message) => {
      if (message.streaming) {
        const stopped: AiChatMessage = {
          id: message.id,
          role: message.role,
          content: message.content.length > 0 ? message.content : '已停止生成。',
          streaming: false
        };
        return stopped;
      }
      return message;
    });
  }

  clear(): void {
    if (this.activeConnection !== undefined) {
      this.activeConnection.close();
      this.activeConnection = undefined;
    }
    this.conversationId = '';
    this.loading = false;
    this.errorMessage = '';
    this.messages = this.createWelcomeMessages();
  }

  private ensureConversation(): void {
    if (this.conversationId.length > 0) {
      return;
    }
    const conversation: AiConversation = aiAssistantService.createConversation(
      AI_CHAT_SYSTEM_PROMPT,
      'AI 助手'
    );
    this.conversationId = conversation.id;
  }

  private appendToAssistant(id: string, chunk: string): void {
    this.messages = this.messages.map((message) => {
      if (message.id === id) {
        const next: AiChatMessage = {
          id: message.id,
          role: message.role,
          content: `${message.content}${chunk}`,
          streaming: true
        };
        return next;
      }
      return message;
    });
  }

  private finishAssistant(id: string): void {
    this.activeConnection = undefined;
    this.loading = false;
    this.messages = this.messages.map((message) => {
      if (message.id === id) {
        const finished: AiChatMessage = {
          id: message.id,
          role: message.role,
          content: message.content.length > 0 ? message.content : '没有收到回复。',
          streaming: false
        };
        return finished;
      }
      return message;
    });
  }

  private failAssistant(id: string, messageText: string): void {
    this.activeConnection = undefined;
    this.loading = false;
    this.messages = this.messages.map((message) => {
      if (message.id === id) {
        const failed: AiChatMessage = {
          id: message.id,
          role: message.role,
          content: messageText.length > 0 ? messageText : 'AI 请求失败，请检查 API Key 和网络。',
          streaming: false
        };
        return failed;
      }
      return message;
    });
  }

  private createId(prefix: string): string {
    return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 1000000)}`;
  }

  private createWelcomeMessages(): AiChatMessage[] {
    return [
      {
        id: 'assistant-welcome',
        role: 'assistant',
        content: '你好，我是课递助手。可以帮你整理传输思路、解释功能，或回答使用问题。',
        streaming: false
      }
    ];
  }
}
