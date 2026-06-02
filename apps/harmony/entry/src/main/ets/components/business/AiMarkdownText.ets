import { AppColors, AppRadius, AppSpacing, AppTypography } from '../../common/Theme';
import { clipboardService } from '../../services/clipboard';

type AiMarkdownBlockType = 'paragraph' | 'heading' | 'code' | 'hr' | 'list' | 'table';
type AiMarkdownInlineType = 'text' | 'bold' | 'italic' | 'code' | 'link';
type AiCodeTokenType = 'plain' | 'keyword' | 'string' | 'number' | 'comment' | 'operator';

interface AiMarkdownBlock {
  type: AiMarkdownBlockType;
  text: string;
  level: number;
  language: string;
  rows: string[][];
  ordered: boolean;
  marker: string;
}

interface AiMarkdownInline {
  type: AiMarkdownInlineType;
  text: string;
  href: string;
}

interface AiCodeToken {
  type: AiCodeTokenType;
  text: string;
}

class AiMarkdownBlockFactory {
  static paragraph(text: string): AiMarkdownBlock {
    return AiMarkdownBlockFactory.create('paragraph', text, 0, '', [], false, '');
  }

  static heading(text: string, level: number): AiMarkdownBlock {
    return AiMarkdownBlockFactory.create('heading', text, level, '', [], false, '');
  }

  static code(text: string, language: string): AiMarkdownBlock {
    return AiMarkdownBlockFactory.create('code', text, 0, language, [], false, '');
  }

  static hr(): AiMarkdownBlock {
    return AiMarkdownBlockFactory.create('hr', '', 0, '', [], false, '');
  }

  static list(text: string, ordered: boolean, marker: string): AiMarkdownBlock {
    return AiMarkdownBlockFactory.create('list', text, 0, '', [], ordered, marker);
  }

  static table(rows: string[][]): AiMarkdownBlock {
    return AiMarkdownBlockFactory.create('table', '', 0, '', rows, false, '');
  }

  private static create(
    type: AiMarkdownBlockType,
    text: string,
    level: number,
    language: string,
    rows: string[][],
    ordered: boolean,
    marker: string
  ): AiMarkdownBlock {
    const block: AiMarkdownBlock = {
      type: type,
      text: text,
      level: level,
      language: language,
      rows: rows,
      ordered: ordered,
      marker: marker
    };
    return block;
  }
}

class AiMarkdownInlineFactory {
  static text(text: string): AiMarkdownInline {
    return AiMarkdownInlineFactory.create('text', text, '');
  }

  static bold(text: string): AiMarkdownInline {
    return AiMarkdownInlineFactory.create('bold', text, '');
  }

  static italic(text: string): AiMarkdownInline {
    return AiMarkdownInlineFactory.create('italic', text, '');
  }

  static code(text: string): AiMarkdownInline {
    return AiMarkdownInlineFactory.create('code', text, '');
  }

  static link(text: string, href: string): AiMarkdownInline {
    return AiMarkdownInlineFactory.create('link', text, href);
  }

  private static create(type: AiMarkdownInlineType, text: string, href: string): AiMarkdownInline {
    const inline: AiMarkdownInline = {
      type: type,
      text: text,
      href: href
    };
    return inline;
  }
}

@Component
export struct AiMarkdownText {
  content: string = '';
  isUser: boolean = false;

  private textColor(): string {
    return this.isUser ? AppColors.SURFACE : AppColors.TEXT;
  }

  private secondaryColor(): string {
    return this.isUser ? '#D8E3FF' : AppColors.TEXT_SECONDARY;
  }

