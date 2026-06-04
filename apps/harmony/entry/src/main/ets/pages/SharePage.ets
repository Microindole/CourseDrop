import router from '@ohos.router';
import { AppColors, AppSpacing, AppTypography } from '../common/Theme';
import {
  CdBanner,
  CdButton,
  CdScrollContainer,
  CdSectionHeader,
  CdTopBar,
  CdPanel,
  CdActionIcon,
  CdShareControlCenter,
  CdShareDraftList,
  CdShareTaskList
} from '../components/index';
import { TransferItem } from '../models/TransferItem';
import { TransferTask } from '../models/TransferTask';
import { ShareSession } from '../models/ShareSession';
import { ShareViewModel } from '../viewmodels/ShareViewModel';

@Component
export default struct SharePage {
  showBack: boolean = true;
  private viewModel: ShareViewModel = new ShareViewModel();

  @State currentSession: ShareSession = this.viewModel.currentSession;
  @State draftItems: TransferItem[] = [];
  @State tasks: TransferTask[] = [];
  @State lastActionText: string = '分享内容由 CourseDrop 中转源托管';
  @State errorMessage: string = '';
  @State qrImageUrl: string = '';
  @State loading: boolean = false;
  @State refreshing: boolean = false;

  aboutToAppear() {
    this.syncState();
  }

  private syncState() {
    const session = this.viewModel.currentSession;
    const items = session.items.map((item: TransferItem) => this.copyItem(item));
    this.currentSession = {
      id: session.id,
      title: session.title,
      code: session.code,
      shareUrl: session.shareUrl,
      status: session.status,
      networkMode: session.networkMode,
      expireStatus: session.expireStatus,
      createdAt: session.createdAt,
      expiresAt: session.expiresAt,
      itemCount: session.itemCount,
      totalSizeBytes: session.totalSizeBytes,
      encrypted: session.encrypted,
      downloadPolicy: session.downloadPolicy,
      items: items
    };
    this.draftItems = items.map((item: TransferItem) => this.copyItem(item));
    this.tasks = this.viewModel.getTasks();
    this.lastActionText = this.viewModel.lastActionText.length > 0 ? this.viewModel.lastActionText : '分享内容由 CourseDrop 中转源托管';
    this.errorMessage = this.viewModel.errorMessage;
    this.loading = this.viewModel.loading;
    this.loadQrImage();
  }

  private loadQrImage(): void {
    if (this.currentSession.shareUrl.length === 0) {
      this.qrImageUrl = '';
      return;
    }
    this.viewModel.loadShareQrImage()
      .then((localUri: string) => {
        this.qrImageUrl = localUri;
      })
      .catch((error: Error) => {
        this.qrImageUrl = '';
        this.errorMessage = `二维码加载失败：${String(error)}；${this.viewModel.getShareQrImageUrl()}`;
      });
  }

