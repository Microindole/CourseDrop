import http from '@ohos.net.http';
import {
  AiMessageFactory,
  AiMessageFormatter,
  BaseLlm,
  SseClient,
} from '../core';
import type {
  AiMessage,
  AiToolCall,
  LlmChatOptions,
  LlmProviderConfig,
  LlmStreamCallbacks,
  SseConnection
} from '../core';

interface OpenAIMessage {
  role: string;
  content?: string;
  name?: string;
  tool_call_id?: string;
  tool_calls?: AiToolCall[];
}

export interface OpenAIThinkingOptions {
  type: string;
}

export interface OpenAIChatRequest {
  model: string;
  messages: OpenAIMessage[];
  temperature?: number;
  max_tokens?: number;
  stream?: boolean;
  tools?: object[];
  reasoning_effort?: string;
  thinking?: OpenAIThinkingOptions;
}

interface OpenAIChoice {
  message?: OpenAIMessage;
  delta?: OpenAIMessage;
  finish_reason?: string;
}

interface OpenAIChatResponse {
  model?: string;
  choices?: OpenAIChoice[];
}

interface OpenAIHeaders {
  'Content-Type': string;
  'Accept': string;
  'Authorization': string;
}

export class OpenAIProvider extends BaseLlm {
  protected sseClient: SseClient = new SseClient();

  constructor(config: LlmProviderConfig) {
    super(config);
  }

  async chat(messages: AiMessage[], options?: LlmChatOptions): Promise<AiMessage> {
    const request = http.createHttp();
    const url = `${this.baseUrl}/chat/completions`;
    const body = JSON.stringify(this.buildRequest(messages, false, options));
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.POST,
        header: this.buildHeaders('application/json'),
        extraData: body,
        connectTimeout: 15000,
        readTimeout: 60000
      });
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`AI HTTP ${response.responseCode}: ${String(response.result)}`);
      }
      const parsed = JSON.parse(String(response.result)) as OpenAIChatResponse;
      const choices = parsed.choices !== undefined ? parsed.choices : [];
      const choice = choices.length > 0 ? choices[0] : undefined;
      const fallbackMessage: OpenAIMessage = { role: 'assistant', content: '' };
      const message = choice !== undefined && choice.message !== undefined ?
        choice.message :
        fallbackMessage;
      const messageContent = typeof message.content === 'string' ? message.content : '';
      const result = AiMessageFactory.assistant(messageContent, message.tool_calls);
      result.metadata = {
        model: parsed.model,
        finishReason: choice !== undefined ? choice.finish_reason : undefined,
        createdAt: Date.now()
      };
      return result;
    } finally {
      request.destroy();
    }
  }

  chatStream(messages: AiMessage[], callbacks: LlmStreamCallbacks, options?: LlmChatOptions): SseConnection {
    const url = `${this.baseUrl}/chat/completions`;
    const body = JSON.stringify(this.buildRequest(messages, true, options));
    let fullText = '';
    return this.sseClient.stream({
      url: url,
      method: http.RequestMethod.POST,
      headers: this.buildHeaders('text/event-stream'),
      body: body,
      connectTimeoutMs: 15000,
      readTimeoutMs: 120000
    }, {
      onEvent: (event) => {
        if (event.data === '[DONE]') {
          return;
        }
        if (event.data.trim().length === 0) {
          return;
        }
        try {
          const parsed = JSON.parse(event.data) as OpenAIChatResponse;
          const choices = parsed.choices !== undefined ? parsed.choices : [];
          if (choices.length === 0) {
            return;
          }
          const delta = choices[0].delta;
          if (delta === undefined) {
            return;
          }
          const content = delta.content;
          if (typeof content === 'string' && content.length > 0) {
            fullText += content;
            callbacks.onChunk(content);
          }
          const onToolCall = callbacks.onToolCall;
          if (delta.tool_calls !== undefined && onToolCall !== undefined) {
            delta.tool_calls.forEach((toolCall) => onToolCall(toolCall));
          }
        } catch (error) {
          callbacks.onError(new Error(`AI stream parse failed: ${String(error)}`));
        }
      },
      onComplete: () => callbacks.onComplete(fullText),
      onError: (error) => callbacks.onError(error)
    });
  }

  protected buildRequest(messages: AiMessage[], stream: boolean, options?: LlmChatOptions): OpenAIChatRequest {
    const request: OpenAIChatRequest = {
      model: options !== undefined && options.model !== undefined ? options.model : this.model,
      messages: messages.map((message) => this.toOpenAIMessage(message)),
      stream: stream
    };
    if (options !== undefined && options.temperature !== undefined) {
      request.temperature = options.temperature;
    }
    if (options !== undefined && options.maxTokens !== undefined) {
      request.max_tokens = options.maxTokens;
    }
    if (options !== undefined && options.tools !== undefined && options.tools.length > 0) {
      request.tools = options.tools;
    }
    this.applyProviderOptions(request, options);
    return request;
  }

  protected applyProviderOptions(_request: OpenAIChatRequest, _options?: LlmChatOptions): void {
  }

  protected toOpenAIMessage(message: AiMessage): OpenAIMessage {
    const next: OpenAIMessage = {
      role: message.role,
      content: AiMessageFormatter.toPlainText(message)
    };
    if (message.name !== undefined) {
      next.name = message.name;
    }
    if (message.toolCallId !== undefined) {
      next.tool_call_id = message.toolCallId;
    }
    if (message.toolCalls !== undefined) {
      next.tool_calls = message.toolCalls;
    }
    return next;
  }

  protected buildHeaders(accept: string): OpenAIHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': accept,
      'Authorization': `Bearer ${this.apiKey}`
    };
  }
}
