import router from '@ohos.router';
import { AppColors, AppRadius, AppSpacing, AppTypography } from '../common/Theme';
import { AiChatViewModel } from '../viewmodels';
import type { AiConversationSummary } from '../services/ai';

interface AiChatRouteParams {
  conversationId: string;
}

@Entry
@Component
struct AiChatHistoryPage {
  private viewModel: AiChatViewModel = new AiChatViewModel();

  @State conversations: AiConversationSummary[] = [];
  @State revision: number = 0;

  aboutToAppear(): void {
    this.refresh();
  }

  private refresh(): void {
    this.conversations = this.viewModel.listConversations();
    this.revision += 1;
  }

  private formatTime(value: number): string {
    return new Date(value).toLocaleString();
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
    .onClick(() => {
      onTap();
    })
  }

  @Builder
  HistoryRow(item: AiConversationSummary) {
    Row({ space: AppSpacing.MD }) {
      Column({ space: 6 }) {
        Text(item.title)
          .fontSize(AppTypography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${item.messageCount} 条消息 · ${this.formatTime(item.updatedAt)}`)
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .onClick(() => {
        const params: AiChatRouteParams = {
          conversationId: item.id
        };
        router.pushUrl({
          url: 'pages/AiChatPage',
          params: params
        });
      })

      Stack() {
        Image($r('app.media.cd_icon_trash'))
          .width(18)
          .height(18)
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .onClick(() => {
        this.viewModel.removeConversation(item.id);
        this.refresh();
      })
    }
    .width('100%')
    .padding({ left: 16, right: 10, top: 14, bottom: 14 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.LG)
    .border({ width: 0.7, color: AppColors.BORDER })
  }

  build() {
    Column() {
      if (this.revision < 0) {
        Blank()
      }

      Row() {
        this.HeaderIcon($r('app.media.cd_icon_prev'), () => {
          router.back();
        })

        Text('历史对话')
          .fontSize(AppTypography.BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        this.HeaderIcon($r('app.media.cd_icon_new_chat'), () => {
          router.pushUrl({ url: 'pages/AiChatPage' });
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor(AppColors.SURFACE)

      Scroll() {
        Column({ space: AppSpacing.MD }) {
          if (this.conversations.length === 0) {
            Column({ space: AppSpacing.MD }) {
              Text('暂无历史对话')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT)

              Text('开始一次聊天后，会话会自动保存在这里。')
                .fontSize(AppTypography.BODY_SMALL)
                .fontColor(AppColors.TEXT_SECONDARY)
            }
            .width('100%')
            .padding({ top: 96 })
          } else {
            ForEach(this.conversations, (item: AiConversationSummary) => {
              this.HistoryRow(item)
            }, (item: AiConversationSummary) => `${item.id}-${item.updatedAt}`)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND_DEEP)
  }
}
