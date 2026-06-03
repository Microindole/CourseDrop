import router from '@ohos.router';
import {
  CdBanner,
  CdButton,
  CdPanel,
  CdScrollContainer,
  CdSectionHeader,
  CdTextField,
  CdTopBar,
  CdLanRadarScanner,
  CdLanDeviceList
} from '../components/index';
import { AppColors, AppRadius, AppSpacing, AppTypography } from '../common/Theme';
import { Device } from '../models/Device';
import { LanPairingSession, TrustedDevice } from '../services/device';
import { DeviceViewModel } from '../viewmodels/DeviceViewModel';

@Component
export default struct DevicePage {
  showBack: boolean = true;
  private viewModel: DeviceViewModel = new DeviceViewModel();

  @State devices: Device[] = [];
  @State scanning: boolean = false;
  @State lastActionText: string = '局域网发现优先';
  @State errorMessage: string = '';
  @State manualName: string = '我的电脑';
  @State manualAddress: string = '';
  @State pairingSessions: LanPairingSession[] = [];
  @State trustedDevices: TrustedDevice[] = [];

  aboutToAppear() {
    this.viewModel.startLanResponder().then(() => {
      this.syncDevices();
    });
    this.syncDevices();
  }

  aboutToDisappear() {
    this.viewModel.stopLanResponder();
  }

  private syncDevices() {
    this.devices = this.viewModel.devices;
    this.scanning = this.viewModel.scanning;
    this.lastActionText = this.viewModel.lastActionText.length > 0 ? this.viewModel.lastActionText : '局域网发现优先';
    this.errorMessage = this.viewModel.errorMessage;
    this.pairingSessions = this.viewModel.pairingSessions;
    this.trustedDevices = this.viewModel.trustedDevices;
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      CdScrollContainer({ showScrollBar: true, backgroundStyle: 'device' }) {
        CdTopBar({
          title: '局域网直传设备',
          subtitle: `已连接 ${this.devices.filter((device: Device) => device.status !== 'OFFLINE').length} 台设备`,
          leadingText: this.showBack ? '返回' : '',
          trailingText: '刷新',
          onLeadingTap: () => {
            router.back();
          },
          onTrailingTap: () => {
            this.scanDevices();
          }
        })

        CdBanner({
          title: this.lastActionText,
          description: this.errorMessage.length > 0 ? this.errorMessage : '模拟器环境下建议先手动输入电脑 IP 和端口，例如 http://192.168.1.10:9090。',
          tone: this.errorMessage.length > 0 ? 'danger' : 'info'
        })

        CdPanel({ hasShadow: true }) {
          Column({ space: AppSpacing.MD }) {
            CdTextField({
              label: '设备名称',
              placeholder: '例如：我的电脑',
              value: $manualName
            })

            CdTextField({
              label: '电脑/服务器地址',
              placeholder: '例如：http://192.168.1.10:9090',
              value: $manualAddress
            })

            Button(this.scanning ? '正在测试连接...' : '测试并保存设备')
              .enabled(!this.scanning)
              .fontSize(AppTypography.BODY_SMALL)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.SURFACE)
              .backgroundColor(this.scanning ? AppColors.SURFACE_MUTED : AppColors.PRIMARY)
              .borderRadius(AppRadius.XL)
              .height(42)
              .onClick(() => {
                this.addManualDevice();
              })
            .width('100%')

            Button('添加调试设备')
              .fontSize(AppTypography.BODY_SMALL)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY_SELECTED)
              .backgroundColor(AppColors.ACCENT_SOFT)
              .borderRadius(AppRadius.XL)
              .height(42)
              .onClick(() => {
                this.addDebugLanDevice();
              })
            .width('100%')
          }
          .width('100%')
        }

        // 雷达扫描控制面板
        CdLanRadarScanner({
          scanning: this.scanning,
          lanDeviceCount: this.viewModel.getLanDevices().length,
          onStartScan: () => {
            this.scanDevices();
          }
        })

