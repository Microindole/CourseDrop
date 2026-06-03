import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { appRdbStore } from '../common/AppRdbStore';
import { AppRuntimeContext } from '../common/AppRuntimeContext';
import { relaySourceService } from '../services/relay';

const DOMAIN: number = 0x0000;
const TAG: string = 'CourseDrop';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppRuntimeContext.configure(this.context, this.context.filesDir);
    appRdbStore.open();
    relaySourceService.applyActiveServer();
    hilog.info(DOMAIN, TAG, 'EntryAbility onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/SplashPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
      }
    });
  }
}
