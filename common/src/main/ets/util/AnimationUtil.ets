import { curves, UIContext } from '@kit.ArkUI';

/**
 * 弹簧曲线预设
 */
export class SpringCurve {
  // 卡片点击回弹（轻微振荡）
  static readonly CARD = curves.interpolatingSpring(0, 1, 288, 30);
  // 弹窗出现（更弹）
  static readonly DIALOG = curves.interpolatingSpring(0, 1, 273, 33);
  // 按钮反馈（快速回弹）
  static readonly BUTTON = curves.interpolatingSpring(0, 1, 200, 40);
  // 列表项入场（柔和）
  static readonly LIST_ITEM = curves.interpolatingSpring(0, 0.8, 350, 25);
}

/**
 * 动画时长常量
 */
export class AnimDuration {
  static readonly MICRO: number = 150;
  static readonly SHORT: number = 200;
  static readonly MEDIUM: number = 250;
  static readonly LONG: number = 300;
}

/**
 * 缩放值常量
 */
export class ScaleValue {
  static readonly CARD_PRESS: number = 0.95;
  static readonly BUTTON_PRESS: number = 0.9;
  static readonly DIALOG_ENTER: number = 0.9;
}

/**
 * 动画工具类
 */
export class AnimUtil {
  /**
   * 弹簧动画封装（用于 animateTo）
   */
  static spring(
    uiContext: UIContext,
    change: () => void,
    curve = SpringCurve.CARD,
    duration = AnimDuration.MEDIUM
  ): void {
    uiContext.animateTo({ curve, duration }, change);
  }

  /**
   * 淡入转场
   */
  static fadeInTransition(): TransitionEffect {
    return TransitionEffect.OPACITY.animation({ duration: AnimDuration.LONG });
  }

  /**
   * 缩放 + 淡入组合转场
   */
  static scaleFadeTransition(): TransitionEffect {
    return TransitionEffect.OPACITY
      .combine(TransitionEffect.scale({ x: ScaleValue.DIALOG_ENTER, y: ScaleValue.DIALOG_ENTER }))
      .animation({ duration: AnimDuration.MEDIUM, curve: SpringCurve.DIALOG });
  }

  /**
   * 从底部滑入转场
   */
  static slideUpTransition(): TransitionEffect {
    return TransitionEffect.move(TransitionEdge.BOTTOM)
      .animation({ duration: AnimDuration.MEDIUM, curve: SpringCurve.LIST_ITEM });
  }
}
