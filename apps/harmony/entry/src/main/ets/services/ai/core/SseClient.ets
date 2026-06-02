import http from '@ohos.net.http';

export interface SseRequest {
  url: string;
  method?: http.RequestMethod;
  headers?: Object;
  body?: string | ArrayBuffer;
  connectTimeoutMs?: number;
  readTimeoutMs?: number;
}

export interface SseEvent {
  id?: string;
  event?: string;
  data: string;
  retry?: number;
}

export interface SseCallbacks {
  onResponseCode?: (responseCode: number) => void;
  onEvent: (event: SseEvent) => void;
  onComplete: () => void;
  onError: (error: Error) => void;
}

export interface SseConnection {
  close: () => void;
}

export class SseParser {
  private buffer: string = '';

  push(chunk: string): SseEvent[] {
    this.buffer += chunk;
    const events: SseEvent[] = [];
    let boundary = this.findBoundary(this.buffer);
    while (boundary >= 0) {
      const frame = this.buffer.substring(0, boundary);
      this.buffer = this.buffer.substring(this.nextFrameStart(this.buffer, boundary));
      const event = this.parseFrame(frame);
      if (event !== undefined) {
        events.push(event);
      }
      boundary = this.findBoundary(this.buffer);
    }
    return events;
  }

  finish(): SseEvent[] {
    if (this.buffer.trim().length === 0) {
      this.buffer = '';
      return [];
    }
    const event = this.parseFrame(this.buffer);
    this.buffer = '';
    return event !== undefined ? [event] : [];
  }

  private parseFrame(frame: string): SseEvent | undefined {
    const lines = frame.replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n');
    let id: string | undefined = undefined;
    let eventName: string | undefined = undefined;
    let retry: number | undefined = undefined;
    const dataLines: string[] = [];

    for (const line of lines) {
      if (line.length === 0 || line.startsWith(':')) {
        continue;
      }
      const separatorIndex = line.indexOf(':');
      const field = separatorIndex >= 0 ? line.substring(0, separatorIndex) : line;
      let value = separatorIndex >= 0 ? line.substring(separatorIndex + 1) : '';
      if (value.startsWith(' ')) {
        value = value.substring(1);
      }

      if (field === 'id') {
        id = value;
      } else if (field === 'event') {
        eventName = value;
      } else if (field === 'retry') {
        retry = Number(value);
      } else if (field === 'data') {
        dataLines.push(value);
      }
    }

    if (dataLines.length === 0 && eventName === undefined && id === undefined) {
      return undefined;
    }

    const event: SseEvent = {
      data: dataLines.join('\n')
    };
    if (id !== undefined) {
      event.id = id;
    }
    if (eventName !== undefined) {
      event.event = eventName;
    }
    if (retry !== undefined && retry === retry) {
      event.retry = retry;
    }
    return event;
  }

  private findBoundary(text: string): number {
    const lf = text.indexOf('\n\n');
    const crlf = text.indexOf('\r\n\r\n');
    if (lf < 0) {
      return crlf;
    }
    if (crlf < 0) {
      return lf;
    }
    return Math.min(lf, crlf);
  }

  private nextFrameStart(text: string, boundary: number): number {
    if (text.substring(boundary, boundary + 4) === '\r\n\r\n') {
      return boundary + 4;
    }
    return boundary + 2;
  }
}

