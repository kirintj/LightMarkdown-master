# HarmonyOS 动画技术指南

## 概述

本指南介绍 HarmonyOS 应用中常用的动画实现方式，包括弹簧动画、渐变动画、转场动画、进度动画等，可直接复用到任何 HarmonyOS 项目。

---

## 动画类型总览

| 类型 | API | 典型时长 | 适用场景 |
|------|-----|----------|----------|
| 弹簧动画 | `curves.interpolatingSpring()` | 250ms | 回弹、悬停放大 |
| 渐变动画 | `.animation()` | 200ms | 属性变化过渡 |
| 显式动画 | `animateTo()` | 自定义 | 状态驱动动画 |
| 透明度转场 | `TransitionEffect.OPACITY` | 默认 | 页面/组件转场 |
| 几何转场 | `.geometryTransition()` | 默认 | 共享元素转场 |
| 进度动画 | `setInterval` + `Progress` | 33ms/帧 | 进度条、倒计时 |
| 滚动动画 | `scrollTo({ animation })` | 200ms | 列表滚动 |
| Symbol 动效 | `.symbolEffect()` | 默认 | 图标反馈 |
| 属性动画 | `animateTo()` | 自定义 | 任意属性变化 |

---

## 1. 弹簧动画 (interpolatingSpring)

### 原理

模拟弹簧物理效果，参数控制阻尼、响应、刚度。

### API

```typescript
import { curves } from '@kit.ArkUI';

// 参数: damping, response, stiffness, velocity
curves.interpolatingSpring(velocity, damping, response, stiffness)
```

| 参数 | 说明 | 典型值 |
|------|------|--------|
| `velocity` | 初始速度 | 0 |
| `damping` | 阻尼 (0-1, 1=无振荡) | 1 |
| `response` | 响应时间 (越小越快) | 288 |
| `stiffness` | 刚度 (越大越硬) | 30 |

### 示例 A: 悬停放大效果

```typescript
import { curves } from '@kit.ArkUI';

@Component
struct HoverCard {
  @State isHover: boolean = false;
  private springAnimation = curves.interpolatingSpring(0, 1, 288, 30);

  build() {
    Column() {
      Text('悬停放大')
    }
    .width(this.isHover ? 200 : 150)
    .height(this.isHover ? 200 : 150)
    .backgroundColor('#1890ff')
    .borderRadius(12)
    .onHover((isHover: boolean) => {
      this.getUIContext().animateTo(
        { curve: this.springAnimation },
        () => {
          this.isHover = isHover;
        }
      );
    })
  }
}
```

### 示例 B: 回弹效果

```typescript
import { curves } from '@kit.ArkUI';

@Component
struct BounceView {
  @State offsetY: number = 0;
  private springAnimation = curves.interpolatingSpring(0, 1, 273, 33);

  bounce() {
    const uiContext = this.getUIContext();
    uiContext.animateTo(
      { curve: this.springAnimation, duration: 250 },
      () => {
        this.offsetY = 0; // 回弹到原位
      }
    );
  }

  build() {
    Column() {
      Text('回弹效果')
    }
    .translate({ y: this.offsetY })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.offsetY = 50; // 按下偏移
      } else if (event.type === TouchType.Up) {
        this.bounce(); // 释放回弹
      }
    })
  }
}
```

---

## 2. 渐变动画 (.animation)

### 原理

当组件属性变化时自动添加过渡动画。

### API

```typescript
.animation({
  duration: number,    // 时长 (ms)
  curve: Curve,        // 曲线
  delay?: number,      // 延迟 (ms)
  iterations?: number, // 迭代次数 (-1=无限)
})
```

### 常用曲线

```typescript
Curve.Linear      // 线性
Curve.Ease        // 缓动 (默认)
Curve.EaseIn      // 缓入
Curve.EaseOut     // 缓出
Curve.EaseInOut   // 缓入缓出
Curve.FastOutSlowIn  // 快出慢入
Curve.FastOutLinearIn // 快出线性入
Curve.LinearOutSlowIn // 线性出慢入
Curve.ExtremeDeceleration // 极端减速
Curve.Sharp        // 急速
Curve.Rhythm       // 节奏
```

### 示例 A: 尺寸变化动画

```typescript
@Component
struct SizeAnimation {
  @State isExpanded: boolean = false;

  build() {
    Column() {
      Text('点击展开')
    }
    .width(this.isExpanded ? 200 : 100)
    .height(this.isExpanded ? 200 : 100)
    .backgroundColor('#1890ff')
    .borderRadius(12)
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    })
    .onClick(() => {
      this.isExpanded = !this.isExpanded;
    })
  }
}
```

