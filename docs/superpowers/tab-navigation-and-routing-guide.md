# HarmonyOS Tab 导航与路由跳转实现指南

本文档基于 sample_in_harmonyos 项目，总结了一套可复用的 Tab 导航 + 页面路由跳转方案。适用于 ArkTS / HarmonyOS NEXT 应用开发。

---

## 一、整体架构

```
┌─────────────────────────────────────────────────────────┐
│                      EntryAbility                       │
│   创建多个 PageContext 实例存入 AppStorage               │
└────────────────────────┬────────────────────────────────┘
                         │ loadContent
                         ▼
┌─────────────────────────────────────────────────────────┐
│                     MainPage (根页面)                    │
│  ┌──────────────────────────────────────────────────┐   │
│  │  HdsSideBar (XL 断点显示侧边栏)                   │   │
│  │  ┌────────────────────────────────────────────┐  │   │
│  │  │  HdsTabs (底部 Tab 容器)                    │  │   │
│  │  │  ┌──────────┬──────────┬─────────┬────────┐│  │   │
│  │  │  │ Tab 0    │ Tab 1    │ Tab 2   │ Tab 3  ││  │   │
│  │  │  │ 组件库   │ 示例     │ 实践    │ 我的   ││  │   │
│  │  │  │HdsNav   │HdsNav   │HdsNav  │HdsNav  ││  │   │
│  │  │  │  Stack   │  Stack   │  Stack  │  Stack ││  │   │
│  │  │  └──────────┴──────────┴─────────┴────────┘│  │   │
│  │  └────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

核心思路：**每个 Tab 拥有独立的 NavPathStack**，Tab 内页面跳转互不干扰。Tab 切换由 `HdsTabs` 控制，页面跳转由 `NavPathStack` 控制。

---

## 二、Tab 导航实现

### 2.1 定义 Tab 类型枚举

```typescript
// TabBarType.ets
export enum TabBarType {
  HOME = 0,
  SAMPLE = 1,
  PRACTICE = 2,
  MINE = 3,
}
```

### 2.2 定义 Tab 数据模型

```typescript
// TabBarModel.ets
import { TabBarType } from '@ohos/commonbusiness';

export interface TabBarData {
  id: TabBarType;
  title: ResourceStr;
  icon: Resource;
}

