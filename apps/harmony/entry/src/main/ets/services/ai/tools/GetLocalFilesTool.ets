import type { LocalFileIndexRepository } from '../../local';
import { Tool } from './Tool';
import type { ToolRunContext } from './Tool';

export class GetLocalFilesTool extends Tool {
  name: string = 'get_local_files';
  description: string = '读取 CourseDrop 本地库文件列表，只返回元数据，不读取文件正文。';
  parametersSchema: object = {
    type: 'object',
    properties: {
      limit: {
        type: 'number',
        description: '最多返回多少个文件，默认 20。'
      }
    }
  };

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
      return {
        id: file.id,
        displayName: file.displayName,
        type: file.type,
        contentType: file.contentType,
        sizeBytes: file.sizeBytes,
        encrypted: file.encrypted,
        remoteCached: file.remoteCached,
        shareCount: file.shareCount
      };
    });
    return JSON.stringify(files);
  }
}

interface GetLocalFilesArgs {
  limit?: number;
}
