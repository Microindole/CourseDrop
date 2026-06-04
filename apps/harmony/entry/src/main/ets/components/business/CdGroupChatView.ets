import { AppColors, AppRadius, AppSpacing, AppTypography } from '../../common/Theme';
import { GroupMember } from '../../models/Group';
import { GroupMessagePreview } from '../../viewmodels/GroupTestViewModel';
import { CdBanner } from '../common/CdBanner';
import { CdButton } from '../common/CdButton';
import { CdIconButton } from '../common/CdIconButton';
import { CdPanel } from '../common/CdPanel';
import { CdTextField } from '../common/CdTextField';

@Component
export struct CdGroupChatView {
  groupTitle: string = '';
  avatarText: string = '群';
  avatarColor: string = '#1466FF';
  messageCount: number = 0;
  members: GroupMember[] = [];
  previews: GroupMessagePreview[] = [];
  busy: boolean = false;
  inviteText: string = '';
  showNotice: boolean = false;
  errorMessage: string = '';
  @Link messageText: string;
  @Link avatarEditText: string;
  @Link avatarEditColor: string;
  @Link recoveryPassphrase: string;
  @Link showInvitePanel: boolean;
  @Link showDetailPanel: boolean;
  onBack: () => void = () => {};
  onSync: () => void = () => {};
  onInvite: () => void = () => {};
  onCopyInvite: () => void = () => {};
  onSaveProfile: () => void = () => {};
  onBackupKey: () => void = () => {};
  onRestoreBackup: () => void = () => {};
  onLeaveGroup: () => void = () => {};
  onSendFile: () => void = () => {};
  onSendText: () => void = () => {};
  onDownloadFile: (messageId: string) => void = (_messageId: string) => {};

