# AI 助手与智能代理（Agent）架构设计方案

本文档描述了 CourseDrop（课递）鸿蒙客户端 AI 助手模块的架构设计。该架构不仅支持接入 DeepSeek，还具备跨模型兼容性（如 OpenAI, Ollama 等），并支持对话记忆与轻量级 Agent（工具调用与代理执行）的扩展能力。

---

## 一、 模块设计原则

为了确保模块的未来扩展性，AI 模块的设计遵循了以下核心原则：

1. **跨模型提供商兼容（Provider-Agnostic）**：通过定义底层的通用大语言模型接口，应用不绑定于特定的大模型厂商。可根据用户填写的 Endpoint 和 API 密钥类型，动态切换驱动。
2. **状态与历史记忆解耦（Memory Management）**：大模型本身是无状态的。我们建立专门的历史记忆管理层，负责对对话的上下文（Context Window）进行自动截断、管理以及角色拼接（System/User/Assistant）。
3. **轻量级智能体架构（Lightweight Agent & Tools）**：在鸿蒙 ArkTS 端不直接引入庞大且对 Node.js 原生 API 有严重依赖的 LangChain。我们独立实现一套精简的 Tool 契约与循环思考执行器（Agent Executor），通过 API 的 Function Calling 或是 ReAct 格式指令实现调用系统 API、读取本地库或进行局域网状态查询。

---

## 二、 目录结构规划

为了实现业务高内聚和低耦合，所有的 AI、模型驱动和 Agent 逻辑都放在独立的 `services/ai/` 目录下：

```text
apps/harmony/entry/src/main/ets/
└── services/
    └── ai/
        ├── IDocumentParser.ets          <-- 文档解析契约接口
        ├── DocumentParserFactory.ets    <-- 解析器工厂
        │
        ├── core/                        <-- 核心通用 AI 与 Agent 抽象层
        │   ├── BaseLlm.ets              <-- 通用 LLM 抽象基类
        │   ├── ChatMemory.ets           <-- 记忆管理器（上下文与历史消息）
        │   ├── Tool.ets                 <-- 智能体工具契约类
        │   └── AgentExecutor.ets        <-- Agent 决策与工具循环执行器
        │
        ├── providers/                   <-- 具体大模型厂商驱动实现
        │   ├── OpenAIProvider.ets       <-- 兼容 OpenAI 格式驱动（含 DeepSeek）
        │   └── OllamaProvider.ets       <-- 兼容 Ollama 本地/局域网私有化模型
        │
        └── parsers/                     <-- 文档格式解析器具体实现
            ├── TextParser.ets
            ├── PdfParser.ets
            └── DocxParser.ets
```

---

## 三、 核心架构设计与契约代码

### 1. 通用 LLM 接口与消息模型 (`core/BaseLlm.ets`)

我们定义统一的 `LlmMessage` 与 `BaseLlm` 抽象，规范大模型的输入与流式输出行为：

```typescript
export interface LlmMessage {
  role: 'system' | 'user' | 'assistant' | 'tool';
  content: string;
  name?: string; // 用于 Tool 调用时的名称标识
  tool_calls?: LlmToolCall[]; // 模型输出的工具调用指令
}

export interface LlmToolCall {
  id: string;
  type: 'function';
  function: {
    name: string;
    arguments: string; // JSON 格式参数
  };
}

export interface LlmChatOptions {
  temperature?: number;
  maxTokens?: number;
  stream?: boolean;
  tools?: LlmToolDefinition[]; // 传递给大模型的工具声明列表
}

export interface LlmToolDefinition {
  type: 'function';
  function: {
    name: string;
    description: string;
    parameters: object; // JSON Schema 参数规范
  };
}

export interface StreamCallbacks {
  onChunk: (text: string) => void;
  onToolCall?: (toolCall: LlmToolCall) => void;
  onComplete: (fullText: string) => void;
  onError: (err: Error) => void;
}

export abstract class BaseLlm {
  protected apiKey: string;
  protected baseUrl: string;

  constructor(apiKey: string, baseUrl: string) {
    this.apiKey = apiKey;
    this.baseUrl = baseUrl;
  }

  /**
   * 一次性聊天完成接口
   */
  abstract chat(messages: LlmMessage[], options?: LlmChatOptions): Promise<LlmMessage>;

  /**
   * 流式聊天完成接口
   */
  abstract chatStream(messages: LlmMessage[], callbacks: StreamCallbacks, options?: LlmChatOptions): void;
}
```

### 2. 记忆管理器 (`core/ChatMemory.ets`)

用于记录对话上下文、限制 Token 长度并拼接系统 System Prompt 的组件：

```typescript
import { LlmMessage } from './BaseLlm';

export class ChatMemory {
  private history: LlmMessage[] = [];
  private maxHistoryLength: number = 20; // 默认最大对话轮数
  private systemPrompt: string = '你是一个好用的文档助手。';

  constructor(systemPrompt?: string, maxHistoryLength?: number) {
    if (systemPrompt) this.systemPrompt = systemPrompt;
    if (maxHistoryLength) this.maxHistoryLength = maxHistoryLength;
  }

  public setSystemPrompt(prompt: string) {
    this.systemPrompt = prompt;
  }

  public addMessage(message: LlmMessage) {
    this.history.push(message);
    // 超出限制时进行滑动窗口裁剪（保留最新的对话，注意不裁剪首条 System Prompt）
    if (this.history.length > this.maxHistoryLength) {
      this.history.shift();
    }
  }

  public getMessagesForModel(documentContext?: string): LlmMessage[] {
    const formatted: LlmMessage[] = [];
    
    // 注入 System Prompt
    let finalSystemContent = this.systemPrompt;
    if (documentContext && documentContext.length > 0) {
      finalSystemContent += `\n\n[当前关联文档内容上下文]：\n${documentContext}\n[上下文结束]`;
    }
    
    formatted.push({
      role: 'system',
      content: finalSystemContent
    });

    // 拼入历史对话消息
    formatted.push(...this.history);
    return formatted;
  }

  public clear() {
    this.history = [];
  }
}
```

