import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { logger } from '@ohos.hilog';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';

const TAG: string = '[RustDesk]';
const PERMISSION_REQUEST_CODE = 1001;

export default class EntryAbility extends UIAbility {
  private atManager: abilityAccessCtrl.AtManager = null;

  async onCreate(want, launchParam): Promise<void> {
    logger.info(TAG, 'Ability onCreate');
    
    // 初始化权限管理
    this.atManager = abilityAccessCtrl.createAtManager();
    
    // 请求必要权限
    await this.requestPermissions();
    
    // 初始化 Native 模块
    try {
      // 初始化将会在 UI 准备就绪后进行
      logger.info(TAG, 'Native module initialized');
    } catch (error) {
      logger.error(TAG, 'Native module initialization failed: ' + JSON.stringify(error));
    }
  }

  /**
   * 请求必要的权限
   */
  async requestPermissions(): Promise<void> {
    const permissions: Permissions[] = [
      'ohos.permission.INTERNET',
      'ohos.permission.GET_NETWORK_INFO',
      'ohos.permission.SCREEN_CAPTURE',
      'ohos.permission.INPUT_MONITORING',
      'ohos.permission.MICROPHONE',
      'ohos.permission.READ_MEDIA',
      'ohos.permission.WRITE_MEDIA',
      'ohos.permission.RUNNING_STATE_OBSERVER',
      'ohos.permission.KEEP_BACKGROUND_RUNNING'
    ];
    
    try {
      const grantStatus = await this.atManager.requestPermissionsFromUser(this.context, permissions, PERMISSION_REQUEST_CODE);
      logger.info(TAG, 'Permission request result: ' + JSON.stringify(grantStatus));
      
      // 检查权限授予情况
      let allGranted = true;
      grantStatus.authResults.forEach((result: number, index: number) => {
        if (result !== 0) {
          allGranted = false;
          logger.warn(TAG, `Permission ${permissions[index]} not granted');
        }
      };
      
      if (allGranted) {
        logger.info(TAG, 'All permissions granted');
      }
    } catch (error) {
      logger.error(TAG, 'Permission request failed: ' + JSON.stringify(error));
    }
  }

  onDestroy(): void {
    logger.info(TAG, 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    logger.info(TAG, 'Ability onWindowStageCreate');
    
    // 禁用截屏（除非在远程桌面模式）
    const windowClass = windowStage.getMainWindowSync();
    if (windowClass) {
      windowClass.setWindowSystemBarProperties({
        isAppearance: true
      });
    }
    
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        logger.error(TAG, 'Failed to load the content. Cause: ' + JSON.stringify(err) ?? '');
        return;
      }
      logger.info(TAG, 'Succeeded in loading the content. Data: ' + JSON.stringify(data) ?? '');
    });
  }

  onWindowStageDestroy(): void {
    logger.info(TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    logger.info(TAG, 'Ability onForeground');
  }

  onBackground(): void {
    logger.info(TAG, 'Ability onBackground');
  }
}
