import type { AiToolDefinition } from '../core';

export interface ToolRunContext {
  conversationId?: string;
}

export abstract class Tool {
  abstract name: string;
  abstract description: string;
  abstract parametersSchema: object;

  abstract run(argsString: string, context?: ToolRunContext): Promise<string>;

  toLlmDefinition(): AiToolDefinition {
    return {
      type: 'function',
      function: {
        name: this.name,
        description: this.description,
        parameters: this.parametersSchema
      }
    };
  }
}
