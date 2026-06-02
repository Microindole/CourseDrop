import router from '@ohos.router';
import { AppColors, AppRadius, AppSpacing, AppTypography } from '../common/Theme';
import { AiChatViewModel } from '../viewmodels';
import type { AiChatMessage } from '../viewmodels';

interface AiChatPageParams {
  conversationId?: string;
}

@Entry
@Component
struct AiChatPage {
  private viewModel: AiChatViewModel = new AiChatViewModel();

  @State inputText: string = '';
  @State messages: AiChatMessage[] = this.viewModel.getMessages();
  @State loading: boolean = false;
  @State errorMessage: string = '';
  @State revision: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as AiChatPageParams;
    if (params !== undefined && params.conversationId !== undefined && params.conversationId.length > 0) {
      this.viewModel.loadConversation(params.conversationId);
      this.syncView();
    }
  }

  aboutToDisappear(): void {
    this.viewModel.stop();
  }

  private syncView(): void {
    this.messages = this.viewModel.getMessages();
    this.loading = this.viewModel.loading;
    this.errorMessage = this.viewModel.errorMessage;
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
    this.syncView();
  }

  private openHistory(): void {
    router.pushUrl({ url: 'pages/AiChatHistoryPage' });
  }

  private openSettings(): void {
    router.pushUrl({ url: 'pages/AiChatSettingsPage' });
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

      Text(message.content.length > 0 ? message.content : '正在生成...')
        .fontSize(15)
        .fontColor(message.role === 'user' ? AppColors.SURFACE : AppColors.TEXT)
        .lineHeight(23)
        .padding({
          left: 14,
          right: 14,
          top: 10,
          bottom: 10
        })
        .backgroundColor(message.role === 'user' ? '#111827' : '#00000000')
        .borderRadius(18)
        .constraintSize({ maxWidth: '82%' })

      if (message.role === 'assistant') {
        Blank()
          .layoutWeight(1)
      }
    }
    .width('100%')
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

      Text('先从文本问答开始，当前不会读取你的本地文件。')
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

  build() {
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
        this.InputBar()
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 12 })
      .backgroundColor(AppColors.SURFACE)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.SURFACE)
  }
}
