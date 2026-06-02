export type DocumentParseStatus = 'OK' | 'TRUNCATED' | 'UNSUPPORTED' | 'FAILED';

export interface DocumentParseRequest {
  id: string;
  displayName: string;
  localUri: string;
  mimeType: string;
  sizeBytes: number;
  maxBytes: number;
  maxChars: number;
}

export interface ParsedDocument {
  id: string;
  displayName: string;
  mimeType: string;
  sizeBytes: number;
  text: string;
  summary: string;
  status: DocumentParseStatus;
  errorMessage?: string;
}

export interface DocumentParser {
  supports(mimeType: string, displayName: string): boolean;
  parse(request: DocumentParseRequest): ParsedDocument;
}