### 示例 B: 颜色变化动画

```typescript
@Component
struct ColorAnimation {
  @State isActive: boolean = false;

  build() {
    Button('点击变色')
      .backgroundColor(this.isActive ? '#52c41a' : '#1890ff')
      .animation({
        duration: 200,
        curve: Curve.Ease
      })
      .onClick(() => {
        this.isActive = !this.isActive;
      })
  }
}
```

### 示例 C: 透明度动画

```typescript
@Component
struct FadeAnimation {
  @State isVisible: boolean = true;

  build() {
    Column() {
      Text('淡入淡出')
    }
    .opacity(this.isVisible ? 1 : 0)
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    })
    .onClick(() => {
      this.isVisible = !this.isVisible;
    })
  }
}
```

### 示例 D: 位移动画

```typescript
@Component
struct SlideAnimation {
  @State offsetX: number = 0;

  build() {
    Column() {
      Text('滑动动画')
    }
    .translate({ x: this.offsetX })
    .animation({
      duration: 300,
      curve: Curve.EaseOut
    })
    .onClick(() => {
      this.offsetX = this.offsetX === 0 ? 100 : 0;
    })
  }
}
```

---

## 3. 显式动画 (animateTo)

### 原理

在闭包中修改状态，系统自动添加动画过渡。

### API

```typescript
import { UIContext } from '@kit.ArkUI';

const uiContext = this.getUIContext();
// 或
const uiContext = AppStorage.get<UIContext>(StorageKey.UI_CONTEXT);

uiContext.animateTo(
  {
    duration?: number,      // 时长 (ms)
    curve?: Curve | ICurve, // 曲线
    delay?: number,         // 延迟 (ms)
    iterations?: number,    // 迭代次数
    playMode?: PlayMode,    // 播放模式
    onFinish?: () => void,  // 完成回调
  },
  () => {
    // 在此闭包中修改状态
    this.width = 200;
    this.opacity = 0.5;
  }
);
```

### 示例 A: 组合属性动画

```typescript
@Component
struct MultiPropertyAnimation {
  @State isActive: boolean = false;

  build() {
    Column() {
      Text('点击动画')
    }
    .width(this.isActive ? 200 : 100)
    .height(this.isActive ? 200 : 100)
    .backgroundColor(this.isActive ? '#52c41a' : '#1890ff')
    .borderRadius(this.isActive ? 20 : 12)
    .opacity(this.isActive ? 0.8 : 1)
    .onClick(() => {
      this.getUIContext().animateTo(
        {
          duration: 300,
          curve: Curve.EaseInOut,
          onFinish: () => {
            console.info('动画完成');
          }
        },
        () => {
          this.isActive = !this.isActive;
        }
      );
    })
  }
}
```

### 示例 B: 弹簧动画 + animateTo

```typescript
import { curves } from '@kit.ArkUI';

@Component
struct SpringAnimation {
  @State scale: number = 1;

  build() {
    Column() {
      Text('弹簧缩放')
    }
    .scale({ x: this.scale, y: this.scale })
    .onClick(() => {
      this.getUIContext().animateTo(
        {
          curve: curves.interpolatingSpring(0, 1, 288, 30),
          duration: 250
        },
        () => {
          this.scale = this.scale === 1 ? 1.2 : 1;
        }
      );
    })
  }
}
```

---

## 4. 透明度转场 (TransitionEffect)

### 原理

组件插入/移除时的转场效果。

### API

```typescript
.transition(TransitionEffect | TransitionEffects)

// 预设效果
TransitionEffect.OPACITY          // 透明度
TransitionEffect.scale()          // 缩放
TransitionEffect.slide()          // 滑动
TransitionEffect.move(edge)       // 从边缘移入

// 组合效果
TransitionEffect.OPACITY.combine(TransitionEffect.scale())
```

### 示例 A: 淡入淡出

```typescript
@Component
struct FadeTransition {
  @State show: boolean = true;

  build() {
    Column() {
      if (this.show) {
        Text('淡入淡出')
          .transition(TransitionEffect.OPACITY)
      }

      Button('切换')
        .onClick(() => {
          this.show = !this.show;
        })
    }
  }
}
```

### 示例 B: 缩放转场

