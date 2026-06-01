import type { AiMessage, AiToolCall } from './AiMessage';
import type { SseConnection } from './SseClient';

export interface AiToolDefinitionFunction {
  name: string;
  description: string;
  parameters: object;
}

export interface AiToolDefinition {
  type: 'function';
  function: AiToolDefinitionFunction;
}

export interface LlmChatOptions {
  model?: string;
  temperature?: number;
  maxTokens?: number;
  stream?: boolean;
  tools?: AiToolDefinition[];
}

export interface LlmStreamCallbacks {
  onChunk: (text: string) => void;
  onToolCall?: (toolCall: AiToolCall) => void;
  onComplete: (fullText: string) => void;
  onError: (error: Error) => void;
}

export interface LlmProviderConfig {
  baseUrl: string;
  apiKey: string;
  model: string;
}

export abstract class BaseLlm {
  protected baseUrl: string;
  protected apiKey: string;
  protected model: string;

  constructor(config: LlmProviderConfig) {
    this.baseUrl = config.baseUrl.replace(/\/$/, '');
    this.apiKey = config.apiKey;
    this.model = config.model;
  }

  abstract chat(messages: AiMessage[], options?: LlmChatOptions): Promise<AiMessage>;

  abstract chatStream(
    messages: AiMessage[],
    callbacks: LlmStreamCallbacks,
    options?: LlmChatOptions
  ): SseConnection | void;
}
