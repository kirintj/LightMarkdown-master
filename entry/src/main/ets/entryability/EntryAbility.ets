import { Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageV2, window } from '@kit.ArkUI';
import { WindowUtil, GlobalInfoModel, StorageKey, PageContext } from 'common';
import { AccountService } from 'common';
import { PreferenceManager } from 'common/src/main/ets/util/PreferenceManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {

  onCreate(want: Want): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    AppStorage.setOrCreate<ConfigurationConstant.ColorMode>('currentColorMode', this.context.config.colorMode);
    this.handleWantParam(want);

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onNewWant(want: Want): void {
    this.handleWantParam(want);
  }

  private handleWantParam(want: Want): void {
    if (want.parameters) {
      AppStorage.setOrCreate(StorageKey.WANT_PARAMETERS, want.parameters);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {

    try {
      let windowClass: window.Window = windowStage.getMainWindowSync();
      windowClass.setWindowLayoutFullScreen(true).catch(() => {
        // TODO: Implement error handling.
      });

      // 保留现有安全区域逻辑（兼容旧代码）
      let topRectHeight = windowClass
        .getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
        .topRect.height;
      let bottomRectHeight = windowClass
        .getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
        .bottomRect.height;
      AppStorage.setOrCreate('safeTop', px2vp(topRectHeight));
      AppStorage.setOrCreate('safeBottom', px2vp(bottomRectHeight));
      windowClass.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          AppStorage.setOrCreate('safeTop', px2vp(data.area.topRect.height));
        } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          AppStorage.setOrCreate('safeBottom', px2vp(data.area.bottomRect.height));
        }
      });
    } catch (error) {
    }

    // 创建统一导航栈
    AppStorage.setOrCreate(StorageKey.HOME_PAGE_CONTEXT, new PageContext());

    // 加载首页
    windowStage.loadContent('pages/SplashPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      // 初始化 PreferenceManager
      PreferenceManager.getInstance().init(this.context).then(() => {
        // 初始化账号服务
        AccountService.getInstance().init();
      });
      // 初始化窗口工具（含断点监听）
      WindowUtil.initialize(windowStage);
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    let newColorMode = newConfig.colorMode;
    let currentColorMode = AppStorage.get<ConfigurationConstant.ColorMode>('currentColorMode');
    if (newColorMode === currentColorMode) {
      return;
    }
    // 更新缓存中的颜色模式
    AppStorage.setOrCreate('currentColorMode', newConfig.colorMode);
  }
  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
