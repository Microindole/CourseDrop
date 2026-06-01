export { apiClient, ApiClient } from './ApiClient';
export { deviceDiscoveryService, LanDeviceDiscoveryService } from './device';
export type { DeviceDiscoveryService } from './device';
export { localLibraryService, IndexedLocalLibraryService } from './local';
export type { LibraryGrouping, LocalLibraryService } from './local';
export { relaySourceService, ConfigurableRelaySourceService } from './relay';
export type { RelaySourceService } from './relay';
export { identityService, IdentityService } from './identity';
export type { LocalIdentity, DeviceFingerprintResponse, IdentityRepository } from './identity';
export { roomService, RoomService } from './RoomService';
export { shareService, shareDraftWorkflow, LocalShareService } from './share';
export type { ShareDraftWorkflow, ShareOperationResult, ShareService, TransferStats } from './share';
export { transferService, DefaultTransferService } from './transfer';
export type { DownloadShareItemCommand, TransferService, UploadLocalFileCommand } from './transfer';
export { filePickerService, fileImportService, fileTypeResolver, localFileImportWorkflow } from './file';
export type {
  FileImportPlan,
  FileImportResult,
  FileImportService,
  FilePickerService,
  LocalFileImportResult,
  PickedFile
} from './file';
export { encryptionService, CourseDropEncryptionService } from './crypto';
export type { DecryptionPlan, DecryptionResult, EncryptionPlan, EncryptionResult, EncryptionService } from './crypto';
export { settingsService, SettingsService } from './settings';
export type { AppSettings, CachePolicy, SettingsRepository } from './settings';
export { cameraScanService, CameraScanService, qrPayloadParser, scanDispatchService, QrPayloadParser, ScanDispatchService } from './scan';
export type { CameraScanResult, QrPayload, QrPayloadType, ScanDispatchResult } from './scan';
export {
  AgentExecutor,
  AiConversationFactory,
  AiMessageFactory,
  AiMessageFormatter,
  BaseLlm,
  ChatMemory,
  DeepSeekModels,
  DeepSeekProvider,
  DefaultAiAssistantService,
  DefaultAiDocumentService,
  DefaultAiProviderConfig,
  DefaultAiRuntimeLimits,
  DocumentParserFactory,
  GetLocalFilesTool,
  LlmProviderFactory,
  OpenAIProvider,
  PreferencesAiConfigRepository,
  PreferencesAiMemoryRepository,
  SseClient,
  SseParser,
  TextDocumentParser,
  Tool,
  ToolRegistry,
  UnsupportedDocumentParser,
  aiAssistantService,
  aiConfigRepository,
  aiDocumentService,
  aiMemoryRepository
} from './ai';
export type {
  AgentExecutionOptions,
  AiAssistantService,
  AiConfigRepository,
  AiContentPart,
  AiContentPartType,
  AiConversation,
  AiConversationSummary,
  AiDocumentService,
  AiFileContext,
  AiMemoryRepository,
  AiMessage,
  AiMessageMetadata,
  AiMessageRole,
  AiProviderConfig,
  AiProviderType,
  AiRuntimeLimits,
  AiSendMessageCommand,
  AiSendMessageResult,
  AiToolCall,
  AiToolCallFunction,
  AiToolDefinition,
  AiToolDefinitionFunction,
  ChatMemorySnapshot,
  DocumentParseRequest,
  DocumentParseStatus,
  DocumentParser,
  DeepSeekProviderConfig,
  DeepSeekReasoningEffort,
  LlmChatOptions,
  LlmProviderConfig,
  LlmStreamCallbacks,
  OpenAIChatRequest,
  ParsedDocument,
  SseCallbacks,
  SseConnection,
  SseEvent,
  SseRequest,
  ToolRunContext
} from './ai';