### 3. Agent 核心：工具契约 (`core/Tool.ets`)

任何手机端系统能力、本地存储操作或局域网状态查询都可以封装成一个 `Tool`，供大模型在决策时按需调用：

```typescript
import { LlmToolDefinition } from './BaseLlm';

export abstract class Tool {
  /**
   * 工具的唯一名称
   */
  abstract name: string;

  /**
   * 工具的功能描述（供 LLM 阅读）
   */
  abstract description: string;

  /**
   * 工具的参数规范（JSON Schema 格式）
   */
  abstract parametersSchema: object;

  /**
   * 工具的核心执行方法
   * @param argsString JSON 格式的参数字符串
   */
  abstract run(argsString: string): Promise<string>;

  /**
   * 导出为 LLM 可识别的工具定义格式
   */
  public toLlmDefinition(): LlmToolDefinition {
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
```

#### 实际工具示例：获取局域网在线设备列表
```typescript
import { Tool } from './Tool';

export class GetLanDevicesTool extends Tool {
  name = 'get_lan_devices';
  description = '获取局域网内当前在线的其他 CourseDrop 设备列表，包含它们的设备名称、IP 地址与连接方式。';
  parametersSchema = {
    type: 'object',
    properties: {}, // 无需参数
  };

  async run(argsString: string): Promise<string> {
    try {
      // 此处可直接调用现有服务端的局域网发现列表
      // const devices = DeviceRegistry.getInstance().getActiveDevices();
      return JSON.stringify([
        { deviceName: "MacBook Pro", ip: "192.168.1.102", type: "LAN_DIRECT" },
        { deviceName: "Harmony Pad", ip: "192.168.1.105", type: "LAN_DIRECT" }
      ]);
    } catch (e) {
      return `获取设备列表失败: ${String(e)}`;
    }
  }
}
```

### 4. Agent 执行器 (`core/AgentExecutor.ets`)

AgentExecutor 负责大模型和工具之间的循环交互（ReAct 循环）：
1. 客户端发送用户问题给 LLM，附带所有可用的工具定义。
2. LLM 决定是直接回答，还是调用某个工具（输出 `tool_calls`）。
3. 如果调用工具，Executor 执行该工具并将输出结果拼回消息队列中。
4. 将更新后的队列再次发送给 LLM。这一循环重复执行，直到 LLM 给出最终的文本答案。

```typescript
import { BaseLlm, LlmMessage } from './BaseLlm';
import { Tool } from './Tool';

export class AgentExecutor {
  private llm: BaseLlm;
  private tools: Map<string, Tool> = new Map();
  private maxIterations: number = 5; // 限制防止死循环

  constructor(llm: BaseLlm, toolsList: Tool[]) {
    this.llm = llm;
    for (const tool of toolsList) {
      this.tools.set(tool.name, tool);
    }
  }

  public async execute(userQuery: string, historyMessages: LlmMessage[] = []): Promise<LlmMessage> {
    const sessionMessages: LlmMessage[] = [...historyMessages];
    sessionMessages.push({ role: 'user', content: userQuery });

    const toolDefinitions = Array.from(this.tools.values()).map(t => t.toLlmDefinition());

    for (let step = 0; step < this.maxIterations; step++) {
      // 1. 让大模型进行思考和判断
      const response = await this.llm.chat(sessionMessages, { tools: toolDefinitions });
      sessionMessages.push(response);

      // 2. 判断模型是否需要调用工具
      if (!response.tool_calls || response.tool_calls.length === 0) {
        // 模型没有请求调用工具，推理结束，直接返回模型的最终回复
        return response;
      }

      // 3. 模型请求调用一个或多个工具，依次执行它们
      for (const toolCall of response.tool_calls) {
        const toolName = toolCall.function.name;
        const toolArgs = toolCall.function.arguments;
        const targetTool = this.tools.get(toolName);

        let toolResult = '';
        if (targetTool) {
          console.info(`[CourseDrop Agent] Executing tool: ${toolName} with args: ${toolArgs}`);
          toolResult = await targetTool.run(toolArgs);
        } else {
          toolResult = `Error: Tool [${toolName}] not found.`;
        }

        // 4. 将工具的执行结果存回上下文，角色设为 'tool'
        sessionMessages.push({
          role: 'tool',
          name: toolName,
          content: toolResult
        });
      }
      
      // 完成一轮工具调用后，继续进入下一次循环让大模型基于工具返回的结果进行下一阶段的决策
    }

    throw new Error('Agent execution exceeded maximum iterations without reaching a final answer.');
  }
}
```

---

## 四、 后续开发建议

在有了这套设计方案后，开发步骤非常明确：
1. **统一模型抽象**：首先在 `services/ai/core/BaseLlm.ets` 中定义抽象。
2. **实现默认模型驱动**：在 `services/ai/providers/OpenAIProvider.ets` 中编写对接接口（该驱动可作为 DeepSeek API 的底座）。
3. **完成基本的 UI 问答**：建立 UI 视图，利用 `ChatMemory` 完成基础的多轮文档分析和对话。
4. **引入 Agent 能力**：编写 `Tool.ets` 和 `AgentExecutor.ets`，注册首批原生工具（如 `get_local_files`，`get_lan_devices` 等），让 AI 助手真正实现与 CourseDrop 应用状态进行深层交互。
