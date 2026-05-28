# Navigation Best Practices Adaptation Design

**Date:** 2026-05-28
**Status:** Approved
**Scope:** Full navigation architecture refactor per `navigation-guide-mobile-tablet.md`

---

## Overview

Refactor LightMarkdown navigation to follow HarmonyOS best practices: unified PageContext manager, PageEnum routing, typed parameters, router_map.json registration, responsive tabs for tablet, and Want mechanism for external launch.

---

## Current State

- `Index.ets` as `@Entry`, uses `HdsNavigation` + `HdsTabs` with 3 tabs (MdView/Star/Mine)
- Navigation via `@Provide('pathStack') NavPathStack` shared to children
- Sub-pages pushed by string name: `pathStack.pushPath({ name: 'MarkdownViewer', param: item })`
- `PageMap` builder in Index uses if-else chain for routing
- Complex objects (MarkdownFile, FileGroup) passed as route params
- No PageContext, no PageEnum, no router_map.json
- Tabs always bottom-positioned, no tablet side-tab adaptation

---

## Target Architecture

```
EntryAbility
  └─ AppStorage.setOrCreate(HOME_PAGE_CONTEXT, new PageContext())
  └─ loadContent('page/SplashPage')

SplashPage (@Entry)
  └─ HdsNavigation(pageContext.navPathStack)
  └─ replacePage → MainPage

MainPage (@Component, HdsNavDestination)
  └─ HdsTabs
      ├─ TabContent → MdView
      ├─ TabContent → Star
      └─ TabContent → Mine
  └─ SM/MD: .vertical(false), BarPosition.End
  └─ LG: .vertical(true), BarPosition.Start

Sub-pages (router_map.json registered)
  └─ MarkdownViewerPage, StarredPage, GroupDetailPage, etc.
  └─ All use HdsNavDestination + onReady for typed params
```

---

## Module 1: Core Navigation Files

### File: `common/src/main/ets/routermanager/PageContext.ets`

```typescript
export class PageContext {
  private readonly pathStack: NavPathStack;

  constructor() {
    this.pathStack = new NavPathStack();
  }

  public get navPathStack(): NavPathStack {
    return this.pathStack;
  }

  public openPage(data: RouterParam, animated: boolean = true): void {
    this.pathStack.pushPath({ name: data.routerName, param: data.param }, animated);
  }

  public replacePage(data: RouterParam, animated: boolean = true): void {
    this.pathStack.replacePath({ name: data.routerName, param: data.param }, animated);
  }

  public popPage(animated: boolean = true): void {
    this.pathStack.pop(animated);
  }

  public popToRoot(animated: boolean = true): void {
    this.pathStack.popToIndex(0, animated);
  }

  public clear(animated: boolean = true): void {
    this.pathStack.clear(animated);
  }
}

export interface RouterParam {
  routerName: PageEnum;
  param?: object;
}
```

### File: `common/src/main/ets/model/PageEnum.ets`

```typescript
export enum PageEnum {
  MAIN_PAGE = 'MainPage',
  MARKDOWN_VIEWER = 'MarkdownViewer',
  STARRED_PAGE = 'Starred',
  GROUP_DETAIL_PAGE = 'GroupDetail',
  GROUP_LIST_PAGE = 'GroupList',
  RECENT_PAGE = 'Recent',
  MULTI_SELECT_PAGE = 'MultiSelect',
  DARK_MODE_SETTING = 'DarkModeSetting',
  ABOUT_PAGE = 'AboutPage',
  GUIDE_PAGE = 'GuidePage',
  FEEDBACK_PAGE = 'FeedbackPage',
}
```

### File: `common/src/main/ets/model/RouterParams.ets`

```typescript
export interface MarkdownViewerParams {
  sandboxPath: string;
}

export interface GroupDetailParams {
  groupId: number;
}
```

### File: `common/src/main/ets/constant/CommonEnums.ets` (update)

```typescript
export enum StorageKey {
  HOME_PAGE_CONTEXT = 'lightmd_PageContext',
  GLOBAL_INFO = 'globalInfo',
  UI_CONTEXT = 'uiContext',
  WANT_PARAMETERS = 'lightmd_WantParams',
}
```

