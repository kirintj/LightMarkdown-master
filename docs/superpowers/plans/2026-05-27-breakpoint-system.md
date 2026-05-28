# 断点系统适配实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 LightMarkdown 添加 HarmonyOS 断点系统，实现多端设备响应式布局适配

**Architecture:** 三层架构：UI 组件层通过 @StorageProp 读取断点状态 → 全局状态层 (AppStorage) 存储 GlobalInfoModel → 窗口监听层 (WindowUtil) 监听系统断点变化

**Tech Stack:** HarmonyOS ArkUI, AppStorage, @StorageProp, @Observed, window API

---

## 文件结构

### 新增文件
- `common/src/main/ets/util/BreakpointSystem.ets` — 断点类型系统（BreakpointType 类）
- `common/src/main/ets/util/WindowUtil.ets` — 窗口工具类（初始化、断点监听）

### 修改文件
- `common/src/main/ets/model/GlobalInfoModel.ets` — 扩展断点属性
- `common/Index.ets` — 导出新模块
- `entry/src/main/ets/entryability/EntryAbility.ets` — 初始化断点监听
- `feature/markdown/src/main/ets/page/MdView.ets` — 响应式布局改造
- `feature/markdown/src/main/ets/page/MarkdownViewerPage.ets` — 响应式布局改造
- `feature/mine/src/main/ets/page/Mine.ets` — 响应式布局改造
- `feature/star/src/main/ets/page/StarredPage.ets` — 响应式布局改造
- `feature/star/src/main/ets/page/RecentPage.ets` — 响应式布局改造
- `feature/star/src/main/ets/page/GroupDetailPage.ets` — 响应式布局改造
- `feature/star/src/main/ets/page/GroupListPage.ets` — 响应式布局改造

---

## Task 1: 创建 BreakpointSystem.ets

**Files:**
- Create: `common/src/main/ets/util/BreakpointSystem.ets`

- [ ] **Step 1: 创建断点类型系统文件**

```typescript
// common/src/main/ets/util/BreakpointSystem.ets

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
```

---

## Task 2: 扩展 GlobalInfoModel.ets

**Files:**
- Modify: `common/src/main/ets/model/GlobalInfoModel.ets`

- [ ] **Step 1: 添加断点属性和存储键**

```typescript
// common/src/main/ets/model/GlobalInfoModel.ets

/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

// AppStorage 存储键
export const StorageKey = {
  GLOBAL_INFO: 'hmos_world_GlobalInfoModel',
  UI_CONTEXT: 'hmos_world_UIContext',
};
```

---

## Task 3: 创建 WindowUtil.ets

**Files:**
- Create: `common/src/main/ets/util/WindowUtil.ets`

- [ ] **Step 1: 创建窗口工具类**

```typescript
// common/src/main/ets/util/WindowUtil.ets

import { window } from '@kit.ArkUI';
import { GlobalInfoModel, StorageKey } from '../model/GlobalInfoModel';

const ASPECT_SQUARE_PORTRAIT: number = 9 / 10.8;
const ASPECT_LANDSCAPE_SQUARE: number = 10.8 / 9;

export class WindowUtil {
  private static windowClass?: window.Window;
  private static uiContext: UIContext;

  // 初始化入口
  public static initialize(windowStage: window.WindowStage) {
    WindowUtil.windowClass = windowStage.getMainWindowSync();
    WindowUtil.uiContext = WindowUtil.windowClass.getUIContext();

    // 存储 UIContext
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
```

---

## Task 4: 更新 common/Index.ets 导出

**Files:**
- Modify: `common/Index.ets`

- [ ] **Step 1: 添加新模块导出**

```typescript
// common/Index.ets

export { CardItem } from './src/main/ets/component/CardItem'

export { Storage } from './src/main/ets/model/Global'

export { BindSheetHDS } from './src/main/ets/component/BindSheetHDS'

export { formatRelativeTime } from './src/main/ets/util/TimeUtil'

export { EmptyState } from './src/main/ets/component/EmptyState'

export { showDeleteConfirm } from './src/main/ets/component/DeleteConfirmDialog'

export { SearchBar } from './src/main/ets/component/SearchBar'

export { FileListCard } from './src/main/ets/component/FileListCard'

export { GroupSheetContent, GroupItem } from './src/main/ets/component/GroupSheetContent'

// 断点系统
export { BreakpointType, BreakpointTypes } from './src/main/ets/util/BreakpointSystem'

export { WindowUtil } from './src/main/ets/util/WindowUtil'

export { GlobalInfoModel, StorageKey } from './src/main/ets/model/GlobalInfoModel'
```

---

## Task 5: 改造 EntryAbility.ets

**Files:**
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`

- [ ] **Step 1: 集成 WindowUtil 初始化**

```typescript
// entry/src/main/ets/entryability/EntryAbility.ets

