import { AppConfig } from '../common/AppConfig';
import { Device } from '../models/Device';
import { ShareSession } from '../models/ShareSession';
import { TransferTask } from '../models/TransferTask';
import { deviceDiscoveryService } from '../services/device';
import { shareService } from '../services/share';

export interface HomeTransferStats {
  activeCount: number;
  completedCount: number;
  failedCount: number;
  expiringCount: number;
}

export class HomeViewModel {
  appName: string = AppConfig.APP_NAME;
  subtitle: string = '本地优先的加密文件传输与分享管理';
  recentShares: ShareSession[] = shareService.listRecentSessions(5);
  nearbyDevices: Device[] = deviceDiscoveryService.listDevices().slice(0, 2);
  activeTasks: TransferTask[] = shareService.listTasks(shareService.getCurrentSession().id)
    .filter((task) => task.status === 'RUNNING');

  getTransferStats(): HomeTransferStats {
    return shareService.getStats();
  }

  getPrimaryShare(): ShareSession {
    return shareService.getCurrentSession();
  }
}