  @Builder
  header() {
    Row({ space: AppSpacing.SM }) {
      CdIconButton({
        icon: $r('app.media.cd_icon_prev'),
        variant: 'plain',
        onTap: () => {
          this.onBack();
        }
      })

      Stack() {
        Text(this.avatarText.length === 0 ? '群' : this.avatarText)
          .fontSize(AppTypography.BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.SURFACE)
      }
      .width(42)
      .height(42)
      .backgroundColor(this.avatarColor.length === 0 ? AppColors.PRIMARY : this.avatarColor)
      .borderRadius(21)

      Column({ space: 2 }) {
        Text(this.groupTitle.length === 0 ? '群组' : this.groupTitle)
          .fontSize(AppTypography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.messageCount} 条消息`)
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      CdIconButton({
        icon: $r('app.media.cd_icon_settings'),
        variant: 'plain',
        onTap: () => {
          this.showDetailPanel = !this.showDetailPanel;
        }
      })

      CdIconButton({
        icon: $r('app.media.cd_icon_refresh'),
        variant: 'tonal',
        onTap: () => {
          this.onSync();
        }
      })
    }
    .width('100%')
    .height(56)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  detailPanel() {
    if (this.showDetailPanel) {
      CdPanel() {
        Column({ space: AppSpacing.MD }) {
          Row() {
            Text('群资料')
              .fontSize(AppTypography.BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)
              .layoutWeight(1)

            CdIconButton({
              icon: $r('app.media.cd_icon_close'),
              variant: 'plain',
              onTap: () => {
                this.showDetailPanel = false;
              }
            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row({ space: AppSpacing.MD }) {
            Stack() {
              Text(this.avatarEditText.length === 0 ? this.avatarText : this.avatarEditText.substring(0, 2))
                .fontSize(AppTypography.BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.SURFACE)
            }
            .width(52)
            .height(52)
            .backgroundColor(this.avatarEditColor.length === 0 ? this.avatarColor : this.avatarEditColor)
            .borderRadius(26)

            Column({ space: AppSpacing.SM }) {
              CdTextField({
                label: '头像字',
                placeholder: '1-2 个字',
                value: $avatarEditText
              })

              Row({ space: AppSpacing.SM }) {
                this.colorSwatch('#1466FF')
                this.colorSwatch('#00B8D9')
                this.colorSwatch('#10B981')
                this.colorSwatch('#F59E0B')
                this.colorSwatch('#F04438')
              }
              .width('100%')
            }
            .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          CdButton({
            label: '保存资料',
            variant: 'tonal',
            interactive: !this.busy,
            onTap: () => {
              this.onSaveProfile();
            }
          })

          Row({ space: AppSpacing.SM }) {
            Text('成员')
              .fontSize(AppTypography.BODY_SMALL)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)
              .layoutWeight(1)

            Text(`${this.activeMemberCount()}`)
              .fontSize(AppTypography.CAPTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY_SELECTED)
          }
          .width('100%')

          Column({ space: AppSpacing.SM }) {
            if (this.members.length === 0) {
              Text('暂无成员信息')
                .fontSize(AppTypography.CAPTION)
                .fontColor(AppColors.TEXT_SECONDARY)
            } else {
              ForEach(this.members, (member: GroupMember) => {
                this.memberRow(member)
              }, (member: GroupMember) => `${member.groupId}:${member.fingerprintId}`)
            }
          }
          .width('100%')

          CdTextField({
            label: '恢复口令',
            placeholder: '用于备份或恢复群组密钥',
            obscure: true,
            value: $recoveryPassphrase
          })

          Row({ space: AppSpacing.SM }) {
            CdButton({
              label: '备份',
              variant: 'contained',
              interactive: !this.busy,
              onTap: () => {
                this.onBackupKey();
              }
            })
            .layoutWeight(1)

            CdButton({
              label: '恢复',
              variant: 'tonal',
              interactive: !this.busy,
              onTap: () => {
                this.onRestoreBackup();
              }
            })
            .layoutWeight(1)
          }
          .width('100%')

          Row({ space: AppSpacing.SM }) {
            CdIconButton({
              icon: $r('app.media.cd_icon_new_chat'),
              variant: 'tonal',
              onTap: () => {
                this.onInvite();
              }
            })

            CdButton({
              label: '退出群组',
              variant: 'danger',
              interactive: !this.busy,
              onTap: () => {
                this.onLeaveGroup();
              }
            })
            .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }
    }
  }

  @Builder
  colorSwatch(color: string) {
    Stack() {
      if (this.avatarEditColor === color) {
        Image($r('app.media.cd_icon_done'))
          .width(16)
          .height(16)
          .fillColor(AppColors.SURFACE)
      }
    }
    .width(30)
    .height(30)
    .backgroundColor(color)
    .borderRadius(15)
    .onClick(() => {
      this.avatarEditColor = color;
    })
  }

  @Builder
  memberRow(member: GroupMember) {
    Row({ space: AppSpacing.SM }) {
      Stack() {
        Text(member.role === 'OWNER' ? 'O' : 'M')
          .fontSize(AppTypography.CAPTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY_SELECTED)
      }
      .width(28)
      .height(28)
      .backgroundColor(AppColors.PRIMARY_SOFT)
      .borderRadius(14)

      Text(member.fingerprintId)
        .fontSize(AppTypography.CAPTION)
        .fontColor(AppColors.TEXT_SECONDARY)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      Text(member.status === 'ACTIVE' ? '在线身份' : '已退出')
        .fontSize(AppTypography.CAPTION)
        .fontColor(member.status === 'ACTIVE' ? AppColors.SUCCESS : AppColors.MUTED)
    }
    .width('100%')
    .height(34)
    .alignItems(VerticalAlign.Center)
  }

  private activeMemberCount(): number {
    return this.members.filter((member: GroupMember) => member.status === 'ACTIVE').length;
  }

  @Builder
  invitePanel() {
    if (this.showInvitePanel) {
      CdPanel() {
        Column({ space: AppSpacing.MD }) {
          Row() {
            Text('邀请成员')
              .fontSize(AppTypography.BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)
              .layoutWeight(1)

            CdIconButton({
              icon: $r('app.media.cd_icon_close'),
              variant: 'plain',
              onTap: () => {
                this.showInvitePanel = false;
              }
            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(this.inviteText.length === 0 ? '邀请已复制到剪贴板' : this.inviteText)
            .fontSize(AppTypography.CAPTION)
            .fontColor(AppColors.TEXT_SECONDARY)
            .lineHeight(18)
            .maxLines(4)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: AppSpacing.SM }) {
            CdIconButton({
              icon: $r('app.media.cd_icon_copy'),
              variant: 'contained',
              onTap: () => {
                this.onCopyInvite();
              }
            })

            Text('复制后发给好友，对方粘贴即可加入。')
              .fontSize(AppTypography.CAPTION)
              .fontColor(AppColors.TEXT_SECONDARY)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }
    }
  }

  @Builder
  messageBubble(preview: GroupMessagePreview) {
    Row() {
      if (preview.type === 'FILE') {
        Row({ space: AppSpacing.SM }) {
          Stack() {
            Image($r('app.media.cd_icon_file'))
              .width(22)
              .height(22)
              .fillColor(AppColors.PRIMARY)
          }
          .width(40)
          .height(40)
          .backgroundColor(AppColors.PRIMARY_SOFT)
          .borderRadius(20)

          Column({ space: 3 }) {
            Text(preview.text)
              .fontSize(AppTypography.BODY_SMALL)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text('加密文件')
              .fontSize(AppTypography.CAPTION)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          CdIconButton({
            icon: $r('app.media.cd_icon_next'),
            variant: 'tonal',
            onTap: () => {
              this.onDownloadFile(preview.messageId);
            }
          })
        }
        .width('100%')
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.MD })
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(AppRadius.MD)
      } else {
        Text(preview.text)
          .fontSize(AppTypography.BODY_SMALL)
          .fontColor(AppColors.TEXT)
          .lineHeight(21)
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
          .backgroundColor(AppColors.SURFACE)
          .borderRadius(AppRadius.LG)
          .constraintSize({ maxWidth: '82%' })
      }
    }
    .width('100%')
    .justifyContent(preview.type === 'FILE' ? FlexAlign.Center : FlexAlign.End)
  }

  @Builder
  emptyMessages() {
    Column({ space: AppSpacing.SM }) {
      Text('还没有消息')
        .fontSize(AppTypography.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT)

      Text('发一条消息，或者直接投递文件给群成员。')
        .fontSize(AppTypography.BODY_SMALL)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  messageStream() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        if (this.previews.length === 0) {
          this.emptyMessages()
        } else {
          ForEach(this.previews, (preview: GroupMessagePreview) => {
            this.messageBubble(preview)
          }, (preview: GroupMessagePreview) => preview.messageId)
        }
      }
      .width('100%')
      .padding({ top: AppSpacing.MD, bottom: AppSpacing.MD })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  composer() {
    Row({ space: AppSpacing.SM }) {
      CdIconButton({
        icon: $r('app.media.cd_icon_file'),
        variant: 'plain',
        onTap: () => {
          if (!this.busy) {
            this.onSendFile();
          }
        }
      })

      TextInput({ placeholder: '消息', text: this.messageText })
        .layoutWeight(1)
        .height(42)
        .fontSize(AppTypography.BODY_SMALL)
        .fontColor(AppColors.TEXT)
        .placeholderColor(AppColors.MUTED)
        .backgroundColor(AppColors.SURFACE_RAISED)
        .borderRadius(21)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .onChange((value: string) => {
          this.messageText = value;
        })

      CdIconButton({
        icon: $r('app.media.cd_icon_send'),
        variant: 'contained',
        onTap: () => {
          if (!this.busy) {
            this.onSendText();
          }
        }
      })
    }
    .width('100%')
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.XL)
    .shadow({ radius: 16, color: '#1A132235', offsetX: 0, offsetY: 6 })
  }

  build() {
    Stack() {
      Row()
        .width('100%')
        .height('100%')
        .backgroundColor('#EAF1FA')

      Column({ space: AppSpacing.MD }) {
        this.header()

        if (this.showNotice && this.errorMessage.length > 0) {
          CdBanner({
            title: '操作没有完成',
            description: this.errorMessage,
            tone: 'danger'
          })
        }

        Column({ space: AppSpacing.MD }) {
          this.detailPanel()
          this.invitePanel()
          this.messageStream()
          this.composer()
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.MD })
        .backgroundColor('#F8FBFF')
        .borderRadius(AppRadius.XL)
      }
      .width('100%')
      .height('100%')
      .padding({
        top: AppSpacing.PAGE_TOP,
        left: AppSpacing.PAGE_HORIZONTAL,
        right: AppSpacing.PAGE_HORIZONTAL,
        bottom: AppSpacing.MD
      })
    }
    .width('100%')
    .height('100%')
  }
}
