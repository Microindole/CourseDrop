import { AppColors, AppRadius, AppSize, AppSpacing, AppTypography } from '../../common/Theme';
import { ShareSession } from '../../models/ShareSession';
import { CdPanel } from '../common/CdPanel';

@Component
export struct CdHomeRecentShares {
  recentShares: ShareSession[] = [];
  onRecentTap: (share: ShareSession) => void = (_share: ShareSession) => {};

  private sessionText(session: ShareSession): string {
    if (session.status === 'DRAFT') return '草稿';
    if (session.status === 'REVOKED') return '已撤回';
    if (session.status === 'EXPIRED') return '已过期';
    return session.expiresAt.length > 0 ? `有效至 ${session.expiresAt}` : '长效有效';
  }

  build() {
    if (this.recentShares.length === 0) {
      CdPanel({ hasShadow: true }) {
        Column() {
          Text('暂无最近分享的提取会话')
            .fontSize(AppTypography.BODY_SMALL)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
        .alignItems(HorizontalAlign.Center)
      }
    } else {
      ForEach(this.recentShares, (share: ShareSession) => {
        CdPanel({
          clickable: true,
          onTap: () => {
            this.onRecentTap(share);
          }
        }) {
          Row({ space: AppSpacing.MD }) {
            Stack() {
              Image($r('app.media.cd_icon_share'))
                .width(20)
                .height(20)
                .fillColor(AppColors.PRIMARY)
            }
            .width(40)
            .height(40)
            .backgroundColor(AppColors.PRIMARY_SOFT)
            .borderRadius(AppRadius.MD)
            .border({ width: 0.7, color: AppColors.PRIMARY })

            Column({ space: AppSpacing.XS }) {
              Row() {
                Text(share.title)
                  .fontSize(AppTypography.BODY_SMALL)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppColors.TEXT)
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                
                if (share.code.length > 0) {
                  Text(share.code)
                    .fontSize(10)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppColors.ACCENT)
                    .backgroundColor(AppColors.ACCENT_SOFT)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(AppRadius.SM)
                }
              }
              .width('100%')

              Text(`${share.itemCount} 项提取物 · ${this.sessionText(share)}`)
                .fontSize(AppTypography.CAPTION)
                .fontColor(AppColors.TEXT_SECONDARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
      }, (share: ShareSession) => share.id)
    }
  }
}
