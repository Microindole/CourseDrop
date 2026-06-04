import http from '@ohos.net.http';
import { AppConfig } from '../common/AppConfig';

export class JsonRequestHeader {
  'Content-Type': string = 'application/json';
}

export class ApiClient {
  private baseUrl: string = AppConfig.DEFAULT_SERVER_URL;
  private requestTimeoutMs: number = 5000;

  setBaseUrl(baseUrl: string): void {
    this.baseUrl = baseUrl.replace(/\/$/, '');
  }

  getBaseUrl(): string {
    return this.baseUrl;
  }

  hasBaseUrl(): boolean {
    return this.baseUrl.length > 0;
  }

  async get(path: string, headers?: Object): Promise<string> {
    return this.request(path, http.RequestMethod.GET, '', headers);
  }

  async getWithTimeout(path: string, timeoutMs: number): Promise<string> {
    const previousTimeoutMs = this.requestTimeoutMs;
    this.requestTimeoutMs = timeoutMs;
    try {
      return await this.request(path, http.RequestMethod.GET, '', undefined);
    } finally {
      this.requestTimeoutMs = previousTimeoutMs;
    }
  }

  async postJson(path: string, body: string, headers?: Object): Promise<string> {
    let requestHeaders: Object = new JsonRequestHeader();
    if (headers !== undefined) {
      requestHeaders = headers;
    }
    return this.request(path, http.RequestMethod.POST, body, requestHeaders);
  }

  async putJson(path: string, body: string, headers?: Object): Promise<string> {
    let requestHeaders: Object = new JsonRequestHeader();
    if (headers !== undefined) {
      requestHeaders = headers;
    }
    return this.request(path, http.RequestMethod.PUT, body, requestHeaders);
  }

  async delete(path: string, headers?: Object): Promise<string> {
    return this.request(path, http.RequestMethod.DELETE, '', headers);
  }

  private async request(path: string, method: http.RequestMethod, body: string, headers?: Object): Promise<string> {
    if (!this.hasBaseUrl()) {
      throw new Error('未配置中转源');
    }
    const request = http.createHttp();
    const url = `${this.baseUrl}${path.startsWith('/') ? path : `/${path}`}`;
    console.info(`[CourseDrop] HTTP ${method} ${url}`);
    try {
      const response = await this.withTimeout(request.request(url, {
        method: method,
        header: headers,
        extraData: body,
        connectTimeout: this.requestTimeoutMs,
        readTimeout: this.requestTimeoutMs
      }), this.requestTimeoutMs, url);
      console.info(`[CourseDrop] HTTP ${response.responseCode} ${url}`);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`HTTP ${response.responseCode}: ${String(response.result)}`);
      }
      return String(response.result);
    } finally {
      request.destroy();
    }
  }

  private withTimeout(
    requestTask: Promise<http.HttpResponse>,
    timeoutMs: number,
    url: string
  ): Promise<http.HttpResponse> {
    return new Promise<http.HttpResponse>((resolve, reject) => {
      let completed = false;
      setTimeout(() => {
        if (completed) {
          return;
        }
        completed = true;
        console.error(`[CourseDrop] HTTP timeout ${url}`);
        reject(new Error(`请求超时 ${timeoutMs}ms`));
      }, timeoutMs);

      requestTask
        .then((response: http.HttpResponse) => {
          if (completed) {
            return;
          }
          completed = true;
          resolve(response);
        })
        .catch((error: Error) => {
          if (completed) {
            return;
          }
          completed = true;
          console.error(`[CourseDrop] HTTP failed ${url}: ${String(error)}`);
          reject(error);
        });
    });
  }
}

export const apiClient = new ApiClient();