```typescript
@Component
struct ScaleTransition {
  @State show: boolean = true;

  build() {
    Column() {
      if (this.show) {
        Text('缩放转场')
          .transition(TransitionEffect.scale())
      }

      Button('切换')
        .onClick(() => {
          this.show = !this.show;
        })
    }
  }
}
```

### 示例 C: 滑动转场

```typescript
@Component
struct SlideTransition {
  @State show: boolean = true;

  build() {
    Column() {
      if (this.show) {
        Text('从底部滑入')
          .transition(TransitionEffect.move(Edge.Bottom))
      }

      Button('切换')
        .onClick(() => {
          this.show = !this.show;
        })
    }
  }
}
```

### 示例 D: 组合转场

```typescript
@Component
struct CombinedTransition {
  @State show: boolean = true;

  build() {
    Column() {
      if (this.show) {
        Text('组合转场')
          .transition(
            TransitionEffect.OPACITY
              .combine(TransitionEffect.scale())
              .combine(TransitionEffect.move(Edge.Bottom))
          )
      }

      Button('切换')
        .onClick(() => {
          this.show = !this.show;
        })
    }
  }
}
```

### 页面转场

```typescript
// Navigation 页面转场
HdsNavDestination() {
  // 页面内容
}
.transition(TransitionEffect.OPACITY)

// 或使用系统预设
.transition(PageTransitionEffect.custom())
```

---

## 5. 几何转场 (geometryTransition)

### 原理

两个页面/组件间的共享元素动画。

### API

```typescript
.geometryTransition(id: string, options?: { follow?: boolean })
```

### 示例

```typescript
// 页面 A
@Component
struct PageA {
  build() {
    Column() {
      Image($r('app.media.image'))
        .width(100)
        .height(100)
        .geometryTransition('sharedImage', { follow: true })
        .onClick(() => {
          // 跳转到页面 B
        })
    }
  }
}

// 页面 B
@Component
struct PageB {
  build() {
    Column() {
      Image($r('app.media.image'))
        .width('100%')
        .height(300)
        .geometryTransition('sharedImage', { follow: true })
    }
  }
}
```

---

## 6. 进度动画

### 原理

使用 `setInterval` 定时更新进度值。

### 示例 A: 自动轮播进度条

```typescript
@Component
struct AutoProgress {
  @State progress: number = 0;
  private intervalID: number = -1;
  private readonly MAX_VALUE: number = 100;
  private readonly FRAME_TIME: number = 33; // 30fps

  aboutToAppear() {
    this.startProgress();
  }

  aboutToDisappear() {
    this.stopProgress();
  }

  startProgress() {
    this.progress = 0;
    this.intervalID = setInterval(() => {
      this.progress += 1;
      if (this.progress >= this.MAX_VALUE) {
        this.stopProgress();
        // 触发下一步操作
        this.onProgressComplete();
      }
    }, this.FRAME_TIME);
  }

  stopProgress() {
    if (this.intervalID !== -1) {
      clearInterval(this.intervalID);
      this.intervalID = -1;
    }
  }

  onProgressComplete() {
    console.info('进度完成');
  }

  build() {
    Progress({
      value: this.progress,
      total: this.MAX_VALUE,
      type: ProgressType.Linear
    })
      .width('100%')
      .height(4)
  }
}
```

### 示例 B: 多段进度条 (Banner 指示器)

```typescript
@Component
struct MultiProgress {
  @State progressArray: number[] = [0, 0, 0];
  @State currentIndex: number = 0;
  private intervalID: number = -1;
  private readonly MAX_VALUE: number = 100;
  private readonly DURATION: number = 3000; // 3秒轮播
  private readonly FRAME_TIME: number = 33;

  aboutToAppear() {
    this.startAutoPlay();
  }

  aboutToDisappear() {
    clearInterval(this.intervalID);
  }

  startAutoPlay() {
    this.progressArray[this.currentIndex] = 0;
    this.intervalID = setInterval(() => {
      this.progressArray[this.currentIndex] += (this.MAX_VALUE / (this.DURATION / this.FRAME_TIME));
      if (this.progressArray[this.currentIndex] >= this.MAX_VALUE) {
        this.progressArray[this.currentIndex] = this.MAX_VALUE;
        this.currentIndex = (this.currentIndex + 1) % this.progressArray.length;
        this.progressArray[this.currentIndex] = 0;
      }
    }, this.FRAME_TIME);
  }

  build() {
    Row({ space: 4 }) {
      ForEach(this.progressArray, (value: number, index: number) => {
        Progress({
          value: value,
          total: this.MAX_VALUE,
          type: ProgressType.Linear
        })
          .width(40)
          .height(3)
          .color('#1890ff')
          .backgroundColor('#e8e8e8')
      })
    }
  }
}
```

