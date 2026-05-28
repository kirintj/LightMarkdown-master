import { updateManager } from '@kit.AppGalleryKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { StorageKey } from '../constant/CommonEnums';

const TAG: string = '[UpdateService]';

export class UpdateService {
  private static instance: UpdateService;

  private constructor() {}

  public static getInstance(): UpdateService {
    if (!UpdateService.instance) {
      UpdateService.instance = new UpdateService();
    }
    return UpdateService.instance;
  }

  private getContext(): common.UIAbilityContext | undefined {
    const uiContext: UIContext | undefined = AppStorage.get<UIContext>(StorageKey.UI_CONTEXT);
    return uiContext?.getHostContext() as common.UIAbilityContext | undefined;
  }

  /**
   * 检查是否有新版本
   * @returns true=有新版本, false=已是最新
   */
  public checkUpdate(): Promise<boolean> {
    const context = this.getContext();
    return new Promise((resolve: Function, reject: Function) => {
      try {
        if (!context) {
          console.error(TAG, 'checkAppUpdate failed: context is undefined');
          reject(false);
          return;
        }
        updateManager.checkAppUpdate(context)
          .then((checkResult: updateManager.CheckUpdateResult) => {
            console.info(TAG, 'checkResult updateAvailable:' + checkResult.updateAvailable);
            if (checkResult.updateAvailable === updateManager.UpdateAvailableCode.LATER_VERSION_EXIST) {
              resolve(true);
            } else {
              resolve(false);
            }
          })
          .catch((error: BusinessError) => {
            console.error(TAG, `checkAppUpdate error: ${error.code} ${error.message}`);
            reject(false);
          });
      } catch (error) {
        const err = error as BusinessError;
        console.error(TAG, `checkAppUpdate error: ${err.code} ${err.message}`);
        reject(false);
      }
    });
  }

  /**
   * 弹出系统更新对话框（含下载+安装）
   */
  public updateVersion(): Promise<boolean> {
    const context = this.getContext();
    return new Promise((resolve: Function, reject: Function) => {
      try {
        if (!context) {
          console.error(TAG, 'updateVersion failed: context is undefined');
          reject(false);
          return;
        }
        updateManager.showUpdateDialog(context)
          .then((resultCode: updateManager.ShowUpdateResultCode) => {
            console.info(TAG, 'showUpdateDialog resultCode:' + resultCode);
            resolve(true);
          })
          .catch((error: BusinessError) => {
            console.error(TAG, `showUpdateDialog error: ${error.code} ${error.message}`);
            reject(false);
          });
      } catch (error) {
        const err = error as BusinessError;
        console.error(TAG, `showUpdateDialog error: ${err.code} ${err.message}`);
        reject(false);
      }
    });
  }
}
