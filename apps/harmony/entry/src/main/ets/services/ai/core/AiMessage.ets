export type AiMessageRole = 'system' | 'user' | 'assistant' | 'tool';

export type AiContentPartType = 'text' | 'file_context' | 'analysis_context';

export interface AiFileContext {
  id: string;
  displayName: string;
  mimeType: string;
  sizeBytes: number;
  localUri?: string;
  extractedText?: string;
  summary?: string;
}

export interface AiContentPart {
  type: AiContentPartType;
  text?: string;
  file?: AiFileContext;
}

export interface AiToolCallFunction {
  name: string;
  arguments: string;
}

export interface AiToolCall {
  id: string;
  type: 'function';
  function: AiToolCallFunction;
}

export interface AiMessageMetadata {
  source?: string;
  model?: string;
  finishReason?: string;
  createdAt?: number;
}

export interface AiMessage {
  id: string;
  role: AiMessageRole;
  content: string;
  parts?: AiContentPart[];
  name?: string;
  toolCallId?: string;
  toolCalls?: AiToolCall[];
  metadata?: AiMessageMetadata;
}

export class AiMessageFactory {
  static system(content: string): AiMessage {
    return AiMessageFactory.text('system', content);
  }

  static user(content: string, parts?: AiContentPart[]): AiMessage {
    return AiMessageFactory.text('user', content, parts);
  }

  static assistant(content: string, toolCalls?: AiToolCall[]): AiMessage {
    const message = AiMessageFactory.text('assistant', content);
    if (toolCalls !== undefined && toolCalls.length > 0) {
      message.toolCalls = toolCalls;
    }
    return message;
  }

  static tool(name: string, content: string, toolCallId?: string): AiMessage {
    const message = AiMessageFactory.text('tool', content);
    message.name = name;
    message.toolCallId = toolCallId;
    return message;
  }

  static text(role: AiMessageRole, content: string, parts?: AiContentPart[]): AiMessage {
    const message: AiMessage = {
      id: AiMessageFactory.createId(role),
      role: role,
      content: content,
      metadata: {
        createdAt: Date.now()
      }
    };
    if (parts !== undefined && parts.length > 0) {
      message.parts = parts;
    }
    return message;
  }

  static fileContext(file: AiFileContext): AiContentPart {
    return {
      type: 'file_context',
      file: file
    };
  }

  static analysisContext(text: string): AiContentPart {
    return {
      type: 'analysis_context',
      text: text
    };
  }

  private static createId(role: AiMessageRole): string {
    return `${role}-${Date.now()}-${Math.floor(Math.random() * 1000000)}`;
  }
}

export class AiMessageFormatter {
  static toPlainText(message: AiMessage): string {
    if (message.parts === undefined || message.parts.length === 0) {
      return message.content;
    }

    let text = message.content;
    for (const part of message.parts) {
      if (part.type === 'text' && part.text !== undefined) {
        text += `\n${part.text}`;
      }
      if (part.type === 'analysis_context' && part.text !== undefined) {
        text += `\n\n[分析上下文]\n${part.text}`;
      }
      if (part.type === 'file_context' && part.file !== undefined) {
        text += AiMessageFormatter.formatFileContext(part.file);
      }
    }
    return text;
  }

  private static formatFileContext(file: AiFileContext): string {
    let text = `\n\n[文件上下文]\n文件名: ${file.displayName}\nMIME: ${file.mimeType}\n大小: ${file.sizeBytes}`;
    if (file.summary !== undefined && file.summary.length > 0) {
      text += `\n摘要: ${file.summary}`;
    }
    if (file.extractedText !== undefined && file.extractedText.length > 0) {
      text += `\n内容:\n${file.extractedText}`;
    }
    text += '\n[文件上下文结束]';
    return text;
  }
}