### 示例 C: 倒计时动画

```typescript
@Component
struct Countdown {
  @State remainingTime: number = 60;
  private intervalID: number = -1;

  aboutToAppear() {
    this.startCountdown();
  }

  aboutToDisappear() {
    clearInterval(this.intervalID);
  }

  startCountdown() {
    this.remainingTime = 60;
    this.intervalID = setInterval(() => {
      this.remainingTime -= 1;
      if (this.remainingTime <= 0) {
        clearInterval(this.intervalID);
        this.onCountdownComplete();
      }
    }, 1000);
  }

  onCountdownComplete() {
    console.info('倒计时结束');
  }

  build() {
    Column() {
      Text(`${this.remainingTime}s`)
        .fontSize(48)
        .fontWeight(FontWeight.Bold)

      Progress({
        value: this.remainingTime,
        total: 60,
        type: ProgressType.Ring
      })
        .width(100)
        .height(100)
    }
  }
}
```

---

## 7. 滚动动画 (scrollTo)

### 原理

带动画的列表/滚动容器滚动。

### API

```typescript
scroller.scrollTo({
  xOffset: number,
  yOffset: number,
  animation?: {
    duration?: number,
    curve?: Curve,
  }
})
```

### 示例 A: 平滑滚动到顶部

```typescript
@Component
struct SmoothScroll {
  private scroller: Scroller = new Scroller();

  scrollToTop() {
    this.scroller.scrollTo({
      xOffset: 0,
      yOffset: 0,
      animation: {
        duration: 300,
        curve: Curve.EaseOut
      }
    });
  }

  scrollToOffset(offset: number) {
    const currentOffset = this.scroller.currentOffset().yOffset;
    this.scroller.scrollTo({
      xOffset: 0,
      yOffset: currentOffset + offset,
      animation: {
        duration: 200
      }
    });
  }

  build() {
    Column() {
      List({ scroller: this.scroller }) {
        ForEach(Array.from({ length: 50 }, (_, i) => i), (item: number) => {
          ListItem() {
            Text(`Item ${item}`)
              .height(50)
          }
        })
      }
      .height(300)

      Row({ space: 16 }) {
        Button('滚动到顶部')
          .onClick(() => this.scrollToTop())

        Button('向下滚动 200')
          .onClick(() => this.scrollToOffset(200))
      }
    }
  }
}
```

### 示例 B: 水平滚动 (Banner 翻页)

```typescript
@Component
struct HorizontalScroll {
  private scroller: Scroller = new Scroller();
  private itemWidth: number = 300;

  scrollByOffset(offset: number) {
    const currentOffset = this.scroller.currentOffset().xOffset;
    this.scroller.scrollTo({
      xOffset: currentOffset + offset,
      yOffset: 0,
      animation: {
        duration: 200
      }
    });
  }

  build() {
    Column() {
      Scroll(this.scroller) {
        Row({ space: 16 }) {
          ForEach(Array.from({ length: 5 }, (_, i) => i), (item: number) => {
            Column() {
              Text(`Banner ${item}`)
                .fontSize(20)
                .fontColor(Color.White)
            }
            .width(this.itemWidth)
            .height(200)
            .backgroundColor(['#1890ff', '#52c41a', '#faad14', '#ff4d4f', '#722ed1'][item])
            .borderRadius(12)
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)

      Row({ space: 16 }) {
        Button('上一页')
          .onClick(() => this.scrollByOffset(-this.itemWidth - 16))

        Button('下一页')
          .onClick(() => this.scrollByOffset(this.itemWidth + 16))
      }
    }
  }
}
```

---

## 8. Symbol 动态效果 (symbolEffect)

### 原理

系统图标 (SymbolGlyph) 的动态反馈效果。

### API

```typescript
import { SymbolGlyphModifier } from '@kit.ArkUI';

// 效果类型
new BounceSymbolEffect(EffectScope.LAYER, EffectDirection.UP)
new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.DOWN)
```

### 示例 A: 点击弹跳效果

