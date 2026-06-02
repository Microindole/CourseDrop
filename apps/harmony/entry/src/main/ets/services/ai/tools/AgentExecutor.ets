import { AiMessageFactory, BaseLlm } from '../core';
import type { AiMessage, LlmChatOptions } from '../core';
import { Tool } from './Tool';
import type { ToolRunContext } from './Tool';
import { ToolRegistry } from './ToolRegistry';

export interface AgentExecutionOptions extends LlmChatOptions {
  maxIterations?: number;
  context?: ToolRunContext;
}

export class AgentExecutor {
  private llm: BaseLlm;
  private registry: ToolRegistry;

  constructor(llm: BaseLlm, tools: Tool[]) {
    this.llm = llm;
    this.registry = new ToolRegistry(tools);
  }

  async execute(messages: AiMessage[], options?: AgentExecutionOptions): Promise<AiMessage> {
    const sessionMessages: AiMessage[] = [...messages];
    const maxIterations = options !== undefined && options.maxIterations !== undefined ? options.maxIterations : 5;
    const model = options !== undefined ? options.model : undefined;
    const temperature = options !== undefined ? options.temperature : undefined;
    const maxTokens = options !== undefined ? options.maxTokens : undefined;
    const context = options !== undefined ? options.context : undefined;
    const tools = this.registry.list();
    const toolDefinitions = tools.map((tool) => tool.toLlmDefinition());

    for (let step = 0; step < maxIterations; step += 1) {
      const response = await this.llm.chat(sessionMessages, {
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
        tools: toolDefinitions
      });
      sessionMessages.push(response);

      if (response.toolCalls === undefined || response.toolCalls.length === 0) {
        return response;
      }

      for (const toolCall of response.toolCalls) {
        const tool = this.registry.get(toolCall.function.name);
        let result = '';
        if (tool === undefined) {
          result = `Error: Tool ${toolCall.function.name} not found.`;
        } else {
          result = await tool.run(toolCall.function.arguments, context);
        }
        sessionMessages.push(AiMessageFactory.tool(toolCall.function.name, result, toolCall.id));
      }
    }

    throw new Error('Agent execution exceeded maximum iterations.');
  }
}
