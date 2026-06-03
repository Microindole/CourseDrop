import type { LocalFileEntry } from '../../models/LocalFileEntry';
import {
  AiMessageFactory
} from './core';
import type { AiMessage } from './core';
import type { AiConfigRepository } from './config';
import type { AiDocumentService, ParsedDocument } from './parsers';
import { LlmProviderFactory } from './providers';

export interface AiFileSummaryCommand {
  file: LocalFileEntry;
  instruction?: string;
}

export interface AiFileSummaryResult {
  fileId: string;
  displayName: string;
  mimeType: string;
  sizeBytes: number;
  parseStatus: string;
  parserSummary: string;
  modelSummary: string;
  extractedTextLength: number;
  truncated: boolean;
  errorMessage: string;
}

export interface AiFileAnalysisService {
  summarizeFile(command: AiFileSummaryCommand): Promise<AiFileSummaryResult>;
}

const AI_FILE_SUMMARY_SYSTEM_PROMPT: string =
  '你是 CourseDrop 课递的文件分析助手。' +
  '你会基于给定文件内容输出中文总结。' +
  '要求：1. 先给一句话概括；2. 列出关键要点；3. 如有任务、风险、时间、金额、链接或配置项，单独列出；4. 不要编造文件中没有的信息。';

export class DefaultAiFileAnalysisService implements AiFileAnalysisService {
  private configRepository: AiConfigRepository;
  private documentService: AiDocumentService;
  private providerFactory: LlmProviderFactory;

  constructor(
    configRepository: AiConfigRepository,
    documentService: AiDocumentService,
    providerFactory?: LlmProviderFactory
  ) {
    this.configRepository = configRepository;
    this.documentService = documentService;
    this.providerFactory = providerFactory !== undefined ? providerFactory : new LlmProviderFactory();
  }

  async summarizeFile(command: AiFileSummaryCommand): Promise<AiFileSummaryResult> {
    const limits = this.configRepository.getRuntimeLimits();
    const document = this.documentService.parseLocalFile(command.file, limits);
    if (document.status === 'FAILED' || document.status === 'UNSUPPORTED') {
      return this.failedResult(document, document.errorMessage === undefined ? '文件无法读取或暂不支持' : document.errorMessage);
    }
    if (document.text.trim().length === 0) {
      return this.failedResult(document, '文件内容为空，无法生成总结');
    }

    const providerConfig = this.configRepository.getProviderConfig();
    if (!providerConfig.enabled || providerConfig.apiKey.length === 0) {
      return this.offlineResult(document, 'AI 服务未配置或未启用，已返回本地摘要');
    }

    const provider = this.providerFactory.create(providerConfig);
    const userPrompt = this.buildUserPrompt(document, command.instruction);
    const messages: AiMessage[] = [
      AiMessageFactory.system(AI_FILE_SUMMARY_SYSTEM_PROMPT),
      AiMessageFactory.user(userPrompt)
    ];
    const assistant = await provider.chat(messages, {
      temperature: providerConfig.temperature,
      maxTokens: providerConfig.maxTokens
    });
    return this.successResult(document, assistant.content, '');
  }

  private buildUserPrompt(document: ParsedDocument, instruction?: string): string {
    let prompt = `请总结这个文件。\n文件名：${document.displayName}\nMIME：${document.mimeType}\n大小：${document.sizeBytes} bytes\n解析状态：${document.status}`;
    if (instruction !== undefined && instruction.trim().length > 0) {
      prompt += `\n用户要求：${instruction.trim()}`;
    }
    if (document.summary.length > 0) {
      prompt += `\n本地摘要：${document.summary}`;
    }
    prompt += `\n\n文件内容：\n${document.text}`;
    return prompt;
  }

  private successResult(document: ParsedDocument, modelSummary: string, errorMessage: string): AiFileSummaryResult {
    const result: AiFileSummaryResult = {
      fileId: document.id,
      displayName: document.displayName,
      mimeType: document.mimeType,
      sizeBytes: document.sizeBytes,
      parseStatus: document.status,
      parserSummary: document.summary,
      modelSummary: modelSummary,
      extractedTextLength: document.text.length,
      truncated: document.status === 'TRUNCATED',
      errorMessage: errorMessage
    };
    return result;
  }

  private offlineResult(document: ParsedDocument, errorMessage: string): AiFileSummaryResult {
    return this.successResult(document, document.summary, errorMessage);
  }

  private failedResult(document: ParsedDocument, errorMessage: string): AiFileSummaryResult {
    return this.successResult(document, '', errorMessage);
  }
}
