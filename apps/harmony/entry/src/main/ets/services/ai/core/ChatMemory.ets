import { AiMessageFactory } from './AiMessage';
import type { AiFileContext, AiMessage } from './AiMessage';

export interface ChatMemorySnapshot {
  systemPrompt: string;
  messages: AiMessage[];
}

export class ChatMemory {
  private history: AiMessage[] = [];
  private systemPrompt: string;
  private maxHistoryMessages: number;

  constructor(systemPrompt?: string, maxHistoryMessages?: number) {
    this.systemPrompt = systemPrompt !== undefined ? systemPrompt : '你是 CourseDrop 课递的移动端 AI 助手。没有文件上下文时，直接按普通文本问题回答。';
    this.maxHistoryMessages = maxHistoryMessages !== undefined ? maxHistoryMessages : 20;
  }

  setSystemPrompt(systemPrompt: string): void {
    this.systemPrompt = systemPrompt;
  }

  addMessage(message: AiMessage): void {
    this.history.push(message);
    this.trimHistory();
  }

  addUserMessage(content: string, fileContexts?: AiFileContext[]): AiMessage {
    const parts = fileContexts !== undefined && fileContexts.length > 0 ?
      fileContexts.map((file: AiFileContext) => AiMessageFactory.fileContext(file)) :
      undefined;
    const message = AiMessageFactory.user(content, parts);
    this.addMessage(message);
    return message;
  }

  addAssistantMessage(content: string): AiMessage {
    const message = AiMessageFactory.assistant(content);
    this.addMessage(message);
    return message;
  }

  getMessagesForModel(): AiMessage[] {
    const prompt = this.systemPrompt;
    return [
      AiMessageFactory.system(prompt),
      ...this.history
    ];
  }

  snapshot(): ChatMemorySnapshot {
    return {
      systemPrompt: this.systemPrompt,
      messages: [...this.history]
    };
  }

  restore(snapshot: ChatMemorySnapshot): void {
    this.systemPrompt = snapshot.systemPrompt;
    this.history = [...snapshot.messages];
    this.trimHistory();
  }

  clear(): void {
    this.history = [];
  }

  private trimHistory(): void {
    while (this.history.length > this.maxHistoryMessages) {
      this.history.shift();
    }
  }
}
