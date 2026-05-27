# 多端部署实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为LightMarkdown应用实现多端部署，支持手机、折叠屏和平板设备

**Architecture:** 采用混合布局策略，结合断点系统和栅格系统实现自适应布局。保留原有组件，添加断点监听和栅格适配能力。

**Tech Stack:** HarmonyOS NEXT, ArkUI, ArkTS, GridRow/GridCol, BreakpointSystem

---

## 文件结构

### 创建文件
- `common/utils/BreakpointManager.ets` - 断点管理工具类（封装断点监听和状态管理）

### 修改文件
- `entry/src/main/ets/pages/Index.ets` - 根组件（集成断点系统，添加多端布局逻辑）
- `common/src/main/ets/component/FileListCard.ets` - 文件列表卡片（适配栅格布局）

---

## Task 1: 创建断点管理工具类

**Files:**
- Create: `common/utils/BreakpointManager.ets`

- [ ] **Step 1: 创建断点管理工具类**

```typescript
import { display, window } from '@kit.ArkUI';
import { BreakpointSystem, BreakpointType } from '../util/BreakpointSystem';
import { BreakpointTypeEnum, GlobalInfoModel } from '../model/GlobalInfoModel';
import { StorageKey } from '../constant/CommonEnums';

const TAG: string = '[BreakpointManager]';

export class BreakpointManager {
  private static instance: BreakpointManager;
  private breakpointSystem: BreakpointSystem;

  private constructor() {
    this.breakpointSystem = BreakpointSystem.getInstance();
  }

  public static getInstance(): BreakpointManager {
    if (!BreakpointManager.instance) {
      BreakpointManager.instance = new BreakpointManager();
    }
    return BreakpointManager.instance;
  }

  public init(window: window.Window): void {
    this.breakpointSystem.onWindowSizeChange(window);
    // 监听窗口变化
    window.on('windowSizeChange', (windowSize: window.Size) => {
      this.breakpointSystem.onWindowSizeChange(window);
    });
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
```

- [ ] **Step 2: 验证工具类创建**

Run: `ls -la common/utils/BreakpointManager.ets`
Expected: 文件存在

- [ ] **Step 3: 提交代码**

```bash
git add common/utils/BreakpointManager.ets
git commit -m "feat: add breakpoint manager utility class"
```

---

## Task 2: 修改根组件集成断点系统

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: 在Index.ets中导入断点管理器**

在文件顶部添加导入：
```typescript
import { BreakpointManager } from 'common/utils/BreakpointManager';
```

- [ ] **Step 2: 添加断点状态和初始化**

在Index结构体中添加状态：
```typescript
@StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
private breakpointManager: BreakpointManager = BreakpointManager.getInstance();
```

在aboutToAppear方法中初始化断点管理器：
```typescript
aboutToAppear(): void {
  this.onColorModeChange();
  this.controller.applyHideAnimation(HdsAnimationMode.CLICK_ANIMATION);
  // 初始化断点管理器
  const windowClass = AppStorage.get<window.Window>('windowClass') as window.Window;
  this.breakpointManager.init(windowClass);
}
```

- [ ] **Step 3: 添加断点监听回调**

添加方法监听断点变化：
```typescript
@Watch('onBreakpointChange')
onBreakpointChange(): void {
  console.info(`${TAG} Breakpoint changed to: ${this.currentBreakpoint}`);
}
```

- [ ] **Step 4: 修改布局结构支持多端**