---

## Module 2: EntryAbility Changes

**File:** `entry/src/main/ets/entryability/EntryAbility.ets`

Changes:
1. Import `PageContext`, `StorageKey`
2. In `onWindowStageCreate`: `AppStorage.setOrCreate(StorageKey.HOME_PAGE_CONTEXT, new PageContext())`
3. Change `loadContent('pages/Index')` → `loadContent('page/SplashPage')`
4. Add Want handling in `onCreate`/`onNewWant`:

```typescript
handleWantParam(want: Want) {
  if (want.parameters) {
    AppStorage.setOrCreate(StorageKey.WANT_PARAMETERS, want.parameters);
  }
}
```

---

## Module 3: SplashPage (New File)

**File:** `entry/src/main/ets/page/SplashPage.ets`

```typescript
@Entry
@Component
struct SplashPage {
  @StorageLink(StorageKey.HOME_PAGE_CONTEXT) pageContext: PageContext = new PageContext();

  build() {
    HdsNavigation(this.pageContext.navPathStack) {
      // Splash content (logo, loading indicator)
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }

  aboutToAppear() {
    this.pageContext.replacePage({ routerName: PageEnum.MAIN_PAGE });
  }
}
```

---

## Module 4: Index.ets → MainPage Refactor

**File:** `entry/src/main/ets/pages/Index.ets` (refactor to MainPage)

Key changes:
1. Remove `@Entry` decorator (SplashPage is entry now)
2. Replace `@Provide('pathStack')` with `@StorageLink(StorageKey.HOME_PAGE_CONTEXT) pageContext: PageContext`
3. Wrap content in `HdsNavDestination` instead of bare `HdsNavigation`
4. Remove `PageMap` builder (sub-pages registered in router_map.json)
5. Responsive tabs:

```typescript
.vertical(this.globalInfoModel.widthBreakpoint === WidthBreakpoint.WIDTH_LG)
.barPosition(this.globalInfoModel.widthBreakpoint === WidthBreakpoint.WIDTH_LG ?
  BarPosition.Start : BarPosition.End)
.barHeight(new BreakpointType<Length>({
  sm: 56, md: 56, lg: '100%',
}).getValue(this.globalInfoModel.widthBreakpoint))
```

6. All internal navigation changed to `pageContext.openPage({ routerName: PageEnum.XXX, param: { ... } })`

---

## Module 5: router_map.json

**File:** `entry/src/main/resources/base/profile/router_map.json`

```json
{
  "routerMap": [
    { "name": "MarkdownViewer", "pageSourceFile": "src/main/ets/pages/Index.ets", "buildFunction": "MarkdownViewerBuilder" },
    { "name": "Starred", "pageSourceFile": "src/main/ets/pages/Index.ets", "buildFunction": "StarredPageBuilder" },
    { "name": "GroupDetail", "pageSourceFile": "src/main/ets/pages/Index.ets", "buildFunction": "GroupDetailPageBuilder" },
    { "name": "GroupList", "pageSourceFile": "src/main/ets/pages/Index.ets", "buildFunction": "GroupListPageBuilder" },
    { "name": "Recent", "pageSourceFile": "src/main/ets/pages/Index.ets", "buildFunction": "RecentPageBuilder" },
    { "name": "MultiSelect", "pageSourceFile": "src/main/ets/pages/Index.ets", "buildFunction": "MultiSelectPageBuilder" },
    { "name": "DarkModeSetting", "pageSourceFile": "src/main/ets/pages/Index.ets", "buildFunction": "DarkModeSettingBuilder" },
    { "name": "AboutPage", "pageSourceFile": "src/main/ets/pages/Index.ets", "buildFunction": "AboutPageBuilder" },
    { "name": "GuidePage", "pageSourceFile": "src/main/ets/pages/Index.ets", "buildFunction": "GuidePageBuilder" },
    { "name": "FeedbackPage", "pageSourceFile": "src/main/ets/pages/Index.ets", "buildFunction": "FeedbackPageBuilder" }
  ]
}
```

