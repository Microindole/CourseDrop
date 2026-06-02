import { appPreferencesStore } from '../../../common/AppPreferencesStore';
import { AiConversation, AiConversationFactory, AiConversationSummary } from './AiConversation';

const KEY_AI_CONVERSATIONS: string = 'ai.memory.conversations';

export interface AiMemoryRepository {
  list(): AiConversationSummary[];
  findById(id: string): AiConversation | undefined;
  save(conversation: AiConversation): void;
  remove(id: string): void;
  clear(): void;
}

export class PreferencesAiMemoryRepository implements AiMemoryRepository {
  list(): AiConversationSummary[] {
    return this.loadAll()
      .sort((left, right) => right.updatedAt - left.updatedAt)
      .map((conversation) => AiConversationFactory.summarize(conversation));
  }

  findById(id: string): AiConversation | undefined {
    const conversation = this.loadAll().find((next) => next.id === id);
    if (conversation === undefined) {
      return undefined;
    }
    return this.copyConversation(conversation);
  }

  save(conversation: AiConversation): void {
    const conversations = this.loadAll();
    const next = this.copyConversation(conversation);
    next.updatedAt = Date.now();
    const index = conversations.findIndex((item) => item.id === next.id);
    if (index < 0) {
      conversations.push(next);
    } else {
      conversations[index] = next;
    }
    appPreferencesStore.putString(KEY_AI_CONVERSATIONS, JSON.stringify(conversations));
  }

  remove(id: string): void {
    const conversations = this.loadAll().filter((conversation) => conversation.id !== id);
    appPreferencesStore.putString(KEY_AI_CONVERSATIONS, JSON.stringify(conversations));
  }

  clear(): void {
    appPreferencesStore.putString(KEY_AI_CONVERSATIONS, '[]');
  }

  private loadAll(): AiConversation[] {
    const jsonText = appPreferencesStore.getString(KEY_AI_CONVERSATIONS, '[]');
    try {
      const conversations = JSON.parse(jsonText) as AiConversation[];
      return conversations.map((conversation) => this.copyConversation(conversation));
    } catch (error) {
      console.error(`[CourseDrop] load AI conversations failed: ${String(error)}`);
      return [];
    }
  }

  private copyConversation(conversation: AiConversation): AiConversation {
    return {
      id: conversation.id,
      title: conversation.title,
      systemPrompt: conversation.systemPrompt,
      messages: [...conversation.messages],
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
      documentIds: [...conversation.documentIds]
    };
  }
}