  private parseBlocks(text: string): AiMarkdownBlock[] {
    const lines = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n');
    const blocks: AiMarkdownBlock[] = [];
    let index = 0;
    let paragraph = '';
    while (index < lines.length) {
      const line = lines[index];
      const trimmed = line.trim();

      if (trimmed.startsWith('```')) {
        if (paragraph.length > 0) {
          blocks.push(AiMarkdownBlockFactory.paragraph(paragraph));
          paragraph = '';
        }
        const language = this.normalizeCodeLanguage(trimmed.substring(3).trim());
        index += 1;
        let codeText = '';
        while (index < lines.length && !lines[index].trim().startsWith('```')) {
          codeText += codeText.length === 0 ? lines[index] : `\n${lines[index]}`;
          index += 1;
        }
        blocks.push(AiMarkdownBlockFactory.code(codeText, language));
        if (index < lines.length) {
          index += 1;
        }
        continue;
      }

      if (trimmed.length === 0) {
        if (paragraph.length > 0) {
          blocks.push(AiMarkdownBlockFactory.paragraph(paragraph));
          paragraph = '';
        }
        index += 1;
        continue;
      }

      if (this.isHorizontalRule(trimmed)) {
        if (paragraph.length > 0) {
          blocks.push(AiMarkdownBlockFactory.paragraph(paragraph));
          paragraph = '';
        }
        blocks.push(AiMarkdownBlockFactory.hr());
        index += 1;
        continue;
      }

      if (trimmed.startsWith('#')) {
        if (paragraph.length > 0) {
          blocks.push(AiMarkdownBlockFactory.paragraph(paragraph));
          paragraph = '';
        }
        const level = this.headingLevel(trimmed);
        blocks.push(AiMarkdownBlockFactory.heading(trimmed.substring(level).trim(), level));
        index += 1;
        continue;
      }

      if (this.isTableStart(lines, index)) {
        if (paragraph.length > 0) {
          blocks.push(AiMarkdownBlockFactory.paragraph(paragraph));
          paragraph = '';
        }
        const rows: string[][] = [];
        rows.push(this.splitTableRow(lines[index]));
        index += 2;
        while (index < lines.length && lines[index].indexOf('|') >= 0 && lines[index].trim().length > 0) {
          rows.push(this.splitTableRow(lines[index]));
          index += 1;
        }
        blocks.push(AiMarkdownBlockFactory.table(rows));
        continue;
      }

      if (this.isListLine(trimmed)) {
        if (paragraph.length > 0) {
          blocks.push(AiMarkdownBlockFactory.paragraph(paragraph));
          paragraph = '';
        }
        const ordered = this.isOrderedList(trimmed);
        blocks.push(AiMarkdownBlockFactory.list(this.listText(trimmed), ordered, ordered ? this.listMarker(trimmed) : '•'));
        index += 1;
        continue;
      }

      paragraph += paragraph.length === 0 ? trimmed : `\n${trimmed}`;
      index += 1;
    }
    if (paragraph.length > 0) {
      blocks.push(AiMarkdownBlockFactory.paragraph(paragraph));
    }
    return blocks;
  }

  private parseInline(text: string): AiMarkdownInline[] {
    const result: AiMarkdownInline[] = [];
    let index = 0;
    let plain = '';
    while (index < text.length) {
      const char = text.charAt(index);
      if (char === '`') {
        const end = text.indexOf('`', index + 1);
        if (end > index) {
          this.flushPlain(result, plain);
          plain = '';
          result.push(AiMarkdownInlineFactory.code(text.substring(index + 1, end)));
          index = end + 1;
          continue;
        }
      }
      if (text.substring(index, index + 2) === '**') {
        const end = text.indexOf('**', index + 2);
        if (end > index) {
          this.flushPlain(result, plain);
          plain = '';
          result.push(AiMarkdownInlineFactory.bold(text.substring(index + 2, end)));
          index = end + 2;
          continue;
        }
      }
      if (char === '*') {
        const end = text.indexOf('*', index + 1);
        if (end > index) {
          this.flushPlain(result, plain);
          plain = '';
          result.push(AiMarkdownInlineFactory.italic(text.substring(index + 1, end)));
          index = end + 1;
          continue;
        }
      }
      if (char === '[') {
        const closeText = text.indexOf(']', index + 1);
        if (closeText > index && closeText + 1 < text.length && text.charAt(closeText + 1) === '(') {
          const closeHref = text.indexOf(')', closeText + 2);
          if (closeHref > closeText) {
            this.flushPlain(result, plain);
            plain = '';
            result.push(AiMarkdownInlineFactory.link(
              text.substring(index + 1, closeText),
              text.substring(closeText + 2, closeHref)
            ));
            index = closeHref + 1;
            continue;
          }
        }
      }
      plain += char;
      index += 1;
    }
    this.flushPlain(result, plain);
    return result;
  }

