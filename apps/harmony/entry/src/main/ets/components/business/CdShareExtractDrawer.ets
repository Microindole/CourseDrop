import { AppColors, AppRadius, AppShadows, AppSpacing, AppTypography } from '../../common/Theme';
import { ShareSession } from '../../models/ShareSession';
import { CdButton } from '../common/CdButton';

@Component
export struct CdShareExtractDrawer {
  @Link selectedShare: ShareSession | null;
  @Prop qrImageUrl: string = '';
  @Prop qrErrorText: string = '';
  onCopyCode: (code: string) => void = () => {};
  onCopyLink: (link: string) => void = () => {};

  private expireText(share: ShareSession): string {
    if (share.expiresAt.length === 0) {
      return '长期有效';
    }
    return `有效至 ${share.expiresAt}`;
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.selectedShare !== null) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor('#55000000')
          .onClick(() => {
            animateTo({ duration: 250, curve: Curve.FastOutSlowIn }, () => {
              this.selectedShare = null;
            });
          })
          .transition({ opacity: 0 })

        Column({ space: AppSpacing.LG }) {
          Row() {
            Rect()
              .width(36)
              .height(4)
              .radius(2)
              .fill(AppColors.BORDER_STRONG)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })

          Column({ space: AppSpacing.XS }) {
            Text(this.selectedShare.title.length > 0 ? this.selectedShare.title : 'CourseDrop 提取链接')
              .fontSize(AppTypography.SUBTITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(`${this.selectedShare.itemCount} 项内容 · ${this.expireText(this.selectedShare)}`)
              .fontSize(AppTypography.BODY_SMALL)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Column({ space: AppSpacing.SM }) {
            Text('提取码')
              .fontSize(AppTypography.CAPTION)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_SECONDARY)

            Text(this.selectedShare.code)
              .fontSize(AppTypography.DISPLAY)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
              .letterSpacing(3)
          }
          .width('100%')
          .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
          .backgroundColor(AppColors.BACKGROUND)
          .borderRadius(AppRadius.MD)
          .alignItems(HorizontalAlign.Center)

          Column({ space: AppSpacing.SM }) {
            Text('扫码提取')
              .fontSize(AppTypography.CAPTION)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_SECONDARY)

            if (this.qrImageUrl.length > 0) {
              Image(this.qrImageUrl)
                .width(180)
                .height(180)
                .objectFit(ImageFit.Contain)
            } else {
              Text(this.qrErrorText.length > 0 ? this.qrErrorText : '二维码生成中')
                .fontSize(AppTypography.BODY_SMALL)
                .fontColor(this.qrErrorText.length > 0 ? AppColors.DANGER : AppColors.TEXT_SECONDARY)
                .textAlign(TextAlign.Center)
                .lineHeight(18)
            }
          }
          .width('100%')
          .padding(AppSpacing.MD)
          .backgroundColor(AppColors.BACKGROUND)
          .borderRadius(AppRadius.MD)
          .alignItems(HorizontalAlign.Center)

          Row({ space: AppSpacing.MD }) {
            CdButton({
              label: '复制提取码',
              variant: 'tonal',
              onTap: () => {
                const share = this.selectedShare;
                if (share !== null) {
                  this.onCopyCode(share.code);
                }
              }
            })
            .layoutWeight(1)

            CdButton({
              label: '复制链接',
              onTap: () => {
                const share = this.selectedShare;
                if (share !== null) {
                  this.onCopyLink(share.shareUrl);
                }
              }
            })
            .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: AppSpacing.LG, right: AppSpacing.LG, bottom: AppSpacing.XL + 10 })
        .backgroundColor(AppColors.SURFACE)
        .borderRadius({ topLeft: AppRadius.XL, topRight: AppRadius.XL })
        .shadow(AppShadows.FLOATING)
        .transition({ translate: { y: '100%' } })
      }
    }
    .width('100%')
    .height('100%')
  }
}
