import router from '@ohos.router';
import {
  CdBanner,
  CdButton,
  CdInfoRow,
  CdPanel,
  CdScrollContainer,
  CdSectionHeader,
  CdTextField,
  CdTopBar
} from '../components/index';
import { AppColors, AppSpacing, AppTypography } from '../common/Theme';
import { GroupMessage, GroupSession } from '../models/Group';
import { GroupTestViewModel } from '../viewmodels/GroupTestViewModel';

@Entry
@Component
struct GroupTestPage {
  private viewModel: GroupTestViewModel = new GroupTestViewModel();

  @State serverUrl: string = this.viewModel.serverUrl;
  @State groupName: string = this.viewModel.groupName;
  @State messageText: string = this.viewModel.messageText;
  @State actionText: string = this.viewModel.lastActionText;
  @State errorMessage: string = '';
  @State groupId: string = '';
  @State fingerprintId: string = '';
  @State busy: boolean = false;
  @State messages: GroupMessage[] = [];
  @State messageLines: string[] = [];

  private syncState(): void {
    const group: GroupSession | undefined = this.viewModel.currentGroup;
    this.actionText = this.viewModel.lastActionText;
    this.errorMessage = this.viewModel.errorMessage;
    this.groupId = group === undefined ? '' : group.id;
    this.fingerprintId = this.viewModel.currentIdentity === undefined ? '' : this.viewModel.currentIdentity.fingerprintId;
    this.messages = this.viewModel.messages;
  }

  private runTask(task: () => Promise<void>): void {
    this.busy = true;
    this.errorMessage = '';
    task()
      .then(() => {
        this.syncState();
        return this.viewModel.describeMessages();
      })
      .then((lines: string[]) => {
        this.messageLines = lines;
      })
      .catch((error: Error) => {
        this.errorMessage = String(error);
        this.actionText = '操作失败';
      })
      .finally(() => {
        this.busy = false;
      });
  }

  build() {
    CdScrollContainer({ showScrollBar: true, backgroundStyle: 'settings' }) {
      CdTopBar({
        title: '群组文件流测试',
        subtitle: '独立验证群组 API 与密文消息',
        leadingText: '返回',
        trailingText: this.busy ? '运行中' : '',
        onLeadingTap: () => {
          router.back();
        }
      })

      CdBanner({
        title: this.actionText,
        description: this.errorMessage.length > 0 ? this.errorMessage : '该页面未接入首页主流程，仅用于手动联调 Java server 的群组基础能力。',
        tone: this.errorMessage.length > 0 ? 'danger' : 'info'
      })

      CdPanel() {
        Column({ space: AppSpacing.MD }) {
          CdTextField({
            label: '中转源',
            placeholder: 'http://127.0.0.1:8080',
            value: $serverUrl
          })

          CdTextField({
            label: '测试群名',
            placeholder: 'CourseDrop 测试群',
            value: $groupName
          })

          CdTextField({
            label: '测试消息',
            placeholder: '输入一条测试消息',
            value: $messageText
          })
        }
        .width('100%')
      }

      CdSectionHeader({ title: '操作' })

      CdPanel() {
        Column({ space: AppSpacing.SM }) {
          Row({ space: AppSpacing.SM }) {
            CdButton({
              label: '注册身份',
              variant: 'tonal',
              interactive: !this.busy,
              onTap: () => {
                this.runTask(async () => {
                  this.viewModel.setServerUrl(this.serverUrl);
                  await this.viewModel.registerIdentity();
                });
              }
            })
            .layoutWeight(1)

            CdButton({
              label: '创建群',
              variant: 'contained',
              interactive: !this.busy,
              onTap: () => {
                this.runTask(async () => {
                  this.viewModel.setServerUrl(this.serverUrl);
                  this.viewModel.groupName = this.groupName;
                  await this.viewModel.createGroup();
                });
              }
            })
            .layoutWeight(1)
          }

          Row({ space: AppSpacing.SM }) {
            CdButton({
              label: '发送消息',
              variant: 'tonal',
              interactive: !this.busy,
              onTap: () => {
                this.runTask(async () => {
                  this.viewModel.messageText = this.messageText;
                  await this.viewModel.sendTextMessage();
                });
              }
            })
            .layoutWeight(1)

            CdButton({
              label: '同步消息',
              variant: 'tonal',
              interactive: !this.busy,
              onTap: () => {
                this.runTask(async () => {
                  await this.viewModel.syncMessages();
                });
              }
            })
            .layoutWeight(1)
          }
        }
        .width('100%')
      }

      CdSectionHeader({ title: '当前状态' })

      CdPanel() {
        Column({ space: AppSpacing.SM }) {
          CdInfoRow({ title: 'fingerprintId', value: this.fingerprintId.length === 0 ? '未注册' : this.fingerprintId })
          CdInfoRow({ title: 'groupId', value: this.groupId.length === 0 ? '未创建' : this.groupId })
          CdInfoRow({ title: '本地消息数', value: `${this.messages.length}` })
        }
        .width('100%')
      }

      CdSectionHeader({ title: '消息预览' })

      CdPanel() {
        Column({ space: AppSpacing.SM }) {
          if (this.messageLines.length === 0) {
            Text('暂无消息')
              .fontSize(AppTypography.BODY_SMALL)
              .fontColor(AppColors.TEXT_SECONDARY)
          } else {
            ForEach(this.messageLines, (line: string) => {
              Text(line)
                .fontSize(AppTypography.BODY_SMALL)
                .fontColor(AppColors.TEXT)
                .width('100%')
            }, (line: string) => line)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }
  }
}
