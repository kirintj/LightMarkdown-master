import { window } from '@kit.ArkUI';
import { GlobalInfoModel } from '../model/GlobalInfoModel';
import { StorageKey } from '../constant/CommonEnums';

const ASPECT_SQUARE_PORTRAIT: number = 9 / 10.8;
const ASPECT_LANDSCAPE_SQUARE: number = 10.8 / 9;

export class WindowUtil {
  private static windowClass?: window.Window;
  private static uiContext: UIContext;

  // 初始化入口
  public static initialize(windowStage: window.WindowStage) {
    WindowUtil.windowClass = windowStage.getMainWindowSync();
    WindowUtil.uiContext = WindowUtil.windowClass.getUIContext();

    // 存储 windowClass 和 UIContext
    AppStorage.setOrCreate('windowClass', WindowUtil.windowClass);
    AppStorage.setOrCreate<UIContext>(StorageKey.UI_CONTEXT, WindowUtil.uiContext);

    // 注册断点监听
    WindowUtil.registerBreakpoint(WindowUtil.windowClass);
  }

  // 注册断点监听
  private static registerBreakpoint(windowClass: window.Window) {
    // 1. 获取初始窗口尺寸
    WindowUtil.getDeviceSize();

    // 2. 获取安全区域
    const globalInfoModel = AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
    const systemAvoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    globalInfoModel.statusBarHeight = WindowUtil.uiContext.px2vp(systemAvoidArea?.topRect?.height ?? 0);

    const bottomArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    globalInfoModel.naviIndicatorHeight = WindowUtil.uiContext.px2vp(bottomArea?.bottomRect?.height ?? 0);

    AppStorage.setOrCreate(StorageKey.GLOBAL_INFO, globalInfoModel);

    // 3. 监听窗口尺寸变化
    windowClass.on('windowSizeChange', (windowSize: window.Size) => {
      WindowUtil.setWindowSize(windowSize);
    });

    // 4. 监听安全区域变化
    windowClass.on('avoidAreaChange', (avoidAreaOption) => {
      if (avoidAreaOption.type === window.AvoidAreaType.TYPE_SYSTEM ||
        avoidAreaOption.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        WindowUtil.setAvoidArea(avoidAreaOption.type, avoidAreaOption.area);
      }
    });
  }

  // 获取设备尺寸
  private static getDeviceSize() {
    if (!WindowUtil.windowClass) return;
    const windowSize = WindowUtil.windowClass.getWindowProperties().windowRect;
    WindowUtil.setWindowSize(windowSize);
  }

  // 更新窗口尺寸和断点
  public static setWindowSize(windowSize?: window.Size | window.Rect) {
    const globalInfoModel = AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();

    if (windowSize) {
      const vpHeight = WindowUtil.uiContext.px2vp(windowSize.height);
      const vpWidth = WindowUtil.uiContext.px2vp(windowSize.width);

      globalInfoModel.deviceHeight = vpHeight;
      globalInfoModel.deviceWidth = vpWidth;

      if (vpHeight > 0) {
        globalInfoModel.aspectRatio = vpWidth / vpHeight;
      }
    }

    // 获取系统断点
    globalInfoModel.widthBreakpoint = WindowUtil.uiContext.getWindowWidthBreakpoint();
    globalInfoModel.heightBreakpoint = WindowUtil.uiContext.getWindowHeightBreakpoint();

    // 计算是否需要动态隐藏标题栏
    if ((globalInfoModel.widthBreakpoint === WidthBreakpoint.WIDTH_SM &&
        globalInfoModel.aspectRatio > ASPECT_SQUARE_PORTRAIT) ||
      (globalInfoModel.widthBreakpoint === WidthBreakpoint.WIDTH_MD &&
        globalInfoModel.aspectRatio > ASPECT_LANDSCAPE_SQUARE)) {
      globalInfoModel.needDynamicHideBar = true;
    } else {
      globalInfoModel.needDynamicHideBar = false;
    }

    AppStorage.setOrCreate(StorageKey.GLOBAL_INFO, globalInfoModel);
  }

  // 更新安全区域
  private static setAvoidArea(type: window.AvoidAreaType, area: window.AvoidArea) {
    const globalInfoModel = AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();

    if (type === window.AvoidAreaType.TYPE_SYSTEM) {
      globalInfoModel.statusBarHeight = WindowUtil.uiContext.px2vp(area.topRect.height);
    } else if (type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
      globalInfoModel.naviIndicatorHeight = WindowUtil.uiContext.px2vp(area.bottomRect.height);
    }

    AppStorage.setOrCreate(StorageKey.GLOBAL_INFO, globalInfoModel);
  }
}
