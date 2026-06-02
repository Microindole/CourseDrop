import { PreferencesAiConfigRepository } from './config';
import { PreferencesAiMemoryRepository } from './memory';
import { DefaultAiDocumentService, DocumentParserFactory } from './parsers';
import { DefaultAiAssistantService } from './AiAssistantService';

export {
  DefaultAiAssistantService
} from './AiAssistantService';
export type {
  AiAssistantService,
  AiSendMessageCommand,
  AiSendMessageResult
} from './AiAssistantService';
export {
  DeepSeekModels,
  DefaultAiProviderConfig,
  DefaultAiRuntimeLimits,
  PreferencesAiConfigRepository
} from './config';
export type {
  AiConfigRepository,
  AiProviderConfig,
  AiProviderType,
  AiRuntimeLimits,
  DeepSeekReasoningEffort
} from './config';
export {
  AiMessageFactory,
  AiMessageFormatter,
  BaseLlm,
  ChatMemory,
  SseClient,
  SseParser
} from './core';
export type {
  AiContentPart,
  AiContentPartType,
  AiFileContext,
  AiMessage,
  AiMessageMetadata,
  AiMessageRole,
  AiToolCall,
  AiToolCallFunction,
  AiToolDefinition,
  AiToolDefinitionFunction,
  ChatMemorySnapshot,
  LlmChatOptions,
  LlmProviderConfig,
  LlmStreamCallbacks,
  SseCallbacks,
  SseConnection,
  SseEvent,
  SseRequest
} from './core';
export {
  AiConversationFactory,
  PreferencesAiMemoryRepository
} from './memory';
export type {
  AiConversation,
  AiConversationSummary,
  AiMemoryRepository
} from './memory';
export {
  DefaultAiDocumentService,
  DocumentParserFactory,
  TextDocumentParser,
  UnsupportedDocumentParser
} from './parsers';
export type {
  AiDocumentService,
  DocumentParseRequest,
  DocumentParseStatus,
  DocumentParser,
  ParsedDocument
} from './parsers';
export {
  DeepSeekProvider,
  LlmProviderFactory,
  OpenAIProvider
} from './providers';
export type {
  DeepSeekProviderConfig,
  OpenAIChatRequest
} from './providers';
export {
  AgentExecutor,
  GetLocalFilesTool,
  Tool,
  ToolRegistry
} from './tools';
export type {
  AgentExecutionOptions,
  ToolRunContext
} from './tools';

export const aiConfigRepository = new PreferencesAiConfigRepository();
export const aiMemoryRepository = new PreferencesAiMemoryRepository();
export const aiDocumentService = new DefaultAiDocumentService(new DocumentParserFactory());
export const aiAssistantService = new DefaultAiAssistantService(
  aiConfigRepository,
  aiMemoryRepository,
  aiDocumentService
);