  private flushPlain(result: AiMarkdownInline[], text: string): void {
    if (text.length > 0) {
      result.push(AiMarkdownInlineFactory.text(text));
    }
  }

  private isHorizontalRule(line: string): boolean {
    return line === '---' || line === '***' || line === '___';
  }

  private headingLevel(line: string): number {
    let level = 0;
    while (level < line.length && level < 6 && line.charAt(level) === '#') {
      level += 1;
    }
    return level;
  }

  private isTableStart(lines: string[], index: number): boolean {
    if (index + 1 >= lines.length) {
      return false;
    }
    return lines[index].indexOf('|') >= 0 && this.isTableSeparator(lines[index + 1]);
  }

  private isTableSeparator(line: string): boolean {
    const trimmed = line.trim().replace(/\|/g, '').replace(/:/g, '').replace(/-/g, '').trim();
    return line.indexOf('|') >= 0 && trimmed.length === 0;
  }

  private splitTableRow(line: string): string[] {
    let text = line.trim();
    if (text.startsWith('|')) {
      text = text.substring(1);
    }
    if (text.endsWith('|')) {
      text = text.substring(0, text.length - 1);
    }
    return text.split('|').map((cell) => cell.trim());
  }

  private isListLine(line: string): boolean {
    return line.startsWith('- ') ||
      line.startsWith('* ') ||
      line.startsWith('+ ') ||
      this.isOrderedList(line);
  }

  private isOrderedList(line: string): boolean {
    const dot = line.indexOf('. ');
    if (dot <= 0 || dot > 3) {
      return false;
    }
    const marker = line.substring(0, dot);
    const value = Number(marker);
    return value === value;
  }

