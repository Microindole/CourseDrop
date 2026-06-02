import router from '@ohos.router';
import { AppColors, AppRadius, AppSize, AppSpacing, AppTypography } from '../common/Theme';
import {
  CdBanner,
  CdButton,
  CdPanel,
  CdScrollContainer,
  CdSectionHeader,
  CdTextField,
  CdTopBar
} from '../components/index';
import { RelayShareItemResponse } from '../services/share';
import { cameraScanService, qrPayloadParser } from '../services/scan';
import { ShareDownloadViewModel } from '../viewmodels/ShareDownloadViewModel';

interface ShareDownloadParams {
  code?: string;
}

@Entry
@Component
struct ShareDownloadPage {
  private viewModel: ShareDownloadViewModel = new ShareDownloadViewModel();
  @State code: string = '';
  @State revision: number = 0;

  aboutToAppear() {
    const params = router.getParams() as ShareDownloadParams;
    if (params !== undefined && params.code !== undefined) {
      this.code = params.code;
      this.loadShare();
    }
  }

  private refreshView(): void {
    this.revision += 1;
  }

  private async loadShare(): Promise<void> {
    await this.viewModel.load(this.code);
    this.refreshView();
  }

  private async scanShare(): Promise<void> {
    const result = await cameraScanService.openCamera();
    if (!result.success || result.rawText.length === 0) {
      this.viewModel.lastActionText = result.message;
      this.viewModel.errorMessage = result.success ? '' : result.message;
      this.refreshView();
      return;
    }
    const payload = qrPayloadParser.parse(result.rawText);
    if (payload.type !== 'SHARE') {
      this.viewModel.lastActionText = '未识别到分享二维码';
      this.viewModel.errorMessage = '请扫描 CourseDrop 分享二维码，或手动输入提取码。';
      this.refreshView();
      return;
    }
    this.code = payload.rawText;
    await this.loadShare();
  }

  private formatSize(sizeBytes: number): string {
    if (sizeBytes < 1024) {
      return `${sizeBytes} B`;
    }
    if (sizeBytes < 1024 * 1024) {
      return `${Math.round(sizeBytes / 1024)} KB`;
    }
    return `${Math.round(sizeBytes / 1024 / 1024)} MB`;
  }

  @Builder
  ShareItemRow(item: RelayShareItemResponse) {
    CdPanel({ hasShadow: true }) {
      Row({ space: AppSpacing.MD }) {
        Stack() {
          Image($r('app.media.cd_icon_file'))
            .width(AppSize.ICON_MD)
            .height(AppSize.ICON_MD)
            .fillColor(AppColors.PRIMARY)
        }
        .width(44)
        .height(44)
        .backgroundColor(AppColors.PRIMARY_SOFT)
        .borderRadius(AppRadius.MD)
        .border({ width: 0.7, color: AppColors.PRIMARY })

        Column({ space: AppSpacing.XS }) {
          Text(item.displayName)
            .fontSize(AppTypography.BODY_SMALL)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`${this.formatSize(item.sizeBytes)} · ${item.encrypted ? '端到端密文' : '可直接下载'}`)
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        CdButton({
          label: this.viewModel.loading ? '下载中' : '下载',
          variant: 'tonal',
          interactive: !this.viewModel.loading,
          onTap: () => {
            this.viewModel.downloadItem(item).then(() => {
              this.refreshView();
            });
          }
        })
        .width(88)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      CdScrollContainer({ showScrollBar: true }) {
        if (this.revision < 0) {
          Blank()
        }

        CdTopBar({
          title: '接收分享',
          subtitle: '读取提取码并安全写入本地库',
          leadingText: '返回',
          onLeadingTap: () => {
            router.back();
          }
        })

        CdBanner({
          title: this.viewModel.lastActionText,
          description: this.viewModel.errorMessage.length > 0 ? this.viewModel.errorMessage : '下载完成后会写入应用 incoming 目录，并进入本地库索引；密文内容会在本机侧处理。',
          tone: this.viewModel.errorMessage.length > 0 ? 'danger' : 'info'
        })

        CdPanel({ hasShadow: true }) {
          Column({ space: AppSpacing.MD }) {
            CdTextField({
              label: '分享码',
              placeholder: '输入二维码或链接中的分享码',
              value: $code
            })

            CdButton({
              label: this.viewModel.loading ? '读取中' : '读取分享',
              interactive: !this.viewModel.loading,
              onTap: () => {
                this.loadShare();
              }
            })

            CdButton({
              label: '扫码识别分享',
              variant: 'tonal',
              interactive: !this.viewModel.loading,
              onTap: () => {
                this.scanShare();
              }
            })
          }
          .width('100%')
        }

        CdSectionHeader({ title: '分享文件' })

        if (this.viewModel.getItems().length === 0) {
          CdPanel({ hasShadow: false }) {
            Text('暂无分享文件')
              .fontSize(AppTypography.BODY_SMALL)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
        } else {
          ForEach(this.viewModel.getItems(), (item: RelayShareItemResponse) => {
            this.ShareItemRow(item);
          }, (item: RelayShareItemResponse) => item.id)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