  private copyItem(item: TransferItem): TransferItem {
    return {
      id: item.id,
      roomId: item.roomId,
      sessionId: item.sessionId,
      type: item.type,
      displayName: item.displayName,
      contentType: item.contentType,
      sizeBytes: item.sizeBytes,
      localUri: item.localUri,
      remoteUrl: item.remoteUrl,
      remoteItemId: item.remoteItemId,
      createdAt: item.createdAt,
      expiresAt: item.expiresAt,
      encrypted: item.encrypted
    };
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      CdScrollContainer({ showScrollBar: true, backgroundStyle: 'share' }) {
        CdTopBar({
          title: '创建临时分享',
          subtitle: '生成安全提取码，多端临时下载',
          leadingText: this.showBack ? '返回' : '',
          trailingText: this.refreshing ? '刷新中' : '刷新',
          onLeadingTap: () => {
            router.back();
          },
          onTrailingTap: () => {
            this.refreshing = true;
            this.lastActionText = '正在刷新当前分享状态...';
            this.errorMessage = '';
            setTimeout(() => {
              this.viewModel.refreshStatus();
              this.syncState();
              this.refreshing = false;
            }, 300);
          }
        })

        CdBanner({
          title: this.lastActionText,
          description: this.errorMessage.length > 0 ? this.errorMessage : '中转源仅按时效托管临时内容；启用加密时服务器不持有明文密钥。',
          tone: this.errorMessage.length > 0 ? 'danger' : 'info'
        })

        CdPanel({ hasShadow: true }) {
          Row({ space: AppSpacing.MD }) {
            Stack() {
              Image($r('app.media.cd_icon_link'))
                .width(22)
                .height(22)
                .fillColor(AppColors.ACCENT)
            }
            .width(46)
            .height(46)
            .backgroundColor(AppColors.ACCENT_SOFT)
            .borderRadius(16)
            .border({ width: 0.7, color: AppColors.ACCENT })

            Column({ space: 4 }) {
              Text('接收别人分享')
                .fontSize(AppTypography.BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT)

              Text('扫码或输入提取码，下载到本地库')
                .fontSize(AppTypography.BODY_SMALL)
                .fontColor(AppColors.TEXT_SECONDARY)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            CdActionIcon({
              icon: $r('app.media.cd_icon_search'),
              label: '',
              tone: AppColors.PRIMARY,
              bgColor: AppColors.PRIMARY_SOFT,
              compact: true,
              onTap: () => {
                router.pushUrl({ url: 'pages/ShareDownloadPage' });
              }
            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }

        // 提取中心控制卡片
        CdShareControlCenter({
          currentSession: $currentSession,
          loading: this.loading,
          expireText: this.viewModel.getExpireText(),
          qrImageUrl: this.qrImageUrl,
          qrFallbackText: this.viewModel.getShareQrImageUrl(),
          errorMessage: this.errorMessage,
          onReturn: () => {
            this.loading = true;
            this.lastActionText = '正在返回新的分享草稿...';
            this.errorMessage = '';
            this.viewModel.returnToDraft();
            this.syncState();
          },
          onExtend: () => {
            this.loading = true;
            this.lastActionText = '正在续期 24 小时...';
            this.errorMessage = '';
            this.viewModel.extendShare().then(() => {
              this.syncState();
            });
          },
          onCopy: () => {
            this.viewModel.copyShareLink().then(() => {
              this.syncState();
            });
          },
          onCopyCode: () => {
            this.viewModel.copyShareCode().then(() => {
              this.syncState();
            });
          },
          onCreate: () => {
            this.loading = true;
            this.lastActionText = '正在生成链接并上传...';
            this.errorMessage = '';
            this.viewModel.refreshShareCode().then(() => {
              this.syncState();
            }).catch((error: Error) => {
              this.loading = false;
              this.errorMessage = String(error);
            });
          }
        })

        // 添加草稿操作区域
        CdPanel() {
          Column({ space: AppSpacing.MD }) {
            Row() {
              Text('添加内容至分享草稿')
                .fontSize(AppTypography.BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT)
                .layoutWeight(1)

              if (this.draftItems.length > 0 && this.currentSession.shareUrl.length === 0) {
                Text('清空')
                  .fontSize(AppTypography.BODY_SMALL)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppColors.DANGER)
                  .onClick(() => {
                    this.viewModel.clearDraft();
                    this.syncState();
                  })
              }
            }
            .width('100%')

            if (this.currentSession.shareUrl.length === 0) {
              Row({ space: AppSpacing.MD }) {
                CdButton({
                  label: '添加本地文件',
                  variant: 'tonal',
                  onTap: () => {
                    this.viewModel.addLocalItem('FILE').then(() => {
                      this.syncState();
                    });
                  }
                })
                .layoutWeight(1)

                CdButton({
                  label: '添加图片/照片',
                  variant: 'tonal',
                  onTap: () => {
                    this.viewModel.addLocalItem('IMAGE').then(() => {
                      this.syncState();
                    });
                  }
                })
                .layoutWeight(1)
              }
              .width('100%')
            } else {
              Text('当前链接已生成。若要分享新文件，请点击上方“返回”创建新的分享草稿。')
                .fontSize(AppTypography.BODY_SMALL)
                .fontColor(AppColors.TEXT_SECONDARY)
                .lineHeight(18)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }

        CdSectionHeader({ title: '分享提取内容' })

        // 分享草稿列表
        CdShareDraftList({
          items: this.draftItems,
          onRemoveItem: (itemId: string) => {
            this.viewModel.removeDraftItem(itemId);
            this.syncState();
          }
        })

        // 上传任务进度列表
        CdShareTaskList({
          tasks: this.tasks,
          onGetItemName: (itemId) => {
            return this.viewModel.getItemName(itemId);
          },
          onRetry: (itemId: string) => {
            this.loading = true;
            this.viewModel.retryUpload(itemId).then(() => {
              this.syncState();
            });
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
