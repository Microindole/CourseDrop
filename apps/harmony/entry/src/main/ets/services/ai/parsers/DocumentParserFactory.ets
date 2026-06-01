import { fileSystemService } from '../../file';
import type { DocumentParser } from './DocumentModels';
import { TextDocumentParser } from './TextDocumentParser';
import { UnsupportedDocumentParser } from './UnsupportedDocumentParser';

export class DocumentParserFactory {
  private parsers: DocumentParser[];

  constructor(parsers?: DocumentParser[]) {
    this.parsers = parsers !== undefined ? parsers : [
      new TextDocumentParser(fileSystemService),
      new UnsupportedDocumentParser()
    ];
  }

  getParser(mimeType: string, displayName: string): DocumentParser {
    const parser = this.parsers.find((candidate) => candidate.supports(mimeType, displayName));
    if (parser !== undefined) {
      return parser;
    }
    return new UnsupportedDocumentParser();
  }
}
