import { deviceInfo } from '@kit.BasicServicesKit';

export class HdsUtil {
  public static isSupportNewMaterialApi(): boolean {
    return deviceInfo.distributionOSApiVersion >= 60100;
  }
}