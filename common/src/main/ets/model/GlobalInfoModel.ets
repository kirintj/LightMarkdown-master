@Observed
export class GlobalInfoModel {
  // 断点信息
  public widthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  public heightBreakpoint: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM;

  // 窗口尺寸 (vp)
  public deviceWidth: number = 0;
  public deviceHeight: number = 0;

  // 宽高比
  public aspectRatio: number = 0;

  // 系统安全区域
  public statusBarHeight: number = 0;    // 状态栏高度
  public naviIndicatorHeight: number = 0; // 导航栏高度
  public decorHeight: number = 0;         // 窗口装饰高度

  // 动态标题栏隐藏标志
  public needDynamicHideBar: boolean = false;

  // 折叠屏展开状态
  public foldExpanded: boolean = false;
}
