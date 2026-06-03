import { AppColors, AppRadius, AppSize, AppSpacing, AppTypography } from '../../common/Theme';
import { Device } from '../../models/Device';
import { CdPanel } from '../common/CdPanel';

@Component
export struct CdLanDeviceList {
  devices: Device[] = [];
  onDeviceTap: (device: Device) => void = (_device: Device) => {};

  private statusText(device: Device): string {
    if (device.status === 'ONLINE') return '在线';
    if (device.status === 'IDLE') return '空闲';
    return '离线';
  }

  private platformText(device: Device): string {
    if (device.platform === 'HARMONY') return 'HarmonyOS';
    if (device.platform === 'ANDROID') return 'Android';
    if (device.platform === 'WINDOWS') return 'Windows';
    if (device.platform === 'MACOS') return 'macOS';
    if (device.platform === 'LINUX') return 'Linux';
    if (device.platform === 'WEB') return 'Web 端';
    return '未知设备';
  }

  private platformIcon(device: Device): Resource {
    if (device.platform === 'WINDOWS') return $r('app.media.cd_icon_lan');
    return $r('app.media.cd_icon_devices');
  }

  build() {
    if (this.devices.length === 0) {
      CdPanel() {
        Column({ space: AppSpacing.MD }) {
          Image($r('app.media.cd_icon_devices'))
            .width(44)
            .height(44)
            .fillColor(AppColors.MUTED)

          Text('暂无可连接的局域网设备')
            .fontSize(AppTypography.BODY)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)

          Text('点击上方按钮发起局域网多播嗅探，发现设备后需要先核对验证码并完成配对。')
            .fontSize(AppTypography.BODY_SMALL)
            .fontColor(AppColors.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
            .lineHeight(18)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: AppSpacing.LG, bottom: AppSpacing.LG })
      }
    } else {
      ForEach(this.devices, (device: Device) => {
        CdPanel({
          clickable: device.status !== 'OFFLINE',
          onTap: () => {
            this.onDeviceTap(device);
          }
        }) {
          Row({ space: AppSpacing.MD }) {
            Stack() {
              Image(this.platformIcon(device))
                .width(AppSize.ICON_MD)
                .height(AppSize.ICON_MD)
                .fillColor(device.status !== 'OFFLINE' ? AppColors.PRIMARY : AppColors.MUTED)
            }
            .width(44)
            .height(44)
            .backgroundColor(device.status !== 'OFFLINE' ? AppColors.PRIMARY_SOFT : AppColors.BACKGROUND)
            .borderRadius(AppRadius.MD)
            .border({ width: 0.7, color: device.status !== 'OFFLINE' ? AppColors.PRIMARY : AppColors.BORDER })

            Column({ space: AppSpacing.XS }) {
              Row({ space: AppSpacing.SM }) {
                Text(device.name)
                  .fontSize(AppTypography.BODY_SMALL)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(device.status !== 'OFFLINE' ? AppColors.TEXT : AppColors.MUTED)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)

                Text(this.statusText(device))
                  .fontSize(9)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(device.status !== 'OFFLINE' ? AppColors.SUCCESS : AppColors.MUTED)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor(device.status !== 'OFFLINE' ? AppColors.SUCCESS_SOFT : AppColors.SURFACE_MUTED)
                  .borderRadius(AppRadius.SM)
              }
              .width('100%')

              Row({ space: AppSpacing.SM }) {
                Text(this.platformText(device))
                  .fontSize(AppTypography.CAPTION)
                  .fontColor(AppColors.TEXT_SECONDARY)
                
                Text(`·`)
                  .fontSize(AppTypography.CAPTION)
                  .fontColor(AppColors.TEXT_SECONDARY)

                Text(device.networkMode === 'LAN' ? '局域网直连' : '公网中转')
                  .fontSize(AppTypography.CAPTION)
                  .fontColor(AppColors.TEXT_SECONDARY)
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            // 右侧状态
            Row({ space: AppSpacing.SM }) {
              if (device.status !== 'OFFLINE') {
                if (device.latencyMs) {
                  Text(`${device.latencyMs}ms`)
                    .fontSize(AppTypography.CAPTION)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppColors.SUCCESS)
                }
                
                Circle()
                  .width(8)
                  .height(8)
                  .fill(AppColors.SUCCESS)
              } else {
                Text('离线')
                  .fontSize(AppTypography.CAPTION)
                  .fontColor(AppColors.MUTED)
              }
            }
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
      }, (device: Device) => device.id)
    }
  }
}