import { Configuration, ConfigurationConstant, UIAbility } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageV2, window } from '@kit.ArkUI';
import { WindowUtil, GlobalInfoModel, StorageKey } from '@ohos/common';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {

  onCreate(): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    AppStorage.setOrCreate<ConfigurationConstant.ColorMode>('currentColorMode', this.context.config.colorMode);

    // 初始化 GlobalInfoModel
    AppStorage.setOrCreate<GlobalInfoModel>(StorageKey.GLOBAL_INFO, new GlobalInfoModel());

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {

    try {
      // 初始化窗口工具（含断点监听）
      WindowUtil.initialize(windowStage);

      let windowClass: window.Window = windowStage.getMainWindowSync();
      windowClass.setWindowLayoutFullScreen(true).catch(() => {
        // TODO: Implement error handling.
      });

      // 保留现有安全区域逻辑（兼容旧代码）
      let topRectHeight = windowClass
        .getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
        .topRect.height;
      let bottomRectHeight = windowClass
        .getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
        .bottomRect.height;
      AppStorage.setOrCreate('safeTop', px2vp(topRectHeight));
      AppStorage.setOrCreate('safeBottom', px2vp(bottomRectHeight));
      AppStorage.setOrCreate('windowClass', windowClass);
      windowClass.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          AppStorage.setOrCreate('safeTop', px2vp(data.area.topRect.height));
        } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          AppStorage.setOrCreate('safeBottom', px2vp(data.area.bottomRect.height));
        }
      });
    } catch (error) {
    }
    // 1. 开启窗口全屏沉浸式
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    let newColorMode = newConfig.colorMode;
    let currentColorMode = AppStorage.get<ConfigurationConstant.ColorMode>('currentColorMode');
    if (newColorMode === currentColorMode) {
      return;
    }
    // 更新缓存中的颜色模式
    AppStorage.setOrCreate('currentColorMode', newConfig.colorMode);
  }
  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
```

---

## Task 6: 改造 MdView.ets

**Files:**
- Modify: `feature/markdown/src/main/ets/page/MdView.ets`

- [ ] **Step 1: 添加断点状态和类型导入**

在文件顶部添加导入：
```typescript
import { BreakpointType, GlobalInfoModel, StorageKey } from 'common';
```

在 MdView 组件内添加断点状态：
```typescript
@StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
  AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
```

- [ ] **Step 2: 改造网格列数响应式**

将固定的 `columns: 2` 改为响应式：
```typescript
GridRow({
  columns: new BreakpointType({
    sm: 2,
    md: 3,
    lg: 4,
  }).getValue(this.globalInfoModel.widthBreakpoint),
  gutter: { x: 12, y: 12 }
})
```

- [ ] **Step 3: 改造列表间距响应式**

将固定的 `space: 12` 改为响应式：
```typescript
List({
  space: new BreakpointType({
    sm: 12,
    md: 16,
    lg: 20,
  }).getValue(this.globalInfoModel.widthBreakpoint)
})
```

- [ ] **Step 4: 改造内边距响应式**

将固定的 `padding({ left: 16, right: 16 })` 改为响应式：
```typescript
.padding(new BreakpointType<Padding>({
  sm: { left: 16, right: 16 },
  md: { left: 24, right: 24 },
  lg: { left: 32, right: 32 },
}).getValue(this.globalInfoModel.widthBreakpoint))
```

---

## Task 7: 改造 MarkdownViewerPage.ets

**Files:**
- Modify: `feature/markdown/src/main/ets/page/MarkdownViewerPage.ets`

- [ ] **Step 1: 添加断点状态和类型导入**

在文件顶部添加导入：
```typescript
import { BreakpointType, GlobalInfoModel, StorageKey } from 'common';
```

在 MarkdownViewerPage 组件内添加断点状态：
```typescript
@StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
  AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
```

- [ ] **Step 2: 改造内容区宽度响应式**

将固定的 `.width('100%')` 改为响应式（大屏居中限制宽度）：
```typescript
Markdown({ ... })
  .width(new BreakpointType<Length>({
    sm: '100%',
    md: '100%',
    lg: '80%',
  }).getValue(this.globalInfoModel.widthBreakpoint))
```

- [ ] **Step 3: 改造内边距响应式**

```typescript
.padding(new BreakpointType<Padding>({
  sm: { left: 16, right: 16, top: 16, bottom: 16 },
  md: { left: 24, right: 24, top: 20, bottom: 20 },
  lg: { left: 32, right: 32, top: 24, bottom: 24 },
}).getValue(this.globalInfoModel.widthBreakpoint))
```

---

## Task 8: 改造 Mine.ets

**Files:**
- Modify: `feature/mine/src/main/ets/page/Mine.ets`

- [ ] **Step 1: 添加断点状态和类型导入**

在文件顶部添加导入：
```typescript
import { BreakpointType, GlobalInfoModel, StorageKey } from 'common';
```

在 Mine 组件内添加断点状态：
```typescript
@StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
  AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
