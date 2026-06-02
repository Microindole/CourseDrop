import type { AiToolDefinition, AiToolDefinitionFunction } from '../core';

export interface ToolParameterSchema {
  type: string;
  description?: string;
}

export interface ToolParametersProperties {
  limit?: ToolParameterSchema;
}

export interface ToolParametersSchema {
  type: string;
  properties: ToolParametersProperties;
}

export interface ToolRunContext {
  conversationId?: string;
}

export abstract class Tool {
  abstract name: string;
  abstract description: string;
  abstract parametersSchema: ToolParametersSchema;

  abstract run(argsString: string, context?: ToolRunContext): Promise<string>;

  toLlmDefinition(): AiToolDefinition {
    const definitionFunction: AiToolDefinitionFunction = {
      name: this.name,
      description: this.description,
      parameters: this.parametersSchema
    };
    const definition: AiToolDefinition = {
      type: 'function',
      function: definitionFunction
    };
    return definition;
  }
}