`module.json5` must reference: `"routerMap": "$profile:router_map"`

---

## Module 6: Sub-page Updates

All sub-pages follow this pattern:

```typescript
@Component
struct XxxPage {
  private pageContext: PageContext = AppStorage.get<PageContext>(StorageKey.HOME_PAGE_CONTEXT) ?? new PageContext();

  handleOnReady(ctx: NavDestinationContext) {
    const params = ctx?.pathInfo?.param as XxxParams;
    // Use params.id to query DB
  }

  build() {
    HdsNavDestination() {
      // Content
    }
    .onReady((ctx: NavDestinationContext) => this.handleOnReady(ctx))
  }
}

@Builder
export function XxxPageBuilder() {
  XxxPage()
}
```

### Param changes:

| Page | Current Param | New Param |
|------|--------------|-----------|
| MarkdownViewerPage | `MarkdownFile` object | `{ sandboxPath: string }` |
| GroupDetailPage | `FileGroup` object | `{ groupId: number }` |
| Others | none | none |

---

## Module 7: Tab Content Updates (MdView/Star/Mine)

- Replace `@Consume('pathStack')` with `PageContext` from AppStorage
- Replace `pathStack.pushPath({ name: 'xxx', param: obj })` with `pageContext.openPage({ routerName: PageEnum.XXX, param: { id: xxx } })`
- Remove MdView's internal `PageMap` builder

---

## Module 8: Want Mechanism

In MainPage:

```typescript
@StorageLink(StorageKey.WANT_PARAMETERS) @Watch('jumpPage') wantParams: WantParams | undefined;

jumpPage(): void {
  if (this.wantParams) {
    this.pageContext.popToRoot();
    this.navigateToTarget(this.wantParams);
    AppStorage.delete(StorageKey.WANT_PARAMETERS);
  }
}
```

---

## File Change Summary

| Action | File |
|--------|------|
| CREATE | `common/src/main/ets/routermanager/PageContext.ets` |
| CREATE | `common/src/main/ets/model/PageEnum.ets` |
| CREATE | `common/src/main/ets/model/RouterParams.ets` |
| UPDATE | `common/src/main/ets/constant/CommonEnums.ets` |
| CREATE | `entry/src/main/ets/page/SplashPage.ets` |
| REFACTOR | `entry/src/main/ets/pages/Index.ets` → MainPage |
| UPDATE | `entry/src/main/ets/entryability/EntryAbility.ets` |
| CREATE | `entry/src/main/resources/base/profile/router_map.json` |
| UPDATE | `entry/src/main/module.json5` |
| UPDATE | `feature/markdown/src/main/ets/page/MdView.ets` |
| UPDATE | `feature/markdown/src/main/ets/page/MarkdownViewerPage.ets` |
| UPDATE | `feature/markdown/src/main/ets/page/MultiSelectPage.ets` |
| UPDATE | `feature/star/src/main/ets/page/Star.ets` |
| UPDATE | `feature/star/src/main/ets/page/StarredPage.ets` |
| UPDATE | `feature/star/src/main/ets/page/GroupDetailPage.ets` |
| UPDATE | `feature/star/src/main/ets/page/GroupListPage.ets` |
| UPDATE | `feature/star/src/main/ets/page/RecentPage.ets` |
| UPDATE | `feature/mine/src/main/ets/page/Mine.ets` |
| UPDATE | `feature/mine/src/main/ets/page/DarkModeSetting.ets` |
| UPDATE | `feature/mine/src/main/ets/page/AboutPage.ets` |
| UPDATE | `feature/mine/src/main/ets/page/GuidePage.ets` |
| UPDATE | `feature/mine/src/main/ets/page/FeedbackPage.ets` |

---

## Risks & Mitigations

1. **router_map.json path accuracy**: `pageSourceFile` paths must match build output. Verify after implementation.
2. **Object → ID param change**: MarkdownViewerPage and GroupDetailPage must add DB query in `onReady`.
3. **@Provide → AppStorage migration**: Grep all `@Consume('pathStack')` references to ensure completeness.
4. **SplashPage flash**: Add minimal delay or use animation for smooth transition.
