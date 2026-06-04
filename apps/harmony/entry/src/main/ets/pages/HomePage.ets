import router from '@ohos.router';
import DevicePage from './DevicePage';
import LocalLibraryPage from './LocalLibraryPage';
import SettingsPage from './SettingsPage';
import SharePage from './SharePage';
import { AppColors, AppRadius, AppSize, AppSpacing, AppTypography } from '../common/Theme';
import {
  CdBanner,
  CdBottomTabs,
  CdPageTitle,
  CdPanel,
  CdScrollContainer,
  CdSectionHeader,
  CdTransferStats,
  CdHomeGuideStep,
  CdHomeRecentShares,
  CdShareExtractDrawer
} from '../components/index';
import { ShareSession } from '../models/ShareSession';
import { clipboardService } from '../services/clipboard';
import { shareQrImageService } from '../services/share';
import { HomeViewModel, HomeTransferStats } from '../viewmodels/HomeViewModel';

@Entry
@Component
struct HomePage {
  private viewModel: HomeViewModel = new HomeViewModel();
  @State currentIndex: number = 0;
  
  @State recentShares: ShareSession[] = [];
  @State transferStats: HomeTransferStats = { activeCount: 0, completedCount: 0, failedCount: 0, expiringCount: 0 };
  @State selectedRecentShare: ShareSession | null = null;
  @State recentShareQrImageUrl: string = '';
  @State recentShareQrErrorText: string = '';

  aboutToAppear() {
    this.syncHomeData();
  }

  private syncHomeData() {
    this.viewModel = new HomeViewModel();
    this.recentShares = this.viewModel.recentShares;
    this.transferStats = this.viewModel.getTransferStats();
  }

  private openRecentShare(share: ShareSession): void {
    this.selectedRecentShare = this.copyShare(share);
    this.recentShareQrImageUrl = '';
    this.recentShareQrErrorText = '';
    shareQrImageService.loadQrImage(share.shareUrl)
      .then((localUri: string) => {
        this.recentShareQrImageUrl = localUri;
      })
      .catch((error: Error) => {
        this.recentShareQrErrorText = `二维码加载失败：${String(error)}`;
      });
  }

  private copyShare(share: ShareSession): ShareSession {
    return {
      id: share.id,
      title: share.title,
      code: share.code,
      shareUrl: share.shareUrl,
      status: share.status,
      networkMode: share.networkMode,
      expireStatus: share.expireStatus,
      createdAt: share.createdAt,
      expiresAt: share.expiresAt,
      itemCount: share.itemCount,
      totalSizeBytes: share.totalSizeBytes,
      encrypted: share.encrypted,
      downloadPolicy: share.downloadPolicy,
      items: share.items.slice()
    };
  }

  private copyText(text: string): void {
    clipboardService.copyText(text)
      .catch((error: Error) => {
        console.error(`[CourseDrop] copy recent share failed: ${String(error)}`);
      });
  }

