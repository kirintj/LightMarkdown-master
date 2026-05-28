// 断点类型接口
export interface BreakpointTypes<T> {
  xs?: T;  // 超小屏 (可选，默认等于 sm)
  sm: T;   // 小屏 (手机竖屏)
  md: T;   // 中屏 (手机横屏/小平板)
  lg: T;   // 大屏 (平板/折叠屏展开)
  xl?: T;  // 超大屏 (PC/2in1，可选，默认等于 lg)
}

// 断点值映射类
export class BreakpointType<T> {
  private xs: T;
  private sm: T;
  private md: T;
  private lg: T;
  private xl: T;

  public constructor(param: BreakpointTypes<T>) {
    this.xs = param.xs ?? param.sm;
    this.sm = param.sm;
    this.md = param.md;
    this.lg = param.lg;
    this.xl = param.xl ?? param.lg;
  }

  public getValue(currentBreakpoint: WidthBreakpoint): T {
    if (currentBreakpoint === WidthBreakpoint.WIDTH_XS) return this.xs;
    if (currentBreakpoint === WidthBreakpoint.WIDTH_SM) return this.sm;
    if (currentBreakpoint === WidthBreakpoint.WIDTH_MD) return this.md;
    if (currentBreakpoint === WidthBreakpoint.WIDTH_XL) return this.xl;
    return this.lg;
  }
}
