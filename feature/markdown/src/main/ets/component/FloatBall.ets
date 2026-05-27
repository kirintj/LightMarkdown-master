import { curves } from '@kit.ArkUI';
import { HdsMiniBarButton } from 'hds_button'
import { hdsMaterial, HdsTabs } from '@kit.UIDesignKit';

export class Constants {
  static readonly PAGE_PADDING: number = 12; // 页面内容内边距，用于悬浮窗位置计算
  static readonly FLOAT_WINDOW_WIDTH: number = 90; // 悬浮窗宽度
  static readonly FLOAT_WINDOW_HEIGHT: number = 90; // 悬浮窗高度
  static readonly INIT_POSITION_Y: number = 300; // 悬浮窗相对父容器左上角的Y坐标初始值
}
/**
 * 使用悬浮窗组件样例
 *
 * 核心组件:
 * 1. FloatWindowView
 *
 * 实现步骤：
 *  1. 悬浮窗组件使用Stack嵌套其他布局实现，使用属性position绝对定位使组件悬浮，position使用Edges类型控制悬浮窗到父组件四条边的距离
 *  2. 初始化时悬浮窗的position属性设置top和right，让悬浮窗靠右
 *  3. 父组件添加onAreaChange回调，获取父组件的宽高
 *  4. 悬浮窗组件添加onTouchEvent回调，在手指按下时保存触摸点在窗口中的坐标，用于移动时悬浮窗位置的计算
 *  5. 手指移动时，获取触摸点相对于应用窗口左上角的X和Y坐标，通过计算设置悬浮窗的position坐标实现拖拽，使用默认参数的弹性跟手动画曲线curves.responsiveSpringMotion结合animateTo实现跟手动画效果
 *  6. 手指抬起时，通过判断悬浮窗中心在水平方向位于父组件中心的左侧或右侧设置悬浮窗靠左或靠右，如果悬浮窗超出内容区上下边界，则将悬浮窗设置在边界位置，使用curves.springMotion弹性动画曲线实现吸附边界时的弹性动画效果
 */
@Component
export struct FloatBall {
  private scroller: Scroller = new Scroller();
  // 父组件宽度
  @State containerWidth: number = 0;
  // 父组件高度
  @State containerHeight: number = 0;
  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 以column作为悬浮窗视图下面的内容区，由开发者自行实现
      Column().width('100%').height('100%')
      // 悬浮窗视图必须是顶层显示
      FloatWindowView({ containerWidth: this.containerWidth, containerHeight: this.containerHeight })
    }
    .width('100%')
    .height('100%')
    .onAreaChange((oldValue: Area, newValue: Area) => {
      // TODO：性能知识点：onAreaChange是高频回调，仅在父组件尺寸改变时获取新的父组件宽高，避免性能损耗
      if (oldValue.width !== newValue.width) {
        this.containerWidth = newValue.width as number;
      }
      if (oldValue.height !== newValue.height) {
        this.containerHeight = newValue.height as number;
      }
    })
  }
}

@Component
struct FloatWindowView {
  // 悬浮窗相对于父组件四条边的距离，top和bottom同时设置时top生效，right和left同时设置时left生效
  @State edge: Edges = { top: Constants.INIT_POSITION_Y, right: Constants.PAGE_PADDING };
  @Link containerWidth: number;
  @Link containerHeight: number;
  // 拖拽移动开始时悬浮窗在窗口中的坐标，每次移动回调触发时更新
  private windowStartX: number = 0;
  private windowStartY: number = 0;

  /**
   * 触摸回调，悬浮窗跟手和贴边动画
   */
  onTouchEvent(event: TouchEvent): void {
    switch (event.type) {
      case TouchType.Down: {
        // 获取拖拽开始时悬浮窗在窗口中的坐标
        this.windowStartX = event.touches[0].windowX;
        this.windowStartY = event.touches[0].windowY;
        break;
      }
      case TouchType.Move: {
        const windowX: number = event.touches[0].windowX;
        const windowY: number = event.touches[0].windowY;
        // TODO：知识点：跟手动画，推荐使用默认参数的弹性跟手动画曲线curves.responsiveSpringMotion。
        this.getUIContext().animateTo({ curve: curves.responsiveSpringMotion() }, () => {
          // 判断当前edge中属性left和right哪个不为undefined，用于控制悬浮窗水平方向的位置
          if (this.edge.left !== undefined) {
            this.edge.left = this.edge.left as number + (windowX - this.windowStartX);
          } else {
            this.edge.right = this.edge.right as number - (windowX - this.windowStartX);
          }
          this.edge.top = this.edge.top as number + (windowY - this.windowStartY);
          this.windowStartX = windowX;
          this.windowStartY = windowY;
        })
        break;
      }
      case TouchType.Up: {
        // 计算悬浮窗中心点在父组件中水平方向的坐标
        let centerX: number;
        if (this.edge.left !== undefined) {
          centerX = this.edge.left as number + Constants.FLOAT_WINDOW_WIDTH / 2;
        } else {
          centerX = this.containerWidth - (this.edge.right as number) - Constants.FLOAT_WINDOW_WIDTH / 2;
        }
        // TODO：知识点：通过判断悬浮窗在父组件中的位置，设置悬浮窗贴边，使用curves.springMotion()弹性动画曲线，可以实现阻尼动画效果
        this.getUIContext().animateTo({ curve: curves.springMotion() }, () => {
          // 判断悬浮窗中心在水平方向是否超过父组件宽度的一半，根据结果设置靠左或靠右(如果不想要左右吸附效果，则将edge的left和right设置逻辑去除)
          if (centerX > (this.containerWidth / 2)) {
            this.edge.right = Constants.PAGE_PADDING;
            this.edge.left = undefined;
          } else {
            this.edge.right = undefined;
            this.edge.left = Constants.PAGE_PADDING;
          }
          // 判断悬浮窗是否超出内容区上下边界，根据结果将悬浮窗设置在边界位置
          if (this.edge.top as number < Constants.PAGE_PADDING) {
            this.edge.top = Constants.PAGE_PADDING;
          } else if (this.edge.top as number >
            this.containerHeight - Constants.FLOAT_WINDOW_HEIGHT - Constants.PAGE_PADDING) {
            this.edge.top = this.containerHeight - Constants.FLOAT_WINDOW_HEIGHT - Constants.PAGE_PADDING;
          }
        })
        break;
      }
      default: {
        break;
      }
    }
  }
  @Builder
  plus(){
    Column(){
      SymbolGlyph($r('sys.symbol.plus'))
        .fontColor([Color.Black])
        .backgroundColor(Color.Pink)
        .fontSize(24)
        .clip(true)
        .borderRadius('50%')
        .width(56)
        .height(56)
        .position(this.edge)
        .onClick(()=>{
        })
        .onTouch((event: TouchEvent) => {
          this.onTouchEvent(event);
        })
    }
  }
  build() {
      HdsTabs(){
        TabContent()
          .tabBar(this.plus())
      }
      .barFloatingStyle({
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        },

        adaptToHandedness: true
      })
      .barPosition(BarPosition.End)
      .barOverlap(true)
      .vertical(false)
      .scrollable(false)
      .animationDuration(0)
  }
}