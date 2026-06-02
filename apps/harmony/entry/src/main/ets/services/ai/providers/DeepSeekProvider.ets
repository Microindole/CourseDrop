import type { DeepSeekReasoningEffort } from '../config';
import type { LlmChatOptions, LlmProviderConfig } from '../core';
import { OpenAIProvider } from './OpenAIProvider';
import type { OpenAIChatRequest, OpenAIThinkingOptions } from './OpenAIProvider';

export interface DeepSeekProviderConfig extends LlmProviderConfig {
  thinkingEnabled: boolean;
  reasoningEffort: DeepSeekReasoningEffort;
}

export class DeepSeekProvider extends OpenAIProvider {
  private thinkingEnabled: boolean;
  private reasoningEffort: DeepSeekReasoningEffort;

  constructor(config: DeepSeekProviderConfig) {
    super(config);
    this.thinkingEnabled = config.thinkingEnabled;
    this.reasoningEffort = config.reasoningEffort;
  }

  protected applyProviderOptions(request: OpenAIChatRequest, _options?: LlmChatOptions): void {
    if (!this.thinkingEnabled) {
      return;
    }
    request.reasoning_effort = this.reasoningEffort;
    const thinking: OpenAIThinkingOptions = {
      type: 'enabled'
    };
    request.thinking = thinking;
  }
}
