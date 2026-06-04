import { AppColors, AppRadius, AppSpacing, AppTypography } from '../../common/Theme';
import { ShareSession } from '../../models/ShareSession';
import { CdButton } from '../common/CdButton';
import { CdIconButton } from '../common/CdIconButton';
import { CdPanel } from '../common/CdPanel';

@Component
export struct CdShareControlCenter {
  @Link currentSession: ShareSession;
  @Prop loading: boolean = false;
  @Prop expireText: string = '';
  @Prop qrImageUrl: string = '';
  @Prop qrFallbackText: string = '';
  @Prop errorMessage: string = '';
  onReturn: () => void = () => {};
  onExtend: () => void = () => {};
  onCopy: () => void = () => {};
  onCopyCode: () => void = () => {};
  onCreate: () => void = () => {};

  build() {
    CdPanel({ hasShadow: true }) {
      Column({ space: AppSpacing.MD }) {
        Row({ space: AppSpacing.SM }) {
          // 状态灯
          Stack() {
            Circle()
              .width(20)
              .height(20)
              .fill(this.currentSession.shareUrl.length > 0 ? AppColors.SUCCESS_SOFT : AppColors.SURFACE_MUTED)
            Circle()
              .width(10)
              .height(10)
              .fill(this.currentSession.shareUrl.length > 0 ? AppColors.SUCCESS : AppColors.MUTED)
          }
          .width(24)
          .height(24)
          .align(Alignment.Center)

          Column({ space: 2 }) {
            Text(this.currentSession.shareUrl.length > 0 ? '公网临时分享已激活' : '公网临时分享未创建')
              .fontSize(AppTypography.BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)

            Text(this.expireText)
              .fontSize(AppTypography.CAPTION)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text(this.currentSession.encrypted ? 'E2EE' : 'RELAY')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentSession.encrypted ? AppColors.SUCCESS : AppColors.PRIMARY_SELECTED)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: 3, bottom: 3 })
            .backgroundColor(this.currentSession.encrypted ? AppColors.SUCCESS_SOFT : AppColors.PRIMARY_SOFT)
            .borderRadius(AppRadius.SM)

        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 提取码大字展示
        if (this.currentSession.code.length > 0) {
          Column({ space: AppSpacing.SM }) {
            Text('分享提取码')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_SECONDARY)

            Text(this.currentSession.code)
              .fontSize(AppTypography.DISPLAY)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
              .letterSpacing(3)

            Text('点击复制提取码')
              .fontSize(AppTypography.CAPTION)
              .fontColor(AppColors.PRIMARY_SELECTED)
              .fontWeight(FontWeight.Bold)
              .onClick(() => {
                this.onCopyCode();
              })
          }
          .width('100%')
          .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
          .backgroundColor(AppColors.SURFACE)
          .borderRadius(AppRadius.LG)
          .border({ width: 0.7, color: AppColors.PRIMARY })
          .alignItems(HorizontalAlign.Center)
        }

        if (this.currentSession.shareUrl.length > 0) {
          Column({ space: AppSpacing.SM }) {
            Text('扫码下载')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_SECONDARY)

            if (this.qrImageUrl.length > 0) {
              Image(this.qrImageUrl)
                .width(160)
                .height(160)
                .objectFit(ImageFit.Contain)
            } else {
              Text(this.qrFallbackText.length > 0 ? this.qrFallbackText : this.currentSession.shareUrl)
                .fontSize(AppTypography.CAPTION)
                .fontColor(AppColors.TEXT_SECONDARY)
                .textAlign(TextAlign.Center)
                .maxLines(5)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .width('100%')
          .padding(AppSpacing.MD)
          .backgroundColor(AppColors.SURFACE_RAISED)
          .border({ width: 1, color: AppColors.BORDER })
          .borderRadius(AppRadius.LG)

          Row({ space: AppSpacing.SM }) {
            Text(this.currentSession.shareUrl)
              .fontSize(AppTypography.BODY_SMALL)
              .fontColor(AppColors.PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            
            CdIconButton({
              icon: $r('app.media.cd_icon_copy'),
              variant: 'plain',
              onTap: () => {
                this.onCopy();
              }
            })
          }
          .width('100%')
          .padding(AppSpacing.MD)
          .backgroundColor(AppColors.PRIMARY_SOFT)
          .borderRadius(AppRadius.MD)

          Row({ space: AppSpacing.SM }) {
            CdButton({
              label: '续期 24 小时',
              variant: 'tonal',
              interactive: !this.loading,
              onTap: () => {
                this.onExtend();
              }
            })
            .layoutWeight(1)

            CdButton({
              label: '返回',
              variant: 'danger',
              interactive: !this.loading,
              onTap: () => {
                this.onReturn();
              }
            })
            .layoutWeight(1)
          }
          .width('100%')
        } else {
          Text('向草稿中添加文件或图片，然后点击“生成提取链接”，服务器将在安全期内托管您的临时文件。')
            .fontSize(AppTypography.BODY_SMALL)
            .fontColor(AppColors.TEXT_SECONDARY)
            .lineHeight(18)
        }

        if (this.currentSession.shareUrl.length === 0) {
          CdButton({
            label: this.loading ? '正在生成链接并上传当前草稿...' : '生成公网提取链接',
            interactive: !this.loading && this.currentSession.items.length > 0,
            onTap: () => {
              this.onCreate();
            }
          })
          .width('100%')
        }

        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(AppTypography.BODY_SMALL)
            .fontColor(AppColors.DANGER)
            .lineHeight(18)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }
}
