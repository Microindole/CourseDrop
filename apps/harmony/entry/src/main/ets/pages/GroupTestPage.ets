import router from '@ohos.router';
import {
  CdGroupChatView,
  CdGroupListView,
  CdScrollContainer
} from '../components/index';
import { GroupMember, GroupMessage, GroupSession } from '../models/Group';
import { groupRealtimeService, GroupRealtimeEvent } from '../services/group';
import { GroupMessagePreview, GroupTestViewModel } from '../viewmodels/GroupTestViewModel';

@Entry
@Component
struct GroupTestPage {
  private viewModel: GroupTestViewModel = new GroupTestViewModel();
  private unsubscribeRealtime: () => void = () => {};

  @State groupName: string = this.viewModel.groupName;
  @State messageText: string = this.viewModel.messageText;
  @State inviteText: string = this.viewModel.inviteText;
  @State actionText: string = this.viewModel.lastActionText;
  @State errorMessage: string = '';
  @State groupId: string = '';
  @State groupTitle: string = '';
  @State groupAvatarText: string = '群';
  @State groupAvatarColor: string = '#1466FF';
  @State avatarEditText: string = '群';
  @State avatarEditColor: string = '#1466FF';
  @State recoveryPassphrase: string = '';
  @State busy: boolean = false;
  @State groups: GroupSession[] = [];
  @State members: GroupMember[] = [];
  @State messages: GroupMessage[] = [];
  @State messagePreviews: GroupMessagePreview[] = [];
  @State pageMode: string = 'list';
  @State showCreatePanel: boolean = false;
  @State showJoinPanel: boolean = false;
  @State showRestorePanel: boolean = false;
  @State showNotice: boolean = false;
  @State showInvitePanel: boolean = false;
  @State showDetailPanel: boolean = false;

  aboutToAppear() {
    this.viewModel.initializeFromLocalState();
    this.syncState();
    this.refreshPreviews();
    groupRealtimeService.connect();
    this.unsubscribeRealtime = groupRealtimeService.subscribe((event: GroupRealtimeEvent) => {
      this.handleRealtimeEvent(event);
    });
  }

  aboutToDisappear() {
    this.unsubscribeRealtime();
  }

  private syncState(): void {
    const group: GroupSession | undefined = this.viewModel.currentGroup;
    this.actionText = this.viewModel.lastActionText;
    this.errorMessage = this.viewModel.errorMessage;
    this.groupId = group === undefined ? '' : group.id;
    this.groupTitle = group === undefined ? '' : group.plainName;
    this.groupAvatarText = group === undefined || group.config.avatarText === undefined ? '群' : group.config.avatarText;
    this.groupAvatarColor = group === undefined || group.config.avatarColor === undefined ? '#1466FF' : group.config.avatarColor;
    this.avatarEditText = this.groupAvatarText;
    this.avatarEditColor = this.groupAvatarColor;
    this.groups = this.viewModel.groups;
    this.members = this.viewModel.members;
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

  private handleRealtimeEvent(event: GroupRealtimeEvent): void {
    this.viewModel.handleRealtimeMessage(event.groupId)
      .then(() => {
        this.syncState();
        return this.viewModel.describeMessagePreviews();
      })
      .then((previews: GroupMessagePreview[]) => {
        this.messagePreviews = previews;
      })
      .catch((error: Error) => {
        console.error(`[CourseDrop] group realtime sync failed: ${String(error)}`);
      });
  }

  private selectGroup(groupId: string): void {
    try {
      this.viewModel.selectGroup(groupId);
      this.syncState();
      this.refreshPreviews();
      this.pageMode = 'chat';
      this.viewModel.syncMessages()
        .then(() => {
          this.syncState();
          return this.viewModel.describeMessagePreviews();
        })
        .then((previews: GroupMessagePreview[]) => {
          this.messagePreviews = previews;
        })
        .catch((error: Error) => {
          console.error(`[CourseDrop] group enter sync failed: ${String(error)}`);
        });
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
        recoveryPassphrase: $recoveryPassphrase,
        showCreatePanel: $showCreatePanel,
        showJoinPanel: $showJoinPanel,
        showRestorePanel: $showRestorePanel,
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
            groupRealtimeService.connect();
            await this.viewModel.createGroup();
            this.pageMode = 'chat';
            this.showCreatePanel = false;
          });
        },
        onJoinGroup: () => {
          this.runTask(async () => {
            await this.viewModel.registerIdentity();
            groupRealtimeService.connect();
            await this.viewModel.joinGroupFromInvite(this.inviteText);
            this.pageMode = 'chat';
            this.showJoinPanel = false;
          });
        },
        onRestoreBackup: () => {
          this.runTask(async () => {
            await this.viewModel.registerIdentity();
            await this.viewModel.restoreFirstGroupBackup(this.recoveryPassphrase);
            this.pageMode = 'chat';
            this.showRestorePanel = false;
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
      members: this.members,
      previews: this.messagePreviews,
      busy: this.busy,
      inviteText: this.inviteText,
      showNotice: this.showNotice,
      errorMessage: this.errorMessage,
      messageText: $messageText,
      avatarEditText: $avatarEditText,
      avatarEditColor: $avatarEditColor,
      recoveryPassphrase: $recoveryPassphrase,
      showInvitePanel: $showInvitePanel,
      showDetailPanel: $showDetailPanel,
      onBack: () => {
        this.pageMode = 'list';
      },
      onSync: () => {
        this.runTask(async () => {
          await this.viewModel.syncMessages();
          await this.viewModel.syncMembers();
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
      onSaveProfile: () => {
        this.runTask(async () => {
          this.viewModel.updateGroupProfile(this.avatarEditText, this.avatarEditColor);
        });
      },
      onBackupKey: () => {
        this.runTask(async () => {
          await this.viewModel.backupCurrentGroup(this.recoveryPassphrase);
        });
      },
      onRestoreBackup: () => {
        this.runTask(async () => {
          await this.viewModel.restoreFirstGroupBackup(this.recoveryPassphrase);
          this.pageMode = 'chat';
        });
      },
      onLeaveGroup: () => {
        this.runTask(async () => {
          await this.viewModel.leaveCurrentGroup();
          this.pageMode = this.viewModel.currentGroup === undefined ? 'list' : 'chat';
          this.showDetailPanel = false;
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