```typescript
@Component
struct SymbolBounce {
  @State isActive: boolean = false;
  @State symbolEffect: BounceSymbolEffect = new BounceSymbolEffect(
    EffectScope.LAYER,
    EffectDirection.UP
  );

  build() {
    SymbolGlyph($r('sys.symbol.heart_fill'))
      .fontSize(48)
      .fontColor([this.isActive ? '#ff4d4f' : '#999999'])
      .symbolEffect(this.symbolEffect, this.isActive)
      .onClick(() => {
        this.isActive = !this.isActive;
      })
  }
}
```

### 示例 B: Tab 选中效果

```typescript
@Component
struct TabItem {
  @Prop icon: Resource;
  @Prop title: string;
  @Prop isSelected: boolean;
  @State symbolEffect: BounceSymbolEffect = new BounceSymbolEffect(
    EffectScope.LAYER,
    EffectDirection.UP
  );

  build() {
    Column() {
      SymbolGlyph(this.icon)
        .fontSize(24)
        .fontColor([this.isSelected ? '#1890ff' : '#999999'])
        .symbolEffect(this.symbolEffect, this.isSelected)

      Text(this.title)
        .fontSize(12)
        .fontColor(this.isSelected ? '#1890ff' : '#999999')
    }
  }
}
```

---

## 9. Swiper 轮播动画

### 原理

内置轮播组件，支持自动播放、循环、指示器。

### API

```typescript
Swiper(controller?: SwiperController) {
  // 内容
}
.loop(boolean)           // 循环
.autoPlay(boolean)       // 自动播放
.interval(number)        // 轮播间隔 (ms)
.indicator(boolean | Indicator) // 指示器
.displayCount(number)    // 显示数量
.itemSpace(number)       // 间距
.prevMargin(Length)      // 前边距
.nextMargin(Length)      // 后边距
.effectMode(EdgeEffect)  // 边缘效果
```

### 示例 A: 基础轮播

```typescript
@Component
struct BasicSwiper {
  private swiperController: SwiperController = new SwiperController();

  build() {
    Swiper(this.swiperController) {
      ForEach([1, 2, 3, 4], (item: number) => {
        Column() {
          Text(`Slide ${item}`)
            .fontSize(24)
            .fontColor(Color.White)
        }
        .width('100%')
        .height(200)
        .backgroundColor(['#1890ff', '#52c41a', '#faad14', '#ff4d4f'][item - 1])
        .borderRadius(12)
      })
    }
    .loop(true)
    .autoPlay(true)
    .interval(3000)
    .indicator(new DotIndicator()
      .color('#ffffff80')
      .selectedColor('#ffffff')
    )
  }
}
```

### 示例 B: 卡片式轮播

```typescript
@Component
struct CardSwiper {
  build() {
    Swiper() {
      ForEach([1, 2, 3, 4], (item: number) => {
        Column() {
          Text(`Card ${item}`)
            .fontSize(24)
        }
        .width('100%')
        .height(200)
        .backgroundColor('#f0f0f0')
        .borderRadius(16)
      })
    }
    .prevMargin(16)
    .nextMargin(16)
    .itemSpace(12)
    .displayCount(1.2) // 显示 1.2 个，露出下一个卡片边缘
    .indicator(false)
  }
}
```

### 示例 C: 多列轮播

```typescript
@Component
struct MultiColumnSwiper {
  build() {
    Swiper() {
      ForEach([1, 2, 3, 4, 5, 6], (item: number) => {
        Column() {
          Text(`Item ${item}`)
        }
        .width('100%')
        .height(100)
        .backgroundColor('#f0f0f0')
        .borderRadius(8)
      })
    }
    .displayCount(3) // 同时显示 3 个
    .itemSpace(8)
    .indicator(new DotIndicator())
  }
}
```

---

## 10. 标题栏滚动效果 (ScrollEffect)

### 原理

滚动时标题栏渐变模糊、颜色变化。

### API

```typescript
// HdsNavigation 标题栏样式
TitleBarStyleOptions = {
  originalStyle: { ... },      // 原始样式
  scrollEffectStyle: { ... },  // 滚动后样式
  scrollEffectOpts: {
    enableScrollEffect: true,
    scrollEffectType: ScrollEffectType,
    blurEffectiveStartOffset: LengthMetrics,
    blurEffectiveEndOffset: LengthMetrics,
  }
}
```

### 示例

