import router from '@ohos.router';
import { AppColors, AppRadius, AppSpacing, AppTypography } from '../common/Theme';
import { AiMarkdownText, CdButton } from '../components/index';
import { LocalFileEntry } from '../models/LocalFileEntry';
import { AiChatViewModel } from '../viewmodels';
import type { AiChatMessage } from '../viewmodels';

interface AiChatPageParams {
  conversationId?: string;
  fileIds?: string[];
}

@Entry
@Component
struct AiChatPage {
  private viewModel: AiChatViewModel = new AiChatViewModel();

  @State inputText: string = '';
  @State messages: AiChatMessage[] = this.viewModel.getMessages();
  @State loading: boolean = false;
  @State errorMessage: string = '';
  @State contextFiles: LocalFileEntry[] = [];
  @State libraryFiles: LocalFileEntry[] = [];
  @State selectedLibraryIds: string[] = [];
  @State showFilePicker: boolean = false;
  @State revision: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as AiChatPageParams;
    if (params !== undefined && params.conversationId !== undefined && params.conversationId.length > 0) {
      this.viewModel.loadConversation(params.conversationId);
    }
    if (params !== undefined && params.fileIds !== undefined && params.fileIds.length > 0) {
      this.viewModel.addContextFilesByIds(params.fileIds);
    }
    this.syncView();
  }

  aboutToDisappear(): void {
    this.viewModel.stop();
  }

  private syncView(): void {
    this.messages = this.viewModel.getMessages();
    this.loading = this.viewModel.loading;
    this.errorMessage = this.viewModel.errorMessage;
    this.contextFiles = this.viewModel.getContextFiles();
    this.revision += 1;
  }

  private sendMessage(): void {
    const text = this.inputText.trim();
    if (text.length === 0 || this.loading) {
      return;
    }
    this.inputText = '';
    this.viewModel.send(text, () => {
      this.syncView();
    });
    this.syncView();
  }

  private stopMessage(): void {
    this.viewModel.stop();
    this.syncView();
  }

  private startNewChat(): void {
    this.viewModel.clear();
    this.inputText = '';
    this.contextFiles = [];
    this.selectedLibraryIds = [];
    this.showFilePicker = false;
    this.syncView();
  }

  private openHistory(): void {
    router.pushUrl({ url: 'pages/AiChatHistoryPage' });
  }

  private openSettings(): void {
    router.pushUrl({ url: 'pages/AiChatSettingsPage' });
  }

  private openFilePicker(): void {
    this.libraryFiles = this.viewModel.getLibraryFiles();
    this.selectedLibraryIds = this.contextFiles.map((file: LocalFileEntry) => file.id);
    this.showFilePicker = true;
  }

  private confirmFilePicker(): void {
    const selectedFiles: LocalFileEntry[] = [];
    this.libraryFiles.forEach((file: LocalFileEntry) => {
      if (this.selectedLibraryIds.includes(file.id)) {
        selectedFiles.push(file);
      }
    });
    this.viewModel.addContextFiles(selectedFiles);
    this.showFilePicker = false;
    this.selectedLibraryIds = [];
    this.syncView();
  }

  private togglePickerFile(id: string): void {
    if (this.selectedLibraryIds.includes(id)) {
      this.selectedLibraryIds = this.selectedLibraryIds.filter((nextId: string) => nextId !== id);
    } else {
      this.selectedLibraryIds.push(id);
    }
  }

  private removeContextFile(id: string): void {
    this.viewModel.removeContextFile(id);
    this.syncView();
  }

  private formatSize(sizeBytes: number): string {
    if (sizeBytes < 1024) return `${sizeBytes} B`;
    if (sizeBytes < 1024 * 1024) return `${Math.round(sizeBytes / 1024)} KB`;
    return `${Math.round(sizeBytes / 1024 / 1024)} MB`;
  }

  @Builder
  HeaderIcon(icon: Resource, onTap: () => void) {
    Stack() {
      Image(icon)
        .width(22)
        .height(22)
        .fillColor(AppColors.TEXT)
    }
    .width(42)
    .height(42)
    .borderRadius(21)
    .backgroundColor('#00000000')
    .onClick(() => {
      onTap();
    })
  }

  @Builder
  ChatHeader() {
    Row() {
      this.HeaderIcon($r('app.media.cd_icon_prev'), () => {
        router.back();
      })

      Row({ space: 6 }) {
        Text('课递助手')
          .fontSize(AppTypography.BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)

        Text(this.loading ? '生成中' : '在线')
          .fontSize(11)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      this.HeaderIcon($r('app.media.cd_icon_history'), () => {
        this.openHistory();
      })

      this.HeaderIcon($r('app.media.cd_icon_new_chat'), () => {
        this.startNewChat();
      })

      this.HeaderIcon($r('app.media.cd_icon_settings'), () => {
        this.openSettings();
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .backgroundColor(AppColors.SURFACE)
    .border({ width: { bottom: 0.5 }, color: AppColors.BORDER })
  }

  @Builder
  MessageBubble(message: AiChatMessage) {
    Row() {
      if (message.role === 'user') {
        Blank()
          .layoutWeight(1)
      }

      AiMarkdownText({
        content: message.content.length > 0 ? message.content : '正在生成...',
        isUser: false
      })
        .padding({
          left: message.role === 'user' ? 16 : 0,
          right: message.role === 'user' ? 16 : 0,
          top: message.role === 'user' ? 10 : 0,
          bottom: message.role === 'user' ? 10 : 0
        })
        .backgroundColor(message.role === 'user' ? '#F1F2F4' : '#00000000')
        .borderRadius(message.role === 'user' ? 20 : 0)
        .width(message.role === 'user' && message.content.length > 18 ? '76%' : 'auto')
        .constraintSize({ maxWidth: message.role === 'user' ? '76%' : '92%' })

      if (message.role === 'assistant') {
        Blank()
          .layoutWeight(1)
      }
    }
    .width('100%')
    .padding({
      left: message.role === 'assistant' ? 0 : 40,
      right: message.role === 'user' ? 0 : 18
    })
  }

  @Builder
  EmptyState() {
    Column({ space: AppSpacing.MD }) {
      Row() {
        Image($r('app.media.cd_icon_text'))
          .width(28)
          .height(28)
          .fillColor(AppColors.TEXT)
      }
      .width(56)
      .height(56)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(AppColors.SURFACE_MUTED)
      .borderRadius(28)

      Text('有什么可以帮忙？')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT)

      Text(this.contextFiles.length > 0 ? `已准备读取 ${this.contextFiles.length} 个本地库文件，输入问题后开始分析。` : '可直接提问，也可以先选择本地库文件作为阅读上下文。')
        .fontSize(AppTypography.BODY_SMALL)
        .fontColor(AppColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 88, left: 24, right: 24 })
  }

  @Builder
  InputBar() {
    Row({ space: AppSpacing.SM }) {
      TextArea({ placeholder: '给课递助手发消息', text: this.inputText })
        .layoutWeight(1)
        .height(44)
        .fontSize(15)
        .fontColor(AppColors.TEXT)
        .placeholderColor(AppColors.MUTED)
        .backgroundColor('#00000000')
        .padding({ left: 14, right: 8 })
        .onChange((value: string) => {
          this.inputText = value;
        })

      Stack() {
        Image($r('app.media.cd_icon_robots'))
          .width(19)
          .height(19)
          .fillColor(this.contextFiles.length > 0 ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
      }
      .width(38)
      .height(38)
      .borderRadius(19)
      .backgroundColor(this.contextFiles.length > 0 ? AppColors.PRIMARY_SOFT : AppColors.SURFACE_MUTED)
      .onClick(() => {
        if (!this.loading) {
          this.openFilePicker();
        }
      })

      Stack() {
        Image(this.loading ? $r('app.media.cd_icon_close') : $r('app.media.cd_icon_send'))
          .width(20)
          .height(20)
          .fillColor(this.loading || this.inputText.trim().length > 0 ? AppColors.SURFACE : AppColors.MUTED)
      }
      .width(38)
      .height(38)
      .borderRadius(19)
      .backgroundColor(this.loading || this.inputText.trim().length > 0 ? '#111827' : AppColors.SURFACE_MUTED)
      .onClick(() => {
        if (this.loading) {
          this.stopMessage();
        } else {
          this.sendMessage();
        }
      })
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(26)
    .border({ width: 0.7, color: AppColors.BORDER })
  }

  @Builder
  ContextFilesBar() {
    if (this.contextFiles.length > 0) {
      Column({ space: AppSpacing.SM }) {
        Row() {
          Text(`AI 将阅读 ${this.contextFiles.length} 个文件`)
            .fontSize(AppTypography.CAPTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
            .layoutWeight(1)

          Text('清空')
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.PRIMARY)
            .onClick(() => {
              this.viewModel.clearContextFiles();
              this.syncView();
            })
        }
        .width('100%')

        Scroll() {
          Row({ space: AppSpacing.SM }) {
            ForEach(this.contextFiles, (file: LocalFileEntry) => {
              Row({ space: 6 }) {
                Image($r('app.media.cd_icon_file'))
                  .width(14)
                  .height(14)
                  .fillColor(AppColors.PRIMARY)

                Text(file.displayName)
                  .fontSize(AppTypography.CAPTION)
                  .fontColor(AppColors.TEXT)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .constraintSize({ maxWidth: 120 })

                Image($r('app.media.cd_icon_close'))
                  .width(12)
                  .height(12)
                  .fillColor(AppColors.MUTED)
              }
              .height(30)
              .padding({ left: 10, right: 8 })
              .backgroundColor(AppColors.PRIMARY_SOFT)
              .borderRadius(AppRadius.MD)
              .onClick(() => {
                this.removeContextFile(file.id);
              })
            }, (file: LocalFileEntry) => file.id)
          }
        }
        .width('100%')
        .height(34)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .padding({ left: 4, right: 4, bottom: 8 })
    }
  }

  @Builder
  FilePickerSheet() {
    Column({ space: AppSpacing.MD }) {
      Row() {
        Text('选择本地库文件')
          .fontSize(AppTypography.BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)
          .layoutWeight(1)

        Text('取消')
          .fontSize(AppTypography.BODY_SMALL)
          .fontColor(AppColors.TEXT_SECONDARY)
          .onClick(() => {
            this.showFilePicker = false;
            this.selectedLibraryIds = [];
          })
      }
      .width('100%')

      if (this.libraryFiles.length === 0) {
        Column({ space: AppSpacing.SM }) {
          Image($r('app.media.cd_icon_library'))
            .width(34)
            .height(34)
            .fillColor(AppColors.MUTED)

          Text('本地库暂无可选文件')
            .fontSize(AppTypography.BODY_SMALL)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ top: AppSpacing.XL, bottom: AppSpacing.XL })
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: AppSpacing.SM }) {
            ForEach(this.libraryFiles, (file: LocalFileEntry) => {
              Row({ space: AppSpacing.SM }) {
                Stack() {
                  if (this.selectedLibraryIds.includes(file.id)) {
                    Circle()
                      .width(22)
                      .height(22)
                      .fill(AppColors.PRIMARY)
                    Image($r('app.media.cd_icon_done'))
                      .width(12)
                      .height(12)
                      .fillColor(AppColors.SURFACE)
                  } else {
                    Circle()
                      .width(22)
                      .height(22)
                      .fill(Color.Transparent)
                      .stroke(AppColors.BORDER_STRONG)
                      .strokeWidth(1.4)
                  }
                }
                .width(24)
                .height(24)

                Image($r('app.media.cd_icon_file'))
                  .width(22)
                  .height(22)
                  .fillColor(AppColors.PRIMARY)

                Column({ space: 2 }) {
                  Text(file.displayName)
                    .fontSize(AppTypography.BODY_SMALL)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppColors.TEXT)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(`${file.contentType} · ${this.formatSize(file.sizeBytes)}`)
                    .fontSize(AppTypography.CAPTION)
                    .fontColor(AppColors.TEXT_SECONDARY)
                    .maxLines(1)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .height(58)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
              .backgroundColor(this.selectedLibraryIds.includes(file.id) ? AppColors.PRIMARY_SOFT : AppColors.SURFACE_MUTED)
              .borderRadius(AppRadius.MD)
              .onClick(() => {
                this.togglePickerFile(file.id);
              })
            }, (file: LocalFileEntry) => file.id)
          }
        }
        .width('100%')
        .height(300)
        .scrollBar(BarState.Off)
      }

      Row({ space: AppSpacing.SM }) {
        CdButton({
          label: '确认加入上下文',
          interactive: this.selectedLibraryIds.length > 0,
          onTap: () => {
            this.confirmFilePicker();
          }
        })
          .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: AppSpacing.LG, bottom: AppSpacing.XL })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius({ topLeft: AppRadius.XL, topRight: AppRadius.XL })
    .shadow({ radius: 24, color: '#1A0B2A4A', offsetX: 0, offsetY: -8 })
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        if (this.revision < 0) {
          Blank()
        }

        this.ChatHeader()

        Scroll() {
          Column({ space: 18 }) {
            if (this.messages.length === 0) {
              this.EmptyState()
            } else {
              ForEach(this.messages, (message: AiChatMessage) => {
                this.MessageBubble(message)
              }, (message: AiChatMessage) => `${message.id}-${message.content.length}-${message.streaming}`)
            }

            if (this.errorMessage.length > 0) {
              Text(this.errorMessage)
                .fontSize(AppTypography.CAPTION)
                .fontColor(AppColors.DANGER)
                .padding(12)
                .backgroundColor(AppColors.DANGER_SOFT)
                .borderRadius(AppRadius.MD)
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 20, bottom: 20 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)

        Column() {
          this.ContextFilesBar()
          this.InputBar()
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 12 })
        .backgroundColor(AppColors.SURFACE)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.SURFACE)

      if (this.showFilePicker) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .onClick(() => {
            this.showFilePicker = false;
            this.selectedLibraryIds = [];
          })

        this.FilePickerSheet()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.SURFACE)
  }
}
