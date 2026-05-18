import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { logger from '@ohos.hilog';

const TAG: string = '[RustDesk]';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    logger.info(TAG, '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        logger.error(TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      logger.info(TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
    
    this.initNativeCore();
  }

  initNativeCore(): void {
    try {
      const rustCore = requireNapi('rustdesk_core');
      if (rustCore.initialize('/data/storage/el2/base/haps/entry/files');
    } catch (e) {
      logger.error(TAG, 'Failed to initialize rust core: ' + JSON.stringify(e));
    }
  }
}