        if (this.getVerifyingSessions().length > 0) {
          CdSectionHeader({ title: '配对确认' })
          ForEach(this.getVerifyingSessions(), (session: LanPairingSession) => {
            this.pairingSessionCard(session)
          }, (session: LanPairingSession) => session.id)
        }

        if (this.trustedDevices.length > 0) {
          CdSectionHeader({ title: '可信设备' })
          ForEach(this.trustedDevices, (device: TrustedDevice) => {
            this.trustedDeviceCard(device)
          }, (device: TrustedDevice) => device.id)
        }

        CdSectionHeader({ title: '已扫描到的局域网节点' })

        // 连接设备列表
        CdLanDeviceList({
          devices: this.devices,
          onDeviceTap: (device) => {
            this.startPairing(device);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  private async scanDevices(): Promise<void> {
    this.viewModel.scanning = true;
    this.syncDevices();
    await this.viewModel.refreshDevices();
    this.syncDevices();
  }

  private async addManualDevice(): Promise<void> {
    this.viewModel.beginManualProbe();
    this.syncDevices();
    await this.viewModel.addManualDevice(this.manualName, this.manualAddress);
    this.syncDevices();
  }

  private addDebugLanDevice(): void {
    this.lastActionText = '正在添加调试设备...';
    this.errorMessage = '';
    this.viewModel.addDebugLanDevice();
    this.syncDevices();
  }

  private async probeDevice(device: Device): Promise<void> {
    await this.viewModel.probeDevice(device);
    this.syncDevices();
  }

  private startPairing(device: Device): void {
    this.viewModel.startPairing(device);
    this.syncDevices();
  }

  private confirmPairing(session: LanPairingSession): void {
    this.viewModel.confirmPairing(session.id);
    this.syncDevices();
  }

  private rejectPairing(session: LanPairingSession): void {
    this.viewModel.rejectPairing(session.id);
    this.syncDevices();
  }

  private getVerifyingSessions(): LanPairingSession[] {
    return this.pairingSessions.filter((session: LanPairingSession) => session.status === 'VERIFYING');
  }

  @Builder
  private pairingSessionCard(session: LanPairingSession) {
    CdPanel({ hasShadow: true }) {
      Column({ space: AppSpacing.MD }) {
        Row() {
          Column({ space: AppSpacing.XS }) {
            Text(session.remoteName)
              .fontSize(AppTypography.BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)

            Text(session.remoteAddress)
              .fontSize(AppTypography.CAPTION)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('待核对')
            .fontSize(AppTypography.CAPTION)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WARNING)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(AppColors.WARNING_SOFT)
            .borderRadius(AppRadius.SM)
        }
        .width('100%')

        Column({ space: AppSpacing.XS }) {
          Text('安全验证码')
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)

          Text(session.verificationCode)
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.PRIMARY_SELECTED)
            .letterSpacing(4)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
        .backgroundColor(AppColors.PRIMARY_SOFT)
        .borderRadius(AppRadius.MD)

        Row({ space: AppSpacing.MD }) {
          CdButton({
            label: '拒绝',
            onTap: () => {
              this.rejectPairing(session);
            }
          })
          .layoutWeight(1)

          CdButton({
            label: '确认配对',
            onTap: () => {
              this.confirmPairing(session);
            }
          })
          .layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%')
    }
  }

  @Builder
  private trustedDeviceCard(device: TrustedDevice) {
    CdPanel() {
      Row({ space: AppSpacing.MD }) {
        Stack() {
          Image($r('app.media.cd_icon_lock'))
            .width(22)
            .height(22)
            .fillColor(AppColors.SUCCESS)
        }
        .width(40)
        .height(40)
        .backgroundColor(AppColors.SUCCESS_SOFT)
        .borderRadius(AppRadius.MD)

        Column({ space: AppSpacing.XS }) {
          Text(device.name)
            .fontSize(AppTypography.BODY_SMALL)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`指纹 ${device.publicKeyFingerprint} · ${device.lastAddress}`)
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('可信')
          .fontSize(AppTypography.CAPTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.SUCCESS)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(AppColors.SUCCESS_SOFT)
          .borderRadius(AppRadius.SM)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
  }
}
