import type { DocumentParseRequest, DocumentParser, ParsedDocument } from './DocumentModels';

export class UnsupportedDocumentParser implements DocumentParser {
  supports(_mimeType: string, _displayName: string): boolean {
    return true;
  }

  parse(request: DocumentParseRequest): ParsedDocument {
    return {
      id: request.id,
      displayName: request.displayName,
      mimeType: request.mimeType,
      sizeBytes: request.sizeBytes,
      text: '',
      summary: '',
      status: 'UNSUPPORTED',
      errorMessage: '当前 AI 基础设施只支持文本类文档，PDF/DOCX 后续接入专用解析器。'
    };
  }
}
