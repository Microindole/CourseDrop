import type { AiProviderConfig } from '../config';
import { BaseLlm } from '../core';
import { DeepSeekProvider } from './DeepSeekProvider';
import { OpenAIProvider } from './OpenAIProvider';

export class LlmProviderFactory {
  create(config: AiProviderConfig): BaseLlm {
    if (config.provider === 'DEEPSEEK') {
      return new DeepSeekProvider({
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
        model: config.model,
        thinkingEnabled: config.thinkingEnabled,
        reasoningEffort: config.reasoningEffort
      });
    }
    if (config.provider === 'OPENAI_COMPATIBLE') {
      return new OpenAIProvider({
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
        model: config.model
      });
    }
    throw new Error('Ollama Provider 入口已预留，但当前尚未接入 /api/chat 协议。');
  }
}