  @Builder
  HomeTab() {
    CdScrollContainer({ showScrollBar: true, backgroundStyle: 'home' }) {
      CdPageTitle({
        title: this.viewModel.appName,
        subtitle: this.viewModel.subtitle
      })

      CdTransferStats({
        statsActiveCount: this.transferStats.activeCount,
        statsCompletedCount: this.transferStats.completedCount,
        statsFailedCount: this.transferStats.failedCount,
        statsExpiringCount: this.transferStats.expiringCount
      })

      CdPanel({
        clickable: true,
        onTap: () => {
          router.pushUrl({ url: 'pages/AiChatPage' });
        }
      }) {
        Row({ space: AppSpacing.MD }) {
          Stack() {
            Image($r('app.media.cd_icon_text'))
              .width(AppSize.ICON_MD)
              .height(AppSize.ICON_MD)
              .fillColor(AppColors.PRIMARY)
          }
          .width(48)
          .height(48)
          .backgroundColor(AppColors.PRIMARY_SOFT)
          .borderRadius(AppRadius.LG)
          .border({ width: 0.7, color: AppColors.PRIMARY })

          Column({ space: AppSpacing.XS }) {
            Text('课递助手')
              .fontSize(AppTypography.BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)

            Text('打开文本问答，先不读取本地文件')
              .fontSize(AppTypography.CAPTION)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Image($r('app.media.cd_icon_done'))
            .width(14)
            .height(14)
            .fillColor(AppColors.MUTED)
            .rotate({ angle: 270 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      CdPanel({
        clickable: true,
        onTap: () => {
          router.pushUrl({ url: 'pages/ShareDownloadPage' });
        }
      }) {
        Row({ space: AppSpacing.MD }) {
          Stack() {
            Image($r('app.media.cd_icon_search'))
              .width(AppSize.ICON_MD)
              .height(AppSize.ICON_MD)
              .fillColor(AppColors.SUCCESS)
          }
          .width(48)
          .height(48)
          .backgroundColor(AppColors.SUCCESS_SOFT)
          .borderRadius(AppRadius.LG)
          .border({ width: 0.7, color: AppColors.SUCCESS })

          Column({ space: AppSpacing.XS }) {
            Text('接收分享')
              .fontSize(AppTypography.BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)

            Text('扫码或输入提取码，下载到本地库')
              .fontSize(AppTypography.CAPTION)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Image($r('app.media.cd_icon_done'))
            .width(14)
            .height(14)
            .fillColor(AppColors.MUTED)
            .rotate({ angle: 270 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      CdPanel({
        clickable: true,
        onTap: () => {
          router.pushUrl({ url: 'pages/GroupTestPage' });
        }
      }) {
        Row({ space: AppSpacing.MD }) {
          Stack() {
            Image($r('app.media.cd_icon_share'))
              .width(AppSize.ICON_MD)
              .height(AppSize.ICON_MD)
              .fillColor(AppColors.ACCENT)
          }
          .width(48)
          .height(48)
          .backgroundColor(AppColors.ACCENT_SOFT)
          .borderRadius(AppRadius.LG)
          .border({ width: 0.7, color: AppColors.ACCENT })

          Column({ space: AppSpacing.XS }) {
            Text('群组')
              .fontSize(AppTypography.BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)

            Text('像聊天一样和好友共享加密文件流')
              .fontSize(AppTypography.CAPTION)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Image($r('app.media.cd_icon_done'))
            .width(14)
            .height(14)
            .fillColor(AppColors.MUTED)
            .rotate({ angle: 270 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      CdBanner({
        title: '安全中转与局域网直传双引擎',
        description: '本地优先整理内容，公网只托管临时密文，局域网下优先走直连通道。',
        tone: 'info',
        actionText: '同步状态',
        onAction: () => {
          this.syncHomeData();
        }
      })

      // 上手指南步骤卡片
      CdHomeGuideStep({
        onGoLibrary: () => {
          this.currentIndex = 2; // 本地库 Tab
        },
        onGoShare: () => {
          this.currentIndex = 1; // 分享 Tab
        }
      })

      CdSectionHeader({ title: '最近的提取链接' })

      // 最近分享提取列表
      CdHomeRecentShares({
        recentShares: this.recentShares,
        onRecentTap: (share: ShareSession) => {
          this.openRecentShare(share);
        }
      })
    }
  }

  @Builder
  ShareTab() {
    SharePage({ showBack: false })
  }

  @Builder
  LibraryTab() {
    LocalLibraryPage({
      showBack: false,
      onSharePrepared: () => {
        this.currentIndex = 1;
      }
    })
  }

  @Builder
  DeviceTab() {
    DevicePage({ showBack: false })
  }

  @Builder
  SettingsTab() {
    SettingsPage({ showBack: false })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      CdBottomTabs({
        currentIndex: $currentIndex,
        onTabChange: (index: number) => {
          if (index === 0) {
            this.syncHomeData();
          }
        },
        homeContent: () => {
          this.HomeTab();
        },
        shareContent: () => {
          this.ShareTab();
        },
        libraryContent: () => {
          this.LibraryTab();
        },
        deviceContent: () => {
          this.DeviceTab();
        },
        settingsContent: () => {
          this.SettingsTab();
        }
      })

      if (this.selectedRecentShare !== null) {
        CdShareExtractDrawer({
          selectedShare: $selectedRecentShare,
          qrImageUrl: this.recentShareQrImageUrl,
          qrErrorText: this.recentShareQrErrorText,
          onCopyCode: (code: string) => {
            this.copyText(code);
          },
          onCopyLink: (link: string) => {
            this.copyText(link);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
