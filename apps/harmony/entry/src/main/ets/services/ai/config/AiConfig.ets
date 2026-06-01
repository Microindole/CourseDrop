export type AiProviderType = 'DEEPSEEK' | 'OPENAI_COMPATIBLE' | 'OLLAMA';
export type DeepSeekReasoningEffort = 'low' | 'medium' | 'high';

export class DeepSeekModels {
  static readonly V4_FLASH: string = 'deepseek-v4-flash';
  static readonly V4_PRO: string = 'deepseek-v4-pro';
  static readonly LEGACY_CHAT: string = 'deepseek-chat';
  static readonly LEGACY_REASONER: string = 'deepseek-reasoner';
}

export interface AiProviderConfig {
  enabled: boolean;
  provider: AiProviderType;
  baseUrl: string;
  apiKey: string;
  model: string;
  temperature: number;
  maxTokens: number;
  thinkingEnabled: boolean;
  reasoningEffort: DeepSeekReasoningEffort;
}

export class DefaultAiProviderConfig {
  static create(): AiProviderConfig {
    return {
      enabled: false,
      provider: 'DEEPSEEK',
      baseUrl: 'https://api.deepseek.com',
      apiKey: '',
      model: DeepSeekModels.V4_FLASH,
      temperature: 0.3,
      maxTokens: 2048,
      thinkingEnabled: false,
      reasoningEffort: 'medium'
    };
  }
}

export interface AiRuntimeLimits {
  maxHistoryMessages: number;
  maxDocumentBytes: number;
  maxDocumentChars: number;
  maxSseReadTimeoutMs: number;
}

export class DefaultAiRuntimeLimits {
  static create(): AiRuntimeLimits {
    return {
      maxHistoryMessages: 20,
      maxDocumentBytes: 1024 * 1024,
      maxDocumentChars: 24000,
      maxSseReadTimeoutMs: 120000
    };
  }
}
