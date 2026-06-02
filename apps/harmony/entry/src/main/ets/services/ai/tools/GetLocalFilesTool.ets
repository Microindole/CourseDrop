import type { LocalFileIndexRepository } from '../../local';
import { Tool } from './Tool';
import type { ToolParameterSchema, ToolParametersProperties, ToolParametersSchema, ToolRunContext } from './Tool';

interface LocalFileToolItem {
  id: string;
  displayName: string;
  type: string;
  contentType: string;
  sizeBytes: number;
  encrypted: boolean;
  remoteCached: boolean;
  shareCount: number;
}

export class GetLocalFilesTool extends Tool {
  name: string = 'get_local_files';
  description: string = '读取 CourseDrop 本地库文件列表，只返回元数据，不读取文件正文。';
  parametersSchema: ToolParametersSchema = this.createParametersSchema();

  private repository: LocalFileIndexRepository;

  constructor(repository: LocalFileIndexRepository) {
    super();
    this.repository = repository;
  }

  async run(argsString: string, _context?: ToolRunContext): Promise<string> {
    let limit = 20;
    try {
      const args = JSON.parse(argsString) as GetLocalFilesArgs;
      if (args.limit !== undefined && args.limit > 0) {
        limit = Math.min(args.limit, 100);
      }
    } catch (_error) {
    }
    const files = this.repository.list().slice(0, limit).map((file) => {
      const item: LocalFileToolItem = {
        id: file.id,
        displayName: file.displayName,
        type: file.type,
        contentType: file.contentType,
        sizeBytes: file.sizeBytes,
        encrypted: file.encrypted,
        remoteCached: file.remoteCached,
        shareCount: file.shareCount
      };
      return item;
    });
    return JSON.stringify(files);
  }

  private createParametersSchema(): ToolParametersSchema {
    const limitSchema: ToolParameterSchema = {
      type: 'number',
      description: '最多返回多少个文件，默认 20。'
    };
    const properties: ToolParametersProperties = {
      limit: limitSchema
    };
    return {
      type: 'object',
      properties: properties
    };
  }
}

interface GetLocalFilesArgs {
  limit?: number;
}