```typescript
import { ScrollEffectType, hdsMaterial } from '@kit.UIDesignKit';

@Component
struct ScrollEffectTitle {
  @State titleBarStyle: TitleBarStyleOptions = {};

  aboutToAppear() {
    this.setTitleBarStyle();
  }

  setTitleBarStyle() {
    this.titleBarStyle = {
      originalStyle: {
        contentStyle: {
          titleStyle: {
            mainTitleColor: '#ffffff', // 原始白色文字
          },
        },
      },
      scrollEffectStyle: {
        contentStyle: {
          titleStyle: {
            mainTitleColor: '#000000', // 滚动后黑色文字
          },
        },
      },
      scrollEffectOpts: {
        enableScrollEffect: true,
        scrollEffectType: ScrollEffectType.COMMON_BLUR,
        blurEffectiveStartOffset: LengthMetrics.vp(200),
        blurEffectiveEndOffset: LengthMetrics.vp(300),
      },
    };
  }

  build() {
    Navigation(this.navPathStack) {
      // 内容
    }
    .titleBar({
      avoidLayoutSafeArea: true,
      style: this.titleBarStyle,
      content: {
        title: { mainTitle: '标题' },
      }
    })
  }
}
```

---

## 11. 标签栏显示/隐藏动画

### 原理

滚动时底部标签栏自动显示/隐藏。

### API

```typescript
import { HdsTabsController, HdsAnimationMode } from '@kit.UIDesignKit';

// 隐藏动画
tabsController.applyHideAnimation(HdsAnimationMode.SCROLL_ANIMATION);

// 显示动画
tabsController.applyShowAnimation(HdsAnimationMode.SCROLL_ANIMATION);
```

### 示例

```typescript
@Component
struct TabBarAnimation {
  private tabsController: HdsTabsController = new HdsTabsController();
  private isScrollUp: boolean = false;

  handleScroll(yOffset: number) {
    if (yOffset > 0 && !this.isScrollUp) {
      this.isScrollUp = true;
      this.tabsController.applyHideAnimation(HdsAnimationMode.SCROLL_ANIMATION);
    } else if (yOffset < 0 && this.isScrollUp) {
      this.isScrollUp = false;
      this.tabsController.applyShowAnimation(HdsAnimationMode.SCROLL_ANIMATION);
    }
  }

  build() {
    Tabs({ controller: this.tabsController }) {
      TabContent() {
        List() {
          ForEach(Array.from({ length: 50 }, (_, i) => i), (item: number) => {
            ListItem() {
              Text(`Item ${item}`)
            }
          })
        }
        .onDidScroll((xOffset: number, yOffset: number) => {
          this.handleScroll(yOffset);
        })
      }
    }
  }
}
```

---

## 最佳实践

### 1. 动画时长选择

```typescript
// 微交互 (按钮、开关)
duration: 100-200ms

// 一般过渡 (展开、收起)
duration: 200-300ms

// 复杂动画 (页面转场)
duration: 300-500ms

// 弹簧动画
duration: 250ms (由曲线控制)
```

### 2. 曲线选择

```typescript
// 一般过渡
Curve.EaseInOut

// 元素进入
Curve.EaseOut

// 元素离开
Curve.EaseIn

// 弹性效果
curves.interpolatingSpring(0, 1, 288, 30)

// 快速响应
Curve.Sharp
```

### 3. 性能优化

```typescript
// 使用 .animation() 替代 animateTo() (简单场景)
.width(this.isExpanded ? 200 : 100)
.animation({ duration: 200 })

// 避免同时动画过多属性
// 使用 will-change 提示浏览器
```

### 4. 组合动画

```typescript
// 多个属性同时动画
this.getUIContext().animateTo(
  { duration: 300, curve: Curve.EaseInOut },
  () => {
    this.width = 200;
    this.height = 200;
    this.opacity = 0.8;
    this.backgroundColor = '#52c41a';
  }
);
```

---

## 常见问题

### Q1: 如何实现循环动画？

```typescript
animation({
  duration: 1000,
  iterations: -1, // -1 表示无限循环
  curve: Curve.Linear
})
```

### Q2: 如何实现反向动画？

```typescript
animation({
  duration: 300,
  playMode: PlayMode.Reverse // 反向播放
})
```

### Q3: 如何实现延迟动画？

```typescript
animation({
  duration: 300,
  delay: 500 // 延迟 500ms
})
```

### Q4: 如何监听动画完成？

```typescript
this.getUIContext().animateTo(
  {
    duration: 300,
    onFinish: () => {
      console.info('动画完成');
    }
  },
  () => {
    this.isActive = true;
  }
);
```

---

## 参考资源

- [HarmonyOS 动画开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/)
- [ArkUI 动画 API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/)
- [curves 曲线 API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/)