  private listText(line: string): string {
    if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('+ ')) {
      return line.substring(2);
    }
    const dot = line.indexOf('. ');
    return dot > 0 ? line.substring(dot + 2) : line;
  }

  private listMarker(line: string): string {
    const dot = line.indexOf('. ');
    return dot > 0 ? line.substring(0, dot + 1) : '•';
  }

  private normalizeCodeLanguage(value: string): string {
    if (value.length === 0) {
      return 'text';
    }
    const firstSpace = value.indexOf(' ');
    const language = firstSpace > 0 ? value.substring(0, firstSpace) : value;
    const normalized = language.toLowerCase();
    if (normalized === 'ts' || normalized === 'typescript') {
      return 'typescript';
    }
    if (normalized === 'js' || normalized === 'javascript') {
      return 'javascript';
    }
    if (normalized === 'sh' || normalized === 'bash' || normalized === 'shell') {
      return 'shell';
    }
    if (normalized === 'md' || normalized === 'markdown') {
      return 'markdown';
    }
    return normalized;
  }

  private createCodeToken(type: AiCodeTokenType, text: string): AiCodeToken {
    const token: AiCodeToken = {
      type: type,
      text: text
    };
    return token;
  }

  private isIdentifierChar(char: string): boolean {
    if (char.length === 0) {
      return false;
    }
    const code = char.charCodeAt(0);
    return (code >= 48 && code <= 57) ||
      (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      char === '_' ||
      char === '$';
  }

  private isOperatorChar(char: string): boolean {
    return '{}[]().,:;+-*/%=!<>|&?'.indexOf(char) >= 0;
  }

  private isCommentStart(line: string, index: number, language: string): boolean {
    if (line.substring(index, index + 2) === '//') {
      return true;
    }
    if (line.substring(index, index + 2) === '--') {
      return language === 'sql';
    }
    if (line.charAt(index) === '#') {
      return language === 'shell' || language === 'python' || language === 'yaml' || language === 'markdown';
    }
    return false;
  }

  private isCodeKeyword(token: string, language: string): boolean {
    const sharedKeywords: string[] = [
      'abstract', 'async', 'await', 'break', 'case', 'catch', 'class', 'const', 'continue', 'default',
      'do', 'else', 'enum', 'export', 'extends', 'false', 'finally', 'for', 'from', 'function',
      'if', 'implements', 'import', 'interface', 'let', 'new', 'null', 'private', 'protected',
      'public', 'return', 'static', 'super', 'switch', 'this', 'throw', 'true', 'try', 'type',
      'undefined', 'var', 'void', 'while'
    ];
    const javaKeywords: string[] = [
      'boolean', 'byte', 'char', 'double', 'final', 'float', 'int', 'long', 'package', 'short',
      'synchronized', 'throws'
    ];
    const shellKeywords: string[] = [
      'case', 'done', 'elif', 'else', 'esac', 'fi', 'for', 'function', 'if', 'in', 'then', 'while'
    ];
    const jsonKeywords: string[] = ['false', 'null', 'true'];
    if (language === 'java') {
      return sharedKeywords.includes(token) || javaKeywords.includes(token);
    }
    if (language === 'shell') {
      return shellKeywords.includes(token);
    }
    if (language === 'json') {
      return jsonKeywords.includes(token);
    }
    return sharedKeywords.includes(token);
  }

  private isNumericToken(token: string): boolean {
    if (token.length === 0) {
      return false;
    }
    const value = Number(token);
    return value === value;
  }

  private parseCodeTokens(text: string, language: string): AiCodeToken[] {
    const tokens: AiCodeToken[] = [];
    const lines = text.split('\n');
    for (let lineIndex = 0; lineIndex < lines.length; lineIndex += 1) {
      const line = lines[lineIndex];
      let index = 0;
      while (index < line.length) {
        const char = line.charAt(index);
        if (this.isCommentStart(line, index, language)) {
          tokens.push(this.createCodeToken('comment', line.substring(index)));
          index = line.length;
          continue;
        }
        if (char === '"' || char === '\'' || char === '`') {
          const quote = char;
          let end = index + 1;
          while (end < line.length) {
            if (line.charAt(end) === '\\') {
              end += 2;
              continue;
            }
            if (line.charAt(end) === quote) {
              end += 1;
              break;
            }
            end += 1;
          }
          tokens.push(this.createCodeToken('string', line.substring(index, end)));
          index = end;
          continue;
        }
        if (this.isOperatorChar(char)) {
          tokens.push(this.createCodeToken('operator', char));
          index += 1;
          continue;
        }
        if (this.isIdentifierChar(char)) {
          let end = index + 1;
          while (end < line.length && this.isIdentifierChar(line.charAt(end))) {
            end += 1;
          }
          const word = line.substring(index, end);
          if (this.isCodeKeyword(word, language)) {
            tokens.push(this.createCodeToken('keyword', word));
          } else if (this.isNumericToken(word)) {
            tokens.push(this.createCodeToken('number', word));
          } else {
            tokens.push(this.createCodeToken('plain', word));
          }
          index = end;
          continue;
        }
        tokens.push(this.createCodeToken('plain', char));
        index += 1;
      }
      if (lineIndex < lines.length - 1) {
        tokens.push(this.createCodeToken('plain', '\n'));
      }
    }
    return tokens;
  }

  private codeTokenColor(type: AiCodeTokenType): string {
    if (type === 'keyword') {
      return '#C678DD';
    }
    if (type === 'string') {
      return '#98C379';
    }
    if (type === 'number') {
      return '#D19A66';
    }
    if (type === 'comment') {
      return '#7F848E';
    }
    if (type === 'operator') {
      return '#56B6C2';
    }
    return this.isUser ? AppColors.SURFACE : '#E5E7EB';
  }

  private copyCode(text: string): void {
    clipboardService.copyText(text).then(() => {
      this.getUIContext().getPromptAction().showToast({
        message: '已复制代码',
        duration: 1600
      });
    }).catch((error: Error) => {
      console.error(`[CourseDrop] copy code failed: ${error.message}`);
    });
  }

  private headingSize(level: number): number {
    if (level <= 1) {
      return 22;
    }
    if (level === 2) {
      return 19;
    }
    if (level === 3) {
      return 17;
    }
    return 15;
  }

  @Builder
  InlineText(text: string, fontSize: number = 15, bold: boolean = false) {
    Text() {
      ForEach(this.parseInline(text), (part: AiMarkdownInline) => {
        if (part.type === 'bold') {
          Span(part.text)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textColor())
        } else if (part.type === 'italic') {
          Span(part.text)
            .fontStyle(FontStyle.Italic)
            .fontColor(this.textColor())
        } else if (part.type === 'code') {
          Span(part.text)
            .fontFamily('monospace')
            .fontColor(this.isUser ? '#FFFFFF' : AppColors.PRIMARY_SELECTED)
        } else if (part.type === 'link') {
          Span(part.text)
            .fontColor(this.isUser ? '#D8E3FF' : AppColors.PRIMARY)
            .decoration({ type: TextDecorationType.Underline })
        } else {
          Span(part.text)
            .fontColor(this.textColor())
        }
      }, (part: AiMarkdownInline, index: number) => `${index}-${part.type}-${part.text}`)
    }
    .fontSize(fontSize)
    .fontWeight(bold ? FontWeight.Bold : FontWeight.Regular)
    .lineHeight(fontSize + 8)
    .width('100%')
  }

  @Builder
  CodeText(text: string, language: string) {
    Text() {
      ForEach(this.parseCodeTokens(text, language), (token: AiCodeToken) => {
        Span(token.text)
          .fontColor(this.codeTokenColor(token.type))
      }, (token: AiCodeToken, index: number) => `${index}-${token.type}-${token.text}`)
    }
    .width('100%')
    .fontSize(13)
    .fontFamily('monospace')
    .lineHeight(19)
  }

  @Builder
  CodeBlock(text: string, language: string) {
    Column() {
      Row() {
        Text(language.length > 0 ? language : 'text')
          .fontSize(12)
          .fontColor('#AAB2C0')
          .fontWeight(FontWeight.Medium)

        Blank()
          .layoutWeight(1)

        Stack() {
          Image($r('app.media.cd_icon_copy'))
            .width(17)
            .height(17)
            .fillColor('#AAB2C0')
        }
        .width(32)
        .height(28)
        .borderRadius(14)
        .onClick(() => {
          this.copyCode(text);
        })
      }
      .width('100%')
      .height(36)
      .padding({ left: AppSpacing.MD, right: AppSpacing.SM })
      .backgroundColor('#242B38')

      Column() {
        this.CodeText(text, language)
      }
      .width('100%')
        .padding(AppSpacing.MD)
        .backgroundColor('#111827')
    }
    .width('100%')
    .borderRadius(AppRadius.MD)
  }

  @Builder
  TableBlock(rows: string[][]) {
    Column() {
      ForEach(rows, (row: string[], rowIndex: number) => {
        Row() {
          ForEach(row, (cell: string, cellIndex: number) => {
            Column() {
              this.InlineText(cell, 12, rowIndex === 0)
            }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .padding(8)
              .border({ width: 0.5, color: this.isUser ? '#55FFFFFF' : AppColors.BORDER })
          }, (cell: string, cellIndex: number) => `${rowIndex}-${cellIndex}-${cell}`)
        }
        .width('100%')
      }, (row: string[], rowIndex: number) => `${rowIndex}-${row.length}`)
    }
    .width('100%')
    .borderRadius(AppRadius.SM)
  }

  build() {
    Column({ space: AppSpacing.SM }) {
      ForEach(this.parseBlocks(this.content), (block: AiMarkdownBlock, index: number) => {
        if (block.type === 'heading') {
          this.InlineText(block.text, this.headingSize(block.level), true)
        } else if (block.type === 'code') {
          this.CodeBlock(block.text, block.language)
        } else if (block.type === 'hr') {
          Divider()
            .color(this.isUser ? '#55FFFFFF' : AppColors.BORDER)
            .strokeWidth(1)
        } else if (block.type === 'list') {
          Row({ space: AppSpacing.SM }) {
            Text(block.marker)
              .fontSize(15)
              .fontColor(this.secondaryColor())
            this.InlineText(block.text)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        } else if (block.type === 'table') {
          this.TableBlock(block.rows)
        } else {
          this.InlineText(block.text)
        }
      }, (block: AiMarkdownBlock, index: number) => `${index}-${block.type}-${block.text.length}-${block.rows.length}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
