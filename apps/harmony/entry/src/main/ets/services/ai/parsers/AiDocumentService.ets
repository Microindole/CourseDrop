import type { LocalFileEntry } from '../../../models/LocalFileEntry';
import type { AiFileContext } from '../core';
import type { AiRuntimeLimits } from '../config';
import { DocumentParserFactory } from './DocumentParserFactory';
import type { ParsedDocument } from './DocumentModels';

export interface AiDocumentService {
  parseLocalFile(file: LocalFileEntry, limits: AiRuntimeLimits): ParsedDocument;
  toFileContext(document: ParsedDocument): AiFileContext;
}

export class DefaultAiDocumentService implements AiDocumentService {
  private parserFactory: DocumentParserFactory;

  constructor(parserFactory: DocumentParserFactory) {
    this.parserFactory = parserFactory;
  }

  parseLocalFile(file: LocalFileEntry, limits: AiRuntimeLimits): ParsedDocument {
    const parser = this.parserFactory.getParser(file.contentType, file.displayName);
    return parser.parse({
      id: file.id,
      displayName: file.displayName,
      localUri: file.localUri,
      mimeType: file.contentType,
      sizeBytes: file.sizeBytes,
      maxBytes: limits.maxDocumentBytes,
      maxChars: limits.maxDocumentChars
    });
  }

  toFileContext(document: ParsedDocument): AiFileContext {
    return {
      id: document.id,
      displayName: document.displayName,
      mimeType: document.mimeType,
      sizeBytes: document.sizeBytes,
      extractedText: document.text,
      summary: document.summary,
      parseStatus: document.status,
      errorMessage: document.errorMessage
    };
  }
}
