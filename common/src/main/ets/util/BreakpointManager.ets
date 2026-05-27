import { window } from '@kit.ArkUI';
import { BreakpointSystem } from './BreakpointSystem';
import { BreakpointTypeEnum, GlobalInfoModel } from '../model/GlobalInfoModel';
import { StorageKey } from '../constant/CommonEnums';

export class BreakpointManager {
  private static instance: BreakpointManager;
  private breakpointSystem: BreakpointSystem;
  private initialized: boolean = false;
  private win: window.Window | undefined = undefined;

  private constructor() {
    this.breakpointSystem = BreakpointSystem.getInstance();
  }

  public static getInstance(): BreakpointManager {
    if (!BreakpointManager.instance) {
      BreakpointManager.instance = new BreakpointManager();
    }
    return BreakpointManager.instance;
  }

  public init(win: window.Window): void {
    if (this.initialized) {
      return;
    }
    this.win = win;
    this.breakpointSystem.onWindowSizeChange(win);
    // 监听窗口变化
    win.on('windowSizeChange', (windowSize: window.Size) => {
      this.breakpointSystem.onWindowSizeChange(win);
    });
    this.initialized = true;
  }

  public destroy(): void {
    if (this.win) {
      this.win.off('windowSizeChange');
      this.win = undefined;
    }
    this.initialized = false;
  }

  public getCurrentBreakpoint(): BreakpointTypeEnum {
    const globalInfoModel: GlobalInfoModel = AppStorage.get(StorageKey.GLOBAL_INFO) || new GlobalInfoModel();
    return globalInfoModel.currentBreakpoint;
  }

  public isPhone(): boolean {
    const bp = this.getCurrentBreakpoint();
    return bp === BreakpointTypeEnum.SM || bp === BreakpointTypeEnum.XS;
  }

  public isFoldable(): boolean {
    return this.getCurrentBreakpoint() === BreakpointTypeEnum.MD;
  }

  public isTablet(): boolean {
    const bp = this.getCurrentBreakpoint();
    return bp === BreakpointTypeEnum.LG || bp === BreakpointTypeEnum.XL;
  }

  public getGridColumns(): number {
    const bp = this.getCurrentBreakpoint();
    switch (bp) {
      case BreakpointTypeEnum.XS:
        return 1;
      case BreakpointTypeEnum.SM:
        return 1;
      case BreakpointTypeEnum.MD:
        return 2;
      case BreakpointTypeEnum.LG:
        return 3;
      case BreakpointTypeEnum.XL:
        return 4;
      default:
        return 1;
    }
  }

  public getContentPadding(): number {
    const bp = this.getCurrentBreakpoint();
    switch (bp) {
      case BreakpointTypeEnum.XS:
      case BreakpointTypeEnum.SM:
        return 12;
      case BreakpointTypeEnum.MD:
        return 16;
      case BreakpointTypeEnum.LG:
      case BreakpointTypeEnum.XL:
        return 24;
      default:
        return 12;
    }
  }
}