export class SseClient {
  stream(request: SseRequest, callbacks: SseCallbacks): SseConnection {
    const httpRequest = http.createHttp();
    const parser = new SseParser();
    const decoder = new StreamingUtf8Decoder();
    let completed = false;
    let streamEnded = false;
    let responseCode: number | undefined = undefined;

    httpRequest.on('headersReceive', (header: Object) => {
      console.info(`[CourseDrop] SSE headers ${JSON.stringify(header)}`);
    });

    httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      if (completed) {
        return;
      }
      try {
        const chunk = decoder.push(data);
        const events = parser.push(chunk);
        for (const event of events) {
          callbacks.onEvent(event);
        }
      } catch (error) {
        completed = this.fail(completed, httpRequest, callbacks, error);
      }
    });

    httpRequest.on('dataEnd', () => {
      if (completed) {
        return;
      }
      try {
        const chunk = decoder.finish();
        const events = parser.push(chunk).concat(parser.finish());
        for (const event of events) {
          callbacks.onEvent(event);
        }
        streamEnded = true;
        completed = this.completeIfReady(completed, streamEnded, responseCode, httpRequest, callbacks);
      } catch (error) {
        completed = this.fail(completed, httpRequest, callbacks, error);
      }
    });

    httpRequest.requestInStream(request.url, {
      method: request.method !== undefined ? request.method : http.RequestMethod.POST,
      header: request.headers,
      extraData: request.body,
      connectTimeout: request.connectTimeoutMs !== undefined ? request.connectTimeoutMs : 15000,
      readTimeout: request.readTimeoutMs !== undefined ? request.readTimeoutMs : 60000
    }).then((code: number) => {
      responseCode = code;
      if (callbacks.onResponseCode !== undefined) {
        callbacks.onResponseCode(code);
      }
      completed = this.completeIfReady(completed, streamEnded, responseCode, httpRequest, callbacks);
    }).catch((error: Error) => {
      completed = this.fail(completed, httpRequest, callbacks, error);
    });

    return {
      close: () => {
        if (completed) {
          return;
        }
        completed = true;
        this.cleanup(httpRequest);
      }
    };
  }

  private completeIfReady(
    completed: boolean,
    streamEnded: boolean,
    responseCode: number | undefined,
    httpRequest: http.HttpRequest,
    callbacks: SseCallbacks
  ): boolean {
    if (completed || !streamEnded || responseCode === undefined) {
      return completed;
    }
    try {
      if (responseCode < 200 || responseCode >= 300) {
        callbacks.onError(new Error(`SSE HTTP ${responseCode}`));
      } else {
        callbacks.onComplete();
      }
    } finally {
      this.cleanup(httpRequest);
    }
    return true;
  }

  private fail(
    completed: boolean,
    httpRequest: http.HttpRequest,
    callbacks: SseCallbacks,
    error: Error | Object
  ): boolean {
    if (completed) {
      return true;
    }
    try {
      callbacks.onError(this.toError(error));
    } finally {
      this.cleanup(httpRequest);
    }
    return true;
  }

  private cleanup(httpRequest: http.HttpRequest): void {
    httpRequest.off('headersReceive');
    httpRequest.off('dataReceive');
    httpRequest.off('dataEnd');
    httpRequest.destroy();
  }

  private toError(error: Error | Object): Error {
    if (typeof error === 'object' && error !== null) {
      const possibleError = error as Error;
      if (possibleError.message !== undefined) {
        return new Error(String(possibleError.message));
      }
    }
    return new Error(String(error));
  }
}

class StreamingUtf8Decoder {
  private pending: number[] = [];

  push(buffer: ArrayBuffer): string {
    const incoming = new Uint8Array(buffer);
    const bytes = this.mergePending(incoming);
    this.pending = [];
    return this.decode(bytes, false);
  }

  finish(): string {
    if (this.pending.length === 0) {
      return '';
    }
    const bytes = new Uint8Array(this.pending);
    this.pending = [];
    return this.decode(bytes, true);
  }

  private mergePending(incoming: Uint8Array): Uint8Array {
    if (this.pending.length === 0) {
      return incoming;
    }
    const merged = new Uint8Array(this.pending.length + incoming.length);
    for (let index = 0; index < this.pending.length; index += 1) {
      merged[index] = this.pending[index];
    }
    merged.set(incoming, this.pending.length);
    return merged;
  }

  private decode(bytes: Uint8Array, flush: boolean): string {
    let text = '';
    let index = 0;
    while (index < bytes.length) {
      const first = bytes[index];
      if (first < 0x80) {
        text += String.fromCharCode(first);
        index += 1;
      } else if ((first & 0xe0) === 0xc0) {
        if (index + 1 >= bytes.length) {
          return this.holdOrReplace(bytes, index, text, flush);
        }
        const second = bytes[index + 1];
        text += String.fromCharCode(((first & 0x1f) << 6) | (second & 0x3f));
        index += 2;
      } else if ((first & 0xf0) === 0xe0) {
        if (index + 2 >= bytes.length) {
          return this.holdOrReplace(bytes, index, text, flush);
        }
        const second = bytes[index + 1];
        const third = bytes[index + 2];
        text += String.fromCharCode(((first & 0x0f) << 12) | ((second & 0x3f) << 6) | (third & 0x3f));
        index += 3;
      } else if ((first & 0xf8) === 0xf0) {
        if (index + 3 >= bytes.length) {
          return this.holdOrReplace(bytes, index, text, flush);
        }
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

  private holdOrReplace(bytes: Uint8Array, index: number, text: string, flush: boolean): string {
    if (flush) {
      return `${text}\uFFFD`;
    }
    this.pending = [];
    for (let pendingIndex = index; pendingIndex < bytes.length; pendingIndex += 1) {
      this.pending.push(bytes[pendingIndex]);
    }
    return text;
  }
}
