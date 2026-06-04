import router from '@ohos.router';
import {
  CdGroupChatView,
  CdGroupListView,
  CdScrollContainer
} from '../components/index';
import { GroupMessage, GroupSession } from '../models/Group';
import { GroupMessagePreview, GroupTestViewModel } from '../viewmodels/GroupTestViewModel';

@Entry
@Component
struct GroupTestPage {
  private viewModel: GroupTestViewModel = new GroupTestViewModel();

  @State groupName: string = this.viewModel.groupName;
  @State messageText: string = this.viewModel.messageText;
  @State inviteText: string = this.viewModel.inviteText;
  @State actionText: string = this.viewModel.lastActionText;
  @State errorMessage: string = '';
  @State groupId: string = '';
  @State groupTitle: string = '';
  @State groupAvatarText: string = '群';
  @State groupAvatarColor: string = '#1466FF';
  @State busy: boolean = false;
  @State groups: GroupSession[] = [];
  @State messages: GroupMessage[] = [];
  @State messagePreviews: GroupMessagePreview[] = [];
  @State pageMode: string = 'list';
  @State showCreatePanel: boolean = false;
  @State showJoinPanel: boolean = false;
  @State showNotice: boolean = false;
  @State showInvitePanel: boolean = false;

  aboutToAppear() {
    this.viewModel.initializeFromLocalState();
    this.syncState();
    this.refreshPreviews();
  }

  private syncState(): void {
    const group: GroupSession | undefined = this.viewModel.currentGroup;
    this.actionText = this.viewModel.lastActionText;
    this.errorMessage = this.viewModel.errorMessage;
    this.groupId = group === undefined ? '' : group.id;
    this.groupTitle = group === undefined ? '' : group.plainName;
    this.groupAvatarText = group === undefined || group.config.avatarText === undefined ? '群' : group.config.avatarText;
    this.groupAvatarColor = group === undefined || group.config.avatarColor === undefined ? '#1466FF' : group.config.avatarColor;
    this.groups = this.viewModel.groups;
    this.messages = this.viewModel.messages;
    this.inviteText = this.viewModel.inviteText;
    this.messageText = this.viewModel.messageText;
  }

  private refreshPreviews(): void {
    this.viewModel.describeMessagePreviews()
      .then((previews: GroupMessagePreview[]) => {
        this.messagePreviews = previews;
      })
      .catch((_error: Error) => {
        this.messagePreviews = [];
      });
  }

  private runTask(task: () => Promise<void>): void {
    this.busy = true;
    this.errorMessage = '';
    task()
      .then(() => {
        this.syncState();
        return this.viewModel.describeMessagePreviews();
      })
      .then((previews: GroupMessagePreview[]) => {
        this.messagePreviews = previews;
        this.showNotice = true;
      })
      .catch((error: Error) => {
        this.errorMessage = String(error);
        this.actionText = '操作失败';
        this.showNotice = true;
      })
      .finally(() => {
        this.busy = false;
      });
  }

  private selectGroup(groupId: string): void {
    try {
      this.viewModel.selectGroup(groupId);
      this.syncState();
      this.refreshPreviews();
      this.pageMode = 'chat';
    } catch (error) {
      this.errorMessage = String(error);
      this.actionText = '切换群组失败';
      this.showNotice = true;
    }
  }

  @Builder
  listPage() {
    CdScrollContainer({ showScrollBar: true, backgroundStyle: 'settings' }) {
      CdGroupListView({
        groups: this.groups,
        selectedGroupId: this.groupId,
        busy: this.busy,
        showNotice: this.showNotice,
        errorMessage: this.errorMessage,
        groupName: $groupName,
        inviteText: $inviteText,
        showCreatePanel: $showCreatePanel,
        showJoinPanel: $showJoinPanel,
        onBack: () => {
          router.back();
        },
        onSelectGroup: (groupId: string) => {
          this.selectGroup(groupId);
        },
        onCreateGroup: () => {
          this.runTask(async () => {
            this.viewModel.groupName = this.groupName;
            await this.viewModel.registerIdentity();
            await this.viewModel.createGroup();
            this.pageMode = 'chat';
            this.showCreatePanel = false;
          });
        },
        onJoinGroup: () => {
          this.runTask(async () => {
            await this.viewModel.registerIdentity();
            await this.viewModel.joinGroupFromInvite(this.inviteText);
            this.pageMode = 'chat';
            this.showJoinPanel = false;
          });
        }
      })
    }
  }

  @Builder
  chatPage() {
    CdGroupChatView({
      groupTitle: this.groupTitle,
      avatarText: this.groupAvatarText,
      avatarColor: this.groupAvatarColor,
      messageCount: this.messages.length,
      previews: this.messagePreviews,
      busy: this.busy,
      inviteText: this.inviteText,
      showNotice: this.showNotice,
      errorMessage: this.errorMessage,
      messageText: $messageText,
      showInvitePanel: $showInvitePanel,
      onBack: () => {
        this.pageMode = 'list';
      },
      onSync: () => {
        this.runTask(async () => {
          await this.viewModel.syncMessages();
        });
      },
      onInvite: () => {
        this.showInvitePanel = true;
        this.runTask(async () => {
          await this.viewModel.copyCurrentInvite();
        });
      },
      onCopyInvite: () => {
        this.runTask(async () => {
          await this.viewModel.copyCurrentInvite();
        });
      },
      onSendFile: () => {
        this.runTask(async () => {
          await this.viewModel.sendFileMessage();
        });
      },
      onSendText: () => {
        this.runTask(async () => {
          this.viewModel.messageText = this.messageText;
          await this.viewModel.sendTextMessage();
        });
      },
      onDownloadFile: (messageId: string) => {
        this.runTask(async () => {
          await this.viewModel.receiveFileMessage(messageId);
        });
      }
    })
  }

  build() {
    Stack() {
      if (this.pageMode === 'chat' && this.groupId.length > 0) {
        this.chatPage()
      } else {
        this.listPage()
      }
    }
    .width('100%')
    .height('100%')
  }
}
