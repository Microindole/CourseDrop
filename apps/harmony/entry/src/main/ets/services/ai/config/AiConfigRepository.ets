import { appPreferencesStore } from '../../../common/AppPreferencesStore';
import { AiProviderConfig, AiRuntimeLimits, DefaultAiProviderConfig, DefaultAiRuntimeLimits } from './AiConfig';

const KEY_AI_PROVIDER_CONFIG: string = 'settings.ai.provider';
const KEY_AI_RUNTIME_LIMITS: string = 'settings.ai.runtime_limits';

export interface AiConfigRepository {
  getProviderConfig(): AiProviderConfig;
  saveProviderConfig(config: AiProviderConfig): void;
  getRuntimeLimits(): AiRuntimeLimits;
  saveRuntimeLimits(limits: AiRuntimeLimits): void;
}

export class PreferencesAiConfigRepository implements AiConfigRepository {
  getProviderConfig(): AiProviderConfig {
    const defaults = DefaultAiProviderConfig.create();
    const jsonText = appPreferencesStore.getString(KEY_AI_PROVIDER_CONFIG, '');
    if (jsonText.length === 0) {
      return defaults;
    }
    try {
      const config = JSON.parse(jsonText) as AiProviderConfig;
      return {
        enabled: config.enabled !== undefined ? config.enabled : defaults.enabled,
        provider: config.provider !== undefined ? config.provider : defaults.provider,
        baseUrl: config.baseUrl !== undefined ? config.baseUrl : defaults.baseUrl,
        apiKey: config.apiKey !== undefined ? config.apiKey : defaults.apiKey,
        model: config.model !== undefined ? config.model : defaults.model,
        temperature: config.temperature !== undefined ? config.temperature : defaults.temperature,
        maxTokens: config.maxTokens !== undefined ? config.maxTokens : defaults.maxTokens,
        thinkingEnabled: config.thinkingEnabled !== undefined ? config.thinkingEnabled : defaults.thinkingEnabled,
        reasoningEffort: config.reasoningEffort !== undefined ? config.reasoningEffort : defaults.reasoningEffort,
        autoAnalyzeFiles: config.autoAnalyzeFiles !== undefined ? config.autoAnalyzeFiles : defaults.autoAnalyzeFiles
      };
    } catch (error) {
      console.error(`[CourseDrop] load AI provider config failed: ${String(error)}`);
      return defaults;
    }
  }

  saveProviderConfig(config: AiProviderConfig): void {
    appPreferencesStore.putString(KEY_AI_PROVIDER_CONFIG, JSON.stringify(config));
  }

  getRuntimeLimits(): AiRuntimeLimits {
    const defaults = DefaultAiRuntimeLimits.create();
    const jsonText = appPreferencesStore.getString(KEY_AI_RUNTIME_LIMITS, '');
    if (jsonText.length === 0) {
      return defaults;
    }
    try {
      const limits = JSON.parse(jsonText) as AiRuntimeLimits;
      return {
        maxHistoryMessages: limits.maxHistoryMessages,
        maxDocumentBytes: limits.maxDocumentBytes,
        maxDocumentChars: limits.maxDocumentChars,
        maxSseReadTimeoutMs: limits.maxSseReadTimeoutMs
      };
    } catch (error) {
      console.error(`[CourseDrop] load AI runtime limits failed: ${String(error)}`);
      return defaults;
    }
  }

  saveRuntimeLimits(limits: AiRuntimeLimits): void {
    appPreferencesStore.putString(KEY_AI_RUNTIME_LIMITS, JSON.stringify(limits));
  }
}
