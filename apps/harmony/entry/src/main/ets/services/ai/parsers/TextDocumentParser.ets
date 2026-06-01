import { FileSystemService } from '../../file';
import type { DocumentParseRequest, DocumentParser, ParsedDocument } from './DocumentModels';

export class TextDocumentParser implements DocumentParser {
  private fileSystemService: FileSystemService;

  constructor(fileSystemService: FileSystemService) {
    this.fileSystemService = fileSystemService;
  }

  supports(mimeType: string, displayName: string): boolean {
    const normalizedType = mimeType.toLowerCase();
    const normalizedName = displayName.toLowerCase();
    if (normalizedType.startsWith('text/')) {
      return true;
    }
    if (normalizedType.includes('json') || normalizedType.includes('xml') || normalizedType.includes('csv')) {
      return true;
    }
    return normalizedName.endsWith('.txt') ||
      normalizedName.endsWith('.md') ||
      normalizedName.endsWith('.json') ||
      normalizedName.endsWith('.csv') ||
      normalizedName.endsWith('.log') ||
      normalizedName.endsWith('.xml') ||
      normalizedName.endsWith('.yaml') ||
      normalizedName.endsWith('.yml');
  }

  parse(request: DocumentParseRequest): ParsedDocument {
    try {
      if (request.sizeBytes > request.maxBytes) {
        return this.unsupported(request, `文件超过 AI 文本读取上限 ${request.maxBytes} bytes`);
      }
      const buffer = this.fileSystemService.readAll(request.localUri);
      const text = this.decodeUtf8(new Uint8Array(buffer));
      const truncated = text.length > request.maxChars;
      const finalText = truncated ? text.substring(0, request.maxChars) : text;
      return {
        id: request.id,
        displayName: request.displayName,
        mimeType: request.mimeType,
        sizeBytes: request.sizeBytes,
        text: finalText,
        summary: this.createSummary(finalText),
        status: truncated ? 'TRUNCATED' : 'OK'
      };
    } catch (error) {
      return {
        id: request.id,
        displayName: request.displayName,
        mimeType: request.mimeType,
        sizeBytes: request.sizeBytes,
        text: '',
        summary: '',
        status: 'FAILED',
        errorMessage: String(error)
      };
    }
  }

  private unsupported(request: DocumentParseRequest, message: string): ParsedDocument {
    return {
      id: request.id,
      displayName: request.displayName,
      mimeType: request.mimeType,
      sizeBytes: request.sizeBytes,
      text: '',
      summary: '',
      status: 'UNSUPPORTED',
      errorMessage: message
    };
  }

  private createSummary(text: string): string {
    const normalized = text.replace(/\r\n/g, '\n').trim();
    if (normalized.length <= 240) {
      return normalized;
    }
    return `${normalized.substring(0, 240)}...`;
  }

  private decodeUtf8(bytes: Uint8Array): string {
    let text = '';
    let index = 0;
    while (index < bytes.length) {
      const first = bytes[index];
      if (first < 0x80) {
        text += String.fromCharCode(first);
        index += 1;
      } else if ((first & 0xe0) === 0xc0 && index + 1 < bytes.length) {
        const second = bytes[index + 1];
        text += String.fromCharCode(((first & 0x1f) << 6) | (second & 0x3f));
        index += 2;
      } else if ((first & 0xf0) === 0xe0 && index + 2 < bytes.length) {
        const second = bytes[index + 1];
        const third = bytes[index + 2];
        text += String.fromCharCode(((first & 0x0f) << 12) | ((second & 0x3f) << 6) | (third & 0x3f));
        index += 3;
      } else if ((first & 0xf8) === 0xf0 && index + 3 < bytes.length) {
        const second = bytes[index + 1];
        const third = bytes[index + 2];
        const fourth = bytes[index + 3];
        const codePoint = ((first & 0x07) << 18) | ((second & 0x3f) << 12) | ((third & 0x3f) << 6) | (fourth & 0x3f);
        const offset = codePoint - 0x10000;
        text += String.fromCharCode(0xd800 + (offset >> 10), 0xdc00 + (offset & 0x3ff));
        index += 4;
      } else {
        index += 1;
      }
    }
    return text;
  }
}