export const TABS_LIST: TabBarData[] = [
  { id: TabBarType.HOME,     icon: $r('sys.symbol.archivebox_fill'),            title: $r('app.string.tab_home') },
  { id: TabBarType.SAMPLE,   icon: $r('sys.symbol.scenes'),                     title: $r('app.string.tab_sample') },
  { id: TabBarType.PRACTICE, icon: $r('sys.symbol.discover_fill'),              title: $r('app.string.tab_practice') },
  { id: TabBarType.MINE,     icon: $r('sys.symbol.person_crop_circle_fill_1'),  title: $r('app.string.tab_mine') },
];
```

### 2.3 Tab 内容状态数组（用于状态栏适配）

```typescript
// TabStatusBarModel.ets
// 每个 Tab 内容页是否需要深色状态栏
export const TAB_CONTENT_STATUSES: boolean[] = [true, true, true, false];
```

### 2.4 MainPage 核心结构

```typescript
// MainPage.ets
@Component({ freezeWhenInactive: true })
struct MainPage {
  @State currentIndex: number = 0;
  private tabController: HdsTabsController = new HdsTabsController();
  // 每个 Tab 的 Scroller，用于绑定到 tabController
  private componentScroller: Scroller = new Scroller();
  private sampleScroller: Scroller = new Scroller();
  private articleScroller: Scroller = new Scroller();
  private mineScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    // 绑定 Scroller 到 Tab，实现滚动联动
    this.tabController.bindScroller(TabBarType.HOME, this.componentScroller);
    this.tabController.bindScroller(TabBarType.SAMPLE, this.sampleScroller);
    this.tabController.bindScroller(TabBarType.PRACTICE, this.articleScroller);
    this.tabController.bindScroller(TabBarType.MINE, this.mineScroller);
  }

  @Builder
  TabContentsBuilder(showTabBar: boolean) {
    TabContent() {
      ComponentHomeView({ scroller: this.componentScroller, homeTabController: this.tabController })
    }.tabBar(showTabBar ? this.bottomTabBarStyle(TabBarType.HOME) : new SubTabBarStyle(''))

    TabContent() {
      PracticeHomeView({ scroller: this.sampleScroller, homeTabController: this.tabController })
    }.tabBar(showTabBar ? this.bottomTabBarStyle(TabBarType.SAMPLE) : new SubTabBarStyle(''))

    TabContent() {
      ExplorationHomeView({ scroller: this.articleScroller, homeTabController: this.tabController })
    }.tabBar(showTabBar ? this.bottomTabBarStyle(TabBarType.PRACTICE) : new SubTabBarStyle(''))

    TabContent() {
      MineHomeView({ scroller: this.mineScroller, homeTabController: this.tabController })
    }.tabBar(showTabBar ? this.bottomTabBarStyle(TabBarType.MINE) : new SubTabBarStyle(''))
  }

  @Builder
  HdsTabComponent() {
    HdsTabs({ controller: this.tabController, index: this.currentIndex }) {
      this.TabContentsBuilder(/* 根据断点决定是否显示 tabBar */)
    }
    .onChange((index: number) => {
      this.changeTabStatus(index);
    })
  }

  build() {
    HdsNavDestination() {
      // XL 断点使用侧边栏，其他使用底部 Tab
      HdsSideBar({
        isShowSideBar: this.globalInfoModel.widthBreakpoint === WidthBreakpoint.WIDTH_XL,
        sideBarPanelBuilder: () => { this.CustomSideBarBuilder() },
        contentPanelBuilder: () => { this.HdsTabComponent() },
      })
    }
  }
}
```

### 2.5 响应式 Tab 切换（断点适配）

| 断点 | Tab 位置 | 形态 |
|------|---------|------|
| sm / md | 底部 | 标准底部 TabBar |
| lg | 左侧 | 垂直侧边 Tab |
| xl | 左侧侧边栏 | 独立 Sidebar 组件 |

通过 `BreakpointType` 工具类实现：

```typescript
new BreakpointType<Length>({
  sm: CommonConstants.TAB_BAR_HEIGHT,
  md: CommonConstants.TAB_BAR_HEIGHT,
  lg: '100%',
  xl: 0,  // XL 不显示 TabBar，用 Sidebar 替代
}).getValue(this.globalInfoModel.widthBreakpoint)
```

---

## 三、路由跳转实现

### 3.1 路由注册（router_map.json）

每个 feature 模块在 `src/main/resources/base/profile/router_map.json` 中注册页面：

```json
{
  "routerMap": [
    {
      "name": "ComponentListView",
      "pageSourceFile": "src/main/ets/view/ComponentListView.ets",
      "buildFunction": "ComponentListBuilder"
    },
    {
      "name": "ComponentDetailView",
      "pageSourceFile": "src/main/ets/view/ComponentDetailView.ets",
      "buildFunction": "ComponentDetailBuilder"
    }
  ]
}
```

对应页面文件需要导出 `@Builder` 函数：

```typescript
// ComponentListView.ets
@Component
struct ComponentListView {
  build() {
    HdsNavDestination() {
      // 页面内容
    }
  }
}

@Builder
export function ComponentListBuilder() {
  ComponentListView()
}
```

### 3.2 PageEnum 路由名常量

```typescript
// PageEnum.ets
export enum PageEnum {
  MAIN_PAGE = 'MainPage',
  COMPONENT_LIST_VIEW = 'ComponentListView',
  COMPONENT_DETAIL_VIEW = 'ComponentDetailView',
  SAMPLE_DETAIL_VIEW = 'SampleDetailView',
  ARTICLE_DETAIL_VIEW = 'ArticleDetailView',
  BANNER_DETAIL_VIEW = 'BannerDetailView',
  CODE_PREVIEW_VIEW = 'CodePreviewView',
  MINE_VIEW = 'MineView',
  // ... 按需扩展
}
```

### 3.3 PageContext 封装（核心）

将 `NavPathStack` 封装为 `PageContext`，统一管理页面跳转：

```typescript
// PageContext.ets
export interface RouterParam {
  routerName: PageEnum;
  param?: object;
}

export class PageContext {
  private readonly pathStack: NavPathStack;

  constructor() {
    this.pathStack = new NavPathStack();
  }

  get navPathStack(): NavPathStack {
    return this.pathStack;
  }

  // 跳转到新页面
  openPage(data: RouterParam, animated: boolean = true): void {
    this.pathStack.pushPath({
      name: data.routerName,
      param: data.param,
    }, animated);
  }

  // 返回上一页
  popPage(animated: boolean = true): void {
    this.pathStack.pop(animated);
  }

