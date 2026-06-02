import type { AiMessage } from '../core';

export interface AiConversation {
  id: string;
  title: string;
  systemPrompt: string;
  messages: AiMessage[];
  createdAt: number;
  updatedAt: number;
  documentIds: string[];
}

export interface AiConversationSummary {
  id: string;
  title: string;
  createdAt: number;
  updatedAt: number;
  messageCount: number;
  documentCount: number;
}

export class AiConversationFactory {
  static create(systemPrompt: string, title?: string): AiConversation {
    const now = Date.now();
    return {
      id: `ai-conv-${now}-${Math.floor(Math.random() * 1000000)}`,
      title: title !== undefined && title.length > 0 ? title : '新的 AI 对话',
      systemPrompt: systemPrompt,
      messages: [],
      createdAt: now,
      updatedAt: now,
      documentIds: []
    };
  }

  static summarize(conversation: AiConversation): AiConversationSummary {
    return {
      id: conversation.id,
      title: conversation.title,
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
      messageCount: conversation.messages.length,
      documentCount: conversation.documentIds.length
    };
  }
}
