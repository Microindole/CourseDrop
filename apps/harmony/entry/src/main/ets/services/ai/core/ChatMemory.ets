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
    this.systemPrompt = systemPrompt !== undefined ? systemPrompt : '你是 CourseDrop 的文件投递与文档分析助手。';
    this.maxHistoryMessages = maxHistoryMessages !== undefined ? maxHistoryMessages : 20;
  }

  setSystemPrompt(systemPrompt: string): void {
    this.systemPrompt = systemPrompt;
  }

  addMessage(message: AiMessage): void {
    this.history.push(message);
    this.trimHistory();
  }

  addUserMessage(content: string): AiMessage {
    const message = AiMessageFactory.user(content);
    this.addMessage(message);
    return message;
  }

  addAssistantMessage(content: string): AiMessage {
    const message = AiMessageFactory.assistant(content);
    this.addMessage(message);
    return message;
  }

  getMessagesForModel(fileContexts?: AiFileContext[]): AiMessage[] {
    let prompt = this.systemPrompt;
    if (fileContexts !== undefined && fileContexts.length > 0) {
      prompt += this.formatFileContexts(fileContexts);
    }
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

  private formatFileContexts(files: AiFileContext[]): string {
    let text = '\n\n[当前关联文件]\n';
    for (const file of files) {
      text += `- ${file.displayName} (${file.mimeType}, ${file.sizeBytes} bytes)`;
      if (file.summary !== undefined && file.summary.length > 0) {
        text += `\n  摘要: ${file.summary}`;
      }
      if (file.extractedText !== undefined && file.extractedText.length > 0) {
        text += `\n  内容:\n${file.extractedText}`;
      }
      text += '\n';
    }
    text += '[当前关联文件结束]';
    return text;
  }
}