```

- [ ] **Step 2: 改造设置列表宽度响应式**

将固定的 `.width('100%')` 改为响应式（大屏居中限制宽度）：
```typescript
Column() {
  // ... 内容
}
.width(new BreakpointType<Length>({
  sm: '100%',
  md: '100%',
  lg: '60%',
}).getValue(this.globalInfoModel.widthBreakpoint))
```

- [ ] **Step 3: 改造内边距响应式**

```typescript
.padding(new BreakpointType<Padding>({
  sm: { left: 16, right: 16 },
  md: { left: 24, right: 24 },
  lg: { left: 32, right: 32 },
}).getValue(this.globalInfoModel.widthBreakpoint))
```

---

## Task 9: 改造 StarredPage.ets

**Files:**
- Modify: `feature/star/src/main/ets/page/StarredPage.ets`

- [ ] **Step 1: 添加断点状态和类型导入**

在文件顶部添加导入：
```typescript
import { BreakpointType, GlobalInfoModel, StorageKey } from 'common';
```

在 StarredPage 组件内添加断点状态：
```typescript
@StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
  AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
```

- [ ] **Step 2: 改造列表间距响应式**

```typescript
List({
  space: new BreakpointType({
    sm: 12,
    md: 16,
    lg: 20,
  }).getValue(this.globalInfoModel.widthBreakpoint)
})
```

- [ ] **Step 3: 改造内边距响应式**

```typescript
.padding(new BreakpointType<Padding>({
  sm: { left: 16, right: 16 },
  md: { left: 24, right: 24 },
  lg: { left: 32, right: 32 },
}).getValue(this.globalInfoModel.widthBreakpoint))
```

---

## Task 10: 改造 RecentPage.ets

**Files:**
- Modify: `feature/star/src/main/ets/page/RecentPage.ets`

- [ ] **Step 1: 添加断点状态和类型导入**

在文件顶部添加导入：
```typescript
import { BreakpointType, GlobalInfoModel, StorageKey } from 'common';
```

在 RecentPage 组件内添加断点状态：
```typescript
@StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
  AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
```

- [ ] **Step 2: 改造列表间距响应式**

```typescript
List({
  space: new BreakpointType({
    sm: 12,
    md: 16,
    lg: 20,
  }).getValue(this.globalInfoModel.widthBreakpoint)
})
```

- [ ] **Step 3: 改造内边距响应式**

```typescript
.padding(new BreakpointType<Padding>({
  sm: { left: 16, right: 16 },
  md: { left: 24, right: 24 },
  lg: { left: 32, right: 32 },
}).getValue(this.globalInfoModel.widthBreakpoint))
```

---

## Task 11: 改造 GroupDetailPage.ets

**Files:**
- Modify: `feature/star/src/main/ets/page/GroupDetailPage.ets`

- [ ] **Step 1: 添加断点状态和类型导入**

在文件顶部添加导入：
```typescript
import { BreakpointType, GlobalInfoModel, StorageKey } from 'common';
```

在 GroupDetailPage 组件内添加断点状态：
```typescript
@StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
  AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
```

- [ ] **Step 2: 改造列表间距响应式**

```typescript
List({
  space: new BreakpointType({
    sm: 12,
    md: 16,
    lg: 20,
  }).getValue(this.globalInfoModel.widthBreakpoint)
})
```

- [ ] **Step 3: 改造内边距响应式**

```typescript
.padding(new BreakpointType<Padding>({
  sm: { left: 16, right: 16 },
  md: { left: 24, right: 24 },
  lg: { left: 32, right: 32 },
}).getValue(this.globalInfoModel.widthBreakpoint))
```

---

## Task 12: 改造 GroupListPage.ets

**Files:**
- Modify: `feature/star/src/main/ets/page/GroupListPage.ets`

- [ ] **Step 1: 添加断点状态和类型导入**

在文件顶部添加导入：
```typescript
import { BreakpointType, GlobalInfoModel, StorageKey } from 'common';
```

在 GroupListPage 组件内添加断点状态：
```typescript
@StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
  AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
```

- [ ] **Step 2: 改造列表间距响应式**

```typescript
List({
  space: new BreakpointType({
    sm: 12,
    md: 16,
    lg: 20,
  }).getValue(this.globalInfoModel.widthBreakpoint)
})
```

- [ ] **Step 3: 改造内边距响应式**

```typescript
.padding(new BreakpointType<Padding>({
  sm: { left: 16, right: 16 },
  md: { left: 24, right: 24 },
  lg: { left: 32, right: 32 },
}).getValue(this.globalInfoModel.widthBreakpoint))
```

---

## 验证清单

- [ ] 构建通过：`hvigorw assembleHap` 无错误
- [ ] 手机竖屏（SM）：布局正常，单列显示
- [ ] 手机横屏（MD）：布局自适应，间距增大
- [ ] 平板（LG）：侧边栏/多列布局生效
- [ ] 折叠屏展开/折叠：断点切换流畅，无闪烁
- [ ] 性能：滑动流畅，无卡顿