  // 替换当前页面
  replacePage(data: RouterParam, animated: boolean = true): void {
    this.pathStack.replacePath({
      name: data.routerName,
      param: data.param,
    }, animated);
  }

  // 返回到指定索引
  popPageByIndex(index: number, animated: boolean = true): void {
    this.pathStack.popToIndex(index, animated);
  }

  // 清空导航栈
  clear(animated: boolean = true): void {
    this.pathStack.clear(animated);
  }
}
```

### 3.4 多 PageContext 实例（每个 Tab 独立栈）

在 `EntryAbility` 中创建多个 `PageContext`，存入 `AppStorage`：

```typescript
// EntryAbility.ets
onWindowStageCreate(windowStage: window.WindowStage): void {
  AppStorage.setOrCreate(StorageKey.HOME_PAGE_CONTEXT, new PageContext());
  AppStorage.setOrCreate(StorageKey.SAMPLE_PAGE_CONTEXT, new PageContext());
  AppStorage.setOrCreate(StorageKey.COMPONENT_PAGE_CONTEXT, new PageContext());
  AppStorage.setOrCreate(StorageKey.EXPLORATION_PAGE_CONTEXT, new PageContext());
  AppStorage.setOrCreate(StorageKey.MINE_PAGE_CONTEXT, new PageContext());
  // ...
}
```

每个 Tab 的 HomeView 绑定对应的 `PageContext`：

```typescript
// ComponentHomeView.ets
@Component
export struct ComponentHomeView {
  @StorageLink(StorageKey.COMPONENT_PAGE_CONTEXT)
  componentListPageContext: PageContext = new PageContext();

  aboutToAppear(): void {
    // 初始化时压入首页
    this.componentListPageContext.openPage({
      routerName: PageEnum.COMPONENT_LIST_VIEW,
      param: { scroller: this.scroller, homeTabController: this.homeTabController },
    }, false);
  }

  build() {
    HdsNavigation(this.componentListPageContext.navPathStack) {
      // NavContent 会根据 navPathStack 自动渲染栈顶页面
    }
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .hideTitleBar(true)
  }
}
```

### 3.5 路由参数定义

```typescript
// RouterParams.ets
interface BasicRouterParams {
  title: string;
  id: number;
}

export interface ComponentDetailParams extends BasicRouterParams {
  interactionType: InteractionTypeEnum;
}

export interface SampleDetailParams extends BasicRouterParams {
  currentIndex: number;
  cardId: number;
  unionId: number;
  interactionType: InteractionTypeEnum;
  categoryName: string;
}

export interface ArticleDetailParams extends BasicRouterParams {
  isArticle: boolean;
  detailsUrl: string;
  desc: string;
  interactionType: InteractionTypeEnum;
}
```

### 3.6 页面跳转示例

```typescript
// 跳转到组件详情
const pageContext = AppStorage.get<PageContext>(StorageKey.COMPONENT_PAGE_CONTEXT);
pageContext?.openPage({
  routerName: PageEnum.COMPONENT_DETAIL_VIEW,
  param: {
    title: 'Button',
    id: 123,
    interactionType: InteractionTypeEnum.COMPONENT,
  } as ComponentDetailParams,
});

// 返回
pageContext?.popPage();
```

---

## 四、跨 Tab 跳转（外部唤起场景）

处理推送消息、Widget 卡片、快捷方式等需要跳转到指定 Tab + 指定页面的场景：

```typescript
// MainPageViewModel.ets
class MainPageViewModel extends BaseVM<BaseState> {

  // 外部入口统一处理
  private jumpToPage(wantParams: WantParams): number {
    if (wantParams?.shortCutKey) {
      return this.navigateToModuleHome(wantParams.shortCutKey);  // 跳 Tab 首页
    } else if (wantParams?.pushMessage) {
      return this.navigateToModuleDetail(wantParams);            // 跳 Tab + 详情页
    }
    return TabBarType.HOME;
  }

  // 跳转到指定 Tab 的首页
  private navigateToModuleHome(shortCutKey: string): TabBarType {
    switch (shortCutKey) {
      case 'ComponentListPage': return TabBarType.HOME;
      case 'SampleListPage':    return TabBarType.SAMPLE;
      case 'ArticleListPage':   return TabBarType.PRACTICE;
      default:                  return TabBarType.HOME;
    }
  }

