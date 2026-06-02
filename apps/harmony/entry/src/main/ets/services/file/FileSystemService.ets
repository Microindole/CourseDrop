import { fileIo, fileUri } from '@kit.CoreFileKit';

export interface FileMetadata {
  sizeBytes: number;
  contentType: string;
}

export interface CreatedTextFile {
  path: string;
  uri: string;
  sizeBytes: number;
}

export interface CopiedFile {
  path: string;
  uri: string;
  sizeBytes: number;
}

export class FileSystemService {
  stat(uri: string, fallbackContentType: string): FileMetadata {
    try {
      const stat = fileIo.statSync(this.toLocalPath(uri));
      return {
        sizeBytes: stat.size,
        contentType: fallbackContentType
      };
    } catch (error) {
      console.error(`[CourseDrop] file stat failed: ${String(error)}`);
      return {
        sizeBytes: 0,
        contentType: fallbackContentType
      };
    }
  }

  ensureDirectory(path: string): void {
    if (path.length === 0) {
      return;
    }
    const normalized = path.replace(/\\/g, '/');
    const parts = normalized.split('/');
    let current = normalized.startsWith('/') ? '/' : '';
    parts.forEach((part: string) => {
      if (part.length === 0) {
        return;
      }
      if (current.length === 0 || current === '/') {
        current = part;
        if (normalized.startsWith('/')) {
          current = `/${part}`;
        }
      } else {
        current = `${current}/${part}`;
      }
      this.mkdirIfMissing(current);
    });
  }

  private mkdirIfMissing(path: string): void {
    try {
      fileIo.mkdirSync(path);
    } catch (_error) {
    }
  }

  copyToDirectory(sourceUri: string, targetDirectory: string, displayName: string): CopiedFile {
    this.ensureDirectory(targetDirectory);
    const targetPath = `${targetDirectory}/${Date.now()}-${this.sanitizeFileName(displayName)}`;
    const sourceFile = this.openReadOnly(sourceUri);
    const targetFile = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
    try {
      this.copyOpenedFile(sourceFile.fd, targetFile.fd);
    } finally {
      fileIo.closeSync(sourceFile.fd);
      fileIo.closeSync(targetFile.fd);
    }
    const targetStat = fileIo.statSync(targetPath);
    if (targetStat.size <= 0) {
      throw new Error(`文件复制失败：${displayName} 为空或无法读取`);
    }
    return {
      path: targetPath,
      uri: fileUri.getUriFromPath(targetPath),
      sizeBytes: targetStat.size
    };
  }

  writeTextFile(targetDirectory: string, displayName: string, content: string): CreatedTextFile {
    if (targetDirectory.length === 0) {
      throw new Error('目标目录为空');
    }
    this.ensureDirectory(targetDirectory);
    const targetPath = `${targetDirectory}/${Date.now()}-${this.sanitizeFileName(displayName)}`;
    const file = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
    try {
      fileIo.writeSync(file.fd, this.toUtf8(content));
    } finally {
      fileIo.closeSync(file.fd);
    }
    const stat = fileIo.statSync(targetPath);
    return {
      path: targetPath,
      uri: fileUri.getUriFromPath(targetPath),
      sizeBytes: stat.size
    };
  }

  readAll(uri: string): ArrayBuffer {
    const path = this.toLocalPath(uri);
    const stat = fileIo.statSync(path);
    if (stat.size <= 0) {
      throw new Error(`文件为空或无法读取：${path}`);
    }
    const file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
    try {
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      return buffer;
    } finally {
      fileIo.closeSync(file.fd);
    }
  }

  private sanitizeFileName(displayName: string): string {
    return displayName
      .replace(/\//g, '_')
      .replace(/\\/g, '_')
      .replace(/:/g, '_');
  }

  private toLocalPath(uri: string): string {
    if (!uri.startsWith('file://')) {
      return uri;
    }
    return decodeURIComponent(uri.replace(/^file:\/\//, ''));
  }

  private openReadOnly(uri: string): fileIo.File {
    try {
      return fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    } catch (_error) {
      return fileIo.openSync(this.toLocalPath(uri), fileIo.OpenMode.READ_ONLY);
    }
  }

  private copyOpenedFile(sourceFd: number, targetFd: number): void {
    try {
      fileIo.copyFileSync(sourceFd, targetFd);
    } catch (_error) {
      const bufferSize = 1024 * 256;
      const buffer = new ArrayBuffer(bufferSize);
      let readSize = fileIo.readSync(sourceFd, buffer);
      while (readSize > 0) {
        if (readSize === bufferSize) {
          fileIo.writeSync(targetFd, buffer);
        } else {
          fileIo.writeSync(targetFd, buffer.slice(0, readSize));
        }
        readSize = fileIo.readSync(sourceFd, buffer);
      }
    }
  }

  private toUtf8(text: string): ArrayBuffer {
    const encoded = new Uint8Array(text.length);
    for (let index = 0; index < text.length; index += 1) {
      encoded[index] = text.charCodeAt(index);
    }
    return encoded.buffer;
  }
}
