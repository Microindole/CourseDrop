import { AppColors, AppRadius, AppSize, AppSpacing, AppTypography } from '../../common/Theme';
import { GroupSession } from '../../models/Group';
import { CdBanner } from '../common/CdBanner';
import { CdButton } from '../common/CdButton';
import { CdIconButton } from '../common/CdIconButton';
import { CdPanel } from '../common/CdPanel';
import { CdTextField } from '../common/CdTextField';

@Component
export struct CdGroupListView {
  groups: GroupSession[] = [];
  selectedGroupId: string = '';
  busy: boolean = false;
  showNotice: boolean = false;
  errorMessage: string = '';
  @Link groupName: string;
  @Link inviteText: string;
  @Link recoveryPassphrase: string;
  @Link showCreatePanel: boolean;
  @Link showJoinPanel: boolean;
  @Link showRestorePanel: boolean;
  onBack: () => void = () => {};
  onSelectGroup: (groupId: string) => void = (_groupId: string) => {};
  onCreateGroup: () => void = () => {};
  onJoinGroup: () => void = () => {};
  onRestoreBackup: () => void = () => {};

  private groupInitial(group: GroupSession): string {
    if (group.config.avatarText !== undefined && group.config.avatarText.length > 0) {
      return group.config.avatarText;
    }
    if (group.plainName.length === 0) {
      return '群';
    }
    return group.plainName.substring(0, 1);
  }

  private groupColor(group: GroupSession): string {
    if (group.config.avatarColor !== undefined && group.config.avatarColor.length > 0) {
      return group.config.avatarColor;
    }
    return AppColors.PRIMARY;
  }

  @Builder
  groupAvatar(label: string, selected: boolean, color: string) {
    Stack() {
      Text(label)
        .fontSize(AppTypography.BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(selected ? AppColors.SURFACE : AppColors.PRIMARY_SELECTED)
    }
    .width(52)
    .height(52)
    .backgroundColor(selected ? color : AppColors.PRIMARY_SOFT)
    .borderRadius(26)
  }

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

      Column({ space: 2 }) {
        Text('群组')
          .fontSize(AppTypography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)

        Text('加密文件流')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Blank()
        .width(AppSize.BUTTON_HEIGHT)
    }
    .width('100%')
    .height(56)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  emptyState() {
    Column({ space: AppSpacing.LG }) {
      Stack() {
        Image($r('app.media.cd_icon_share'))
          .width(AppSize.ICON_LG)
          .height(AppSize.ICON_LG)
          .fillColor(AppColors.PRIMARY)
      }
      .width(76)
      .height(76)
      .backgroundColor(AppColors.PRIMARY_SOFT)
      .borderRadius(38)

      Column({ space: AppSpacing.SM }) {
        Text('把文件投递给一组人')
          .fontSize(AppTypography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)

        Text('新建群后复制邀请给好友，成员之间共享同一条端到端加密文件流。')
          .fontSize(AppTypography.BODY_SMALL)
          .fontColor(AppColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .lineHeight(21)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding({ top: AppSpacing.XXL, bottom: AppSpacing.XXL })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  groupRow(group: GroupSession) {
    Row({ space: AppSpacing.MD }) {
      this.groupAvatar(this.groupInitial(group), this.selectedGroupId === group.id, this.groupColor(group))

      Column({ space: 5 }) {
        Text(group.plainName)
          .fontSize(AppTypography.BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('加密文件流')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(72)
    .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
    .backgroundColor(this.selectedGroupId === group.id ? AppColors.SURFACE_RAISED : AppColors.SURFACE)
    .borderRadius(AppRadius.MD)
    .onClick(() => {
      this.onSelectGroup(group.id);
    })
  }

  @Builder
  listActions() {
    Row({ space: AppSpacing.LG }) {
      Column({ space: AppSpacing.XS }) {
        CdIconButton({
          icon: $r('app.media.cd_icon_new_chat'),
          variant: 'contained',
          onTap: () => {
            this.showCreatePanel = !this.showCreatePanel;
            this.showJoinPanel = false;
            this.showRestorePanel = false;
          }
        })

        Text('新建')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Center)

      Column({ space: AppSpacing.XS }) {
        CdIconButton({
          icon: $r('app.media.cd_icon_link'),
          variant: 'tonal',
          onTap: () => {
            this.showJoinPanel = !this.showJoinPanel;
            this.showCreatePanel = false;
            this.showRestorePanel = false;
          }
        })

        Text('加入')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Center)

      Column({ space: AppSpacing.XS }) {
        CdIconButton({
          icon: $r('app.media.cd_icon_lock'),
          variant: 'tonal',
          onTap: () => {
            this.showRestorePanel = !this.showRestorePanel;
            this.showCreatePanel = false;
            this.showJoinPanel = false;
          }
        })

        Text('恢复')
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  createPanel() {
    if (this.showCreatePanel) {
      CdPanel() {
        Column({ space: AppSpacing.MD }) {
          CdTextField({
            label: '群名称',
            placeholder: '例如 课程资料群',
            value: $groupName
          })

          CdButton({
            label: '创建并进入',
            variant: 'contained',
            interactive: !this.busy,
            onTap: () => {
              this.onCreateGroup();
            }
          })
        }
        .width('100%')
      }
    }
  }

  @Builder
  joinPanel() {
    if (this.showJoinPanel) {
      CdPanel() {
        Column({ space: AppSpacing.MD }) {
          CdTextField({
            label: '邀请链接',
            placeholder: '粘贴好友发来的群邀请',
            value: $inviteText
          })

          CdButton({
            label: '加入群组',
            variant: 'contained',
            interactive: !this.busy,
            onTap: () => {
              this.onJoinGroup();
            }
          })
        }
        .width('100%')
      }
    }
  }

  @Builder
  restorePanel() {
    if (this.showRestorePanel) {
      CdPanel() {
        Column({ space: AppSpacing.MD }) {
          CdTextField({
            label: '恢复口令',
            placeholder: '输入备份时设置的口令',
            obscure: true,
            value: $recoveryPassphrase
          })

          CdButton({
            label: '恢复群组',
            variant: 'contained',
            interactive: !this.busy,
            onTap: () => {
              this.onRestoreBackup();
            }
          })
        }
        .width('100%')
      }
    }
  }

  build() {
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
        Column({ space: AppSpacing.SM }) {
          Row() {
            Text('最近群组')
              .fontSize(AppTypography.TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)
              .layoutWeight(1)

            Text(`${this.groups.length}`)
              .fontSize(AppTypography.CAPTION)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY_SELECTED)
              .textAlign(TextAlign.Center)
              .width(28)
              .height(22)
              .backgroundColor(AppColors.PRIMARY_SOFT)
              .borderRadius(11)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          if (this.groups.length === 0) {
            this.emptyState()
          } else {
            ForEach(this.groups, (group: GroupSession) => {
              this.groupRow(group)
            }, (group: GroupSession) => group.id)
          }
        }
        .width('100%')
        .padding({ top: AppSpacing.MD })

        this.listActions()
        this.createPanel()
        this.joinPanel()
        this.restorePanel()
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.MD })
      .backgroundColor('#F8FBFF')
      .borderRadius(AppRadius.XL)
    }
    .width('100%')
  }
}