  // 跳转到指定 Tab 并打开详情页
  private navigateToModuleDetail(wantParams: WantParams): TabBarType {
    const pageContext = AppStorage.get<PageContext>(StorageKey.HOME_PAGE_CONTEXT);
    pageContext?.openPage({
      routerName: PageEnum.COMPONENT_DETAIL_VIEW,
      param: { title: wantParams.title, id: wantParams.id } as ComponentDetailParams,
    });
    return TabBarType.HOME;  // 返回目标 Tab 索引
  }
}
```

MainPage 中监听外部参数变化：

```typescript
@StorageProp(StorageKey.WANT_PARAMETERS) @Watch('jumpPage') wantParams: WantParams | undefined;

jumpPage(): void {
  if (this.wantParams) {
    const tabIndex = this.mainPageViewModel.sendEvent<WantParams>({
      type: HomeEventTypeEnum.JUMP_TO_PAGE,
      param: this.wantParams,
    });
    this.currentIndex = tabIndex as number;  // 切换到目标 Tab
    AppStorage.delete(StorageKey.WANT_PARAMETERS);
  }
}
```

---

## 五、StorageKey 定义

```typescript
export enum StorageKey {
  GLOBAL_INFO = 'globalInfoModel',
  COLOR_MODE = 'colorMode',
  CURRENT_TAB = 'currentTab',
  WANT_PARAMETERS = 'wantParameters',
  UI_CONTEXT = 'uiContext',
  HOME_PAGE_CONTEXT = 'homePageContext',
  SAMPLE_PAGE_CONTEXT = 'samplePageContext',
  COMPONENT_PAGE_CONTEXT = 'componentPageContext',
  EXPLORATION_PAGE_CONTEXT = 'explorationPageContext',
  MINE_PAGE_CONTEXT = 'minePageContext',
  BLUE_RENDER_GROUP = 'blueRenderGroup',
}
```

---

## 六、复用步骤

### 6.1 模块结构

```
entry/
  └── src/main/ets/
      ├── entryability/EntryAbility.ets    # 创建 PageContext
      └── pages/MainPage.ets               # Tab 容器

features/
  ├── home/
  │   ├── src/main/resources/base/profile/router_map.json
  │   └── src/main/ets/
  │       ├── view/HomeView.ets            # HdsNavigation + NavPathStack
  │       └── view/HomeListView.ets        # HdsNavDestination 页面
  └── mine/
      ├── src/main/resources/base/profile/router_map.json
      └── src/main/ets/
          ├── view/MineView.ets
          └── view/SettingView.ets
```

### 6.2 接入步骤

1. **定义 TabType 枚举和 TabData 模型**
2. **在 EntryAbility 中为每个 Tab 创建 PageContext 并存入 AppStorage**
3. **MainPage 使用 HdsTabs + TabContent 构建 Tab 容器**
4. **每个 Tab 的 HomeView 使用 HdsNavigation 绑定独立的 NavPathStack**
5. **每个 feature 模块注册 router_map.json**
6. **页面使用 HdsNavDestination 包裹，导出 @Builder 函数**
7. **通过 PageContext.openPage() / popPage() 进行跳转**

### 6.3 关键 API 速查

| 功能 | API |
|------|-----|
| 创建导航栈 | `new NavPathStack()` |
| 压入页面 | `navPathStack.pushPath({ name, param })` |
| 弹出页面 | `navPathStack.pop()` |
| 替换页面 | `navPathStack.replacePath({ name, param })` |
| 回到栈底 | `navPathStack.popToIndex(0)` |
| 清空栈 | `navPathStack.clear()` |
| 监听变化 | `navPathStack.onDestinationChange()` |
| Tab 切换 | `HdsTabs.onChange((index) => { ... })` |
| Tab 控制器 | `HdsTabsController` |
| 绑定滚动 | `tabController.bindScroller(index, scroller)` |
| 预加载 | `tabController.preloadItems([0, 1, 2])` |

---

## 七、注意事项

1. **freezeWhenInactive**: TabContent 对应的组件建议添加 `@Component({ freezeWhenInactive: true })`，非活跃 Tab 冻结渲染，提升性能。

2. **Scroller 绑定**: 每个 Tab 的 Scroller 需通过 `tabController.bindScroller()` 绑定，否则滚动联动（如 TabBar 隐藏动画）不生效。

3. **多 PageContext 隔离**: XL 断点下 Sidebar 模式，组件库/示例/实践各有独立 PageContext，互不影响。

4. **router_map.json 合并**: 多模块的 router_map.json 会在构建时自动合并，无需手动去重。

5. **页面 Builder 函数命名**: `buildFunction` 必须与文件中导出的 `@Builder` 函数名完全一致。