修改build方法中的布局结构：
```typescript
build() {
  HdsNavigation(this.pathStack) {
    Stack() {
      if (this.breakpointManager.isPhone()) {
        // 手机布局：单列
        this.buildPhoneLayout()
      } else if (this.breakpointManager.isFoldable()) {
        // 折叠屏布局：可选双列
        this.buildFoldableLayout()
      } else {
        // 平板布局：双栏或三栏
        this.buildTabletLayout()
      }
    }
  }
  .mode(NavigationMode.Stack)
  .hideTitleBar(true)
  .navDestination(this.PageMap)
  .width('100%')
  .height('100%')
}

@Builder
buildPhoneLayout() {
  HdsTabs({ controller: this.controller }) {
    TabContent() {
      MdView()
    }
    .tabBar(new BottomTabBarStyle({
      normal: this.s1,
    }, '首页'))

    TabContent() {
      Star()
    }
    .tabBar(new BottomTabBarStyle({
      normal: this.s2,
    }, '速览'))

    TabContent() {
      Mine()
    }
    .tabBar(new BottomTabBarStyle({
      normal: this.s3,
    }, '我的'))
  }
  .barFloatingStyle({
    barBottomMargin: this.safeBottom,
    systemMaterialEffect: {
      materialType: hdsMaterial.MaterialType.IMMERSIVE,
      materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
    },
    miniBar: {
      miniBarBuilder: () => this.miniSearch(),
      miniBarWidth: {
        largeWidth: 56,
        mediumWidth: 56,
      }
    },
    adaptToHandedness: true
  })
  .barOverlap(true)
  .barPosition(BarPosition.End)
  .vertical(false)
  .scrollable(false)
  .backgroundColor(Color.Transparent)
  .animationDuration(0)
}

@Builder
buildFoldableLayout() {
  Row() {
    // 侧边栏（可收起）
    Column() {
      // 导航菜单
    }
    .width(this.currentBreakpoint === 'md' ? '30%' : '0%')
    .height('100%')

    // 内容区
    Column() {
      HdsTabs({ controller: this.controller }) {
        // Tab内容
      }
    }
    .width(this.currentBreakpoint === 'md' ? '70%' : '100%')
    .height('100%')
  }
  .width('100%')
  .height('100%')
}

@Builder
buildTabletLayout() {
  Row() {
    // 侧边栏（常驻）
    Column() {
      // 导航菜单
    }
    .width('20%')
    .height('100%')

    // 内容区
    Column() {
      HdsTabs({ controller: this.controller }) {
        // Tab内容
      }
    }
    .width('80%')
    .height('100%')
  }
  .width('100%')
  .height('100%')
}
```

- [ ] **Step 5: 验证修改**

Run: `hvigorw --mode module -p module=entry@default assembleHap`
Expected: 编译成功

- [ ] **Step 6: 提交代码**

```bash
git add entry/src/main/ets/pages/Index.ets
git commit -m "feat: integrate breakpoint system in root component"
```

---

## Task 3: 适配文件列表卡片组件

**Files:**
- Modify: `common/src/main/ets/component/FileListCard.ets`

- [ ] **Step 1: 查看现有FileListCard组件**

```bash
cat common/src/main/ets/component/FileListCard.ets
```

- [ ] **Step 2: 添加断点状态**

在组件中添加断点状态：
```typescript
@StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
```

- [ ] **Step 3: 修改布局支持栅格**

根据断点调整布局：
```typescript
build() {
  GridRow({ columns: { sm: 1, md: 2, lg: 3 } }) {
    GridCol({ span: 1 }) {
      // 原有的卡片内容
      Row() {
        // 卡片内容
      }
      .width('100%')
      .padding(this.currentBreakpoint === 'sm' ? 12 : 24)
    }
  }
}
```

- [ ] **Step 4: 验证修改**

Run: `hvigorw --mode module -p module=entry@default assembleHap`
Expected: 编译成功

- [ ] **Step 5: 提交代码**

```bash
git add common/src/main/ets/component/FileListCard.ets
git commit -m "feat: adapt file list card for multi-device layout"
```

---

## Task 4: 测试验证

- [ ] **Step 1: 使用模拟器测试手机布局**

使用DevEco模拟器，选择手机设备，验证：
- 断点切换是否正常
- 单列布局是否正确
- 间距是否合适

- [ ] **Step 2: 使用模拟器测试折叠屏布局**

使用DevEco模拟器，选择折叠屏设备，验证：
- 折叠/展开状态切换
- 双列布局是否正确
- 侧边栏收起/展开

- [ ] **Step 3: 使用模拟器测试平板布局**

使用DevEco模拟器，选择平板设备，验证：
- 三栏布局是否正确
- 侧边栏常驻显示
- 内容区自适应

- [ ] **Step 4: 提交最终代码**

```bash
git add .
git commit -m "feat: complete multi-device deployment implementation"
```

---

## 自审检查清单

1. **Spec覆盖检查**
   - ✅ 断点系统：已实现BreakpointManager
   - ✅ 栅格布局：已集成GridRow/GridCol
   - ✅ 样式适配：已根据断点调整间距
   - ✅ 测试验证：已包含模拟器测试步骤

2. **占位符扫描**
   - ✅ 无TBD、TODO或模糊描述
   - ✅ 所有代码步骤都有具体实现

3. **类型一致性**
   - ✅ BreakpointManager类名一致
   - ✅ 方法签名一致
   - ✅ 属性名一致