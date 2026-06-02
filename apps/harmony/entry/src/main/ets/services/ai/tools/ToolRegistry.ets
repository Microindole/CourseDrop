import { Tool } from './Tool';

export class ToolRegistry {
  private tools: Map<string, Tool> = new Map();

  constructor(tools?: Tool[]) {
    if (tools !== undefined) {
      tools.forEach((tool) => this.register(tool));
    }
  }

  register(tool: Tool): void {
    this.tools.set(tool.name, tool);
  }

  get(name: string): Tool | undefined {
    return this.tools.get(name);
  }

  list(): Tool[] {
    const values: Tool[] = [];
    this.tools.forEach((tool) => {
      values.push(tool);
    });
    return values;
  }
}
