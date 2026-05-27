# LightMarkdown 代码结构优化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Optimize file structure and code architecture — clean dead code, extract shared components, split large files, eliminate cross-module duplication.

**Architecture:** Bottom-up: common cleanup → common components → file splitting → service cleanup → star dedup. All shared components go in `common/` module with primitive-type parameters (no circular deps).

**Tech Stack:** HarmonyOS Next, ArkTS/ArkUI, hvigor build system, relationalStore (RDB)

---

## File Structure

### Files to DELETE
- `common/src/main/ets/component/SearchTwo.ets`
- `common/src/main/ets/service/GroupGlobalService.ets`
- `common/src/main/ets/database/MarkdownFile.ets`
- `common/src/main/ets/model/MarkdownFile.ets`

### Files to MOVE/RENAME
- `feature/markdown/component/SideCompoent.ets` → `feature/markdown/component/SideComponent.ets`
- `feature/markdown/component/MarkdownViewerPage.ets` → `feature/markdown/page/MarkdownViewerPage.ets`
- `feature/mine/settingpage/DarkModeSetting.ets` → `feature/mine/page/DarkModeSetting.ets`
- `feature/mine/viewmodel/ColorModeChangeFunctions.ets` → `feature/mine/utils/ColorModeChangeFunctions.ets`

### Files to CREATE (common components)
- `common/src/main/ets/util/TimeUtil.ets`
- `common/src/main/ets/component/DeleteConfirmDialog.ets`
- `common/src/main/ets/component/EmptyState.ets`
- `common/src/main/ets/component/SearchBar.ets`
- `common/src/main/ets/component/FileListCard.ets`
- `common/src/main/ets/component/GroupSheetContent.ets`

### Files to CREATE (markdown components)
- `feature/markdown/component/FileGridCard.ets`
- `feature/markdown/component/FileActionBar.ets`
- `feature/markdown/component/RenameDialog.ets`
- `feature/markdown/component/BatchToolbar.ets`
- `feature/markdown/utils/FileUtil.ets`

### Files to MODIFY
- `common/Index.ets`
- `feature/markdown/Index.ets`
- `feature/markdown/page/MdView.ets`
- `feature/markdown/page/MarkdownViewerPage.ets` (after move)
- `feature/markdown/page/MultiSelectPage.ets`
- `feature/star/page/StarredPage.ets`
- `feature/star/page/RecentPage.ets`
- `feature/star/page/GroupDetailPage.ets`
- `feature/star/page/GroupListPage.ets`
- `feature/mine/Index.ets`
- `entry/src/main/ets/pages/Index.ets`

---

## Phase 1: Common 模块清理

### Task 1: 删除死代码

**Files:**
- Delete: `common/src/main/ets/component/SearchTwo.ets`
- Delete: `common/src/main/ets/service/GroupGlobalService.ets`
- Delete: `common/src/main/ets/database/MarkdownFile.ets`

- [ ] **Step 1: 删除 SearchTwo.ets**

```bash
rm common/src/main/ets/component/SearchTwo.ets
```

- [ ] **Step 2: 删除 GroupGlobalService.ets**

```bash
rm common/src/main/ets/service/GroupGlobalService.ets
```

- [ ] **Step 3: 删除 MarkdownFile.ets (database 演示)**

```bash
rm common/src/main/ets/database/MarkdownFile.ets
rmdir common/src/main/ets/database
rmdir common/src/main/ets/service
```

- [ ] **Step 4: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add -A common/
git commit -m "chore: remove dead code from common module"
```

### Task 2: 统一 MarkdownFile 定义

**Files:**
- Delete: `common/src/main/ets/model/MarkdownFile.ets`

- [ ] **Step 1: 确认无引用**

Run: `grep -r "model/MarkdownFile" --include="*.ets" .`
Expected: no results (already verified — nobody imports it)

- [ ] **Step 2: 删除文件**

```bash
rm common/src/main/ets/model/MarkdownFile.ets
```

- [ ] **Step 3: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add -A common/
git commit -m "chore: remove duplicate MarkdownFile interface from common"
```

### Task 3: 重命名 SideCompoent → SideComponent

**Files:**
- Rename: `feature/markdown/component/SideCompoent.ets` → `feature/markdown/component/SideComponent.ets`

- [ ] **Step 1: 检查谁 import 了 SideCompoent**

Run: `grep -r "SideCompoent" --include="*.ets" .`

- [ ] **Step 2: 重命名文件**

```bash
mv feature/markdown/component/SideCompoent.ets feature/markdown/component/SideComponent.ets
```

- [ ] **Step 3: 更新所有 import 路径**

将所有 `SideCompoent` 替换为 `SideComponent`（文件名和 import 路径）。

- [ ] **Step 4: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "fix: rename SideCompoent to SideComponent"
```

### Task 4: 移动 MarkdownViewerPage 到 page/

**Files:**
- Move: `feature/markdown/component/MarkdownViewerPage.ets` → `feature/markdown/page/MarkdownViewerPage.ets`
- Modify: `feature/markdown/Index.ets`

- [ ] **Step 1: 移动文件**

```bash
mv feature/markdown/component/MarkdownViewerPage.ets feature/markdown/page/MarkdownViewerPage.ets
```

- [ ] **Step 2: 更新 feature/markdown/Index.ets**

将:
```
export { MarkdownViewerPage } from './src/main/ets/component/MarkdownViewerPage'
```
改为:
```
export { MarkdownViewerPage } from './src/main/ets/page/MarkdownViewerPage'
```

- [ ] **Step 3: 检查 MarkdownViewerPage.ets 内部 import**

如果内部有 `import ... from '../component/...'` 引用同目录文件，需要更新为 `import ... from './...'`。

- [ ] **Step 4: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: move MarkdownViewerPage to page/ directory"
```

### Task 5: 移动 DarkModeSetting 到 page/

**Files:**
- Move: `feature/mine/settingpage/DarkModeSetting.ets` → `feature/mine/page/DarkModeSetting.ets`
- Modify: `feature/mine/Index.ets`

- [ ] **Step 1: 移动文件**

```bash
mv feature/mine/settingpage/DarkModeSetting.ets feature/mine/page/DarkModeSetting.ets
```

- [ ] **Step 2: 更新 feature/mine/Index.ets**

将:
```
export { DarkModeSetting } from './src/main/ets/settingpage/DarkModeSetting';
```
改为:
```
export { DarkModeSetting } from './src/main/ets/page/DarkModeSetting';
```

- [ ] **Step 3: 删除空目录**

```bash
rmdir feature/mine/settingpage
```

- [ ] **Step 4: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: move DarkModeSetting to page/ directory"
```

### Task 6: 移动 ColorModeChangeFunctions 到 utils/

**Files:**
- Move: `feature/mine/viewmodel/ColorModeChangeFunctions.ets` → `feature/mine/utils/ColorModeChangeFunctions.ets`

- [ ] **Step 1: 检查引用**

Run: `grep -r "ColorModeChangeFunctions\|viewmodel" --include="*.ets" feature/mine/`

- [ ] **Step 2: 移动文件**

```bash
mkdir -p feature/mine/src/main/ets/utils
mv feature/mine/src/main/ets/viewmodel/ColorModeChangeFunctions.ets feature/mine/src/main/ets/utils/ColorModeChangeFunctions.ets
```

- [ ] **Step 3: 更新 import 路径**

将 `viewmodel/ColorModeChangeFunctions` 替换为 `utils/ColorModeChangeFunctions`。

- [ ] **Step 4: 删除空目录**

```bash
rmdir feature/mine/src/main/ets/viewmodel
```

- [ ] **Step 5: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: move ColorModeChangeFunctions to utils/ directory"
```

---

## Phase 2: 提取公共组件到 common

### Task 7: 创建 TimeUtil

**Files:**
- Create: `common/src/main/ets/util/TimeUtil.ets`
- Modify: `common/Index.ets`

- [ ] **Step 1: 创建 TimeUtil.ets**

```typescript
export function formatRelativeTime(timestamp: number): string {
  if (timestamp <= 0) return '';
  const diff = Date.now() - timestamp;
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return '刚刚';
  if (minutes < 60) return `${minutes}分钟前`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}小时前`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days}天前`;
  const months = Math.floor(days / 30);
  return `${months}个月前`;
}
```

- [ ] **Step 2: 更新 common/Index.ets 导出**

添加: `export { formatRelativeTime } from './src/main/ets/util/TimeUtil'`

- [ ] **Step 3: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add common/
git commit -m "feat: add TimeUtil with formatRelativeTime to common"
```

### Task 8: 创建 EmptyState 组件

**Files:**
- Create: `common/src/main/ets/component/EmptyState.ets`
- Modify: `common/Index.ets`

- [ ] **Step 1: 创建 EmptyState.ets**

```typescript
@Component
export struct EmptyState {
  icon: Resource = $r('sys.symbol.doc_plaintext_fill');
  text: string = '';

  build() {
    Column() {
      SymbolGlyph(this.icon)
        .fontSize(48)
        .fontColor([$r('sys.color.font_tertiary')])
      Text(this.text)
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ top: 80 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
```

- [ ] **Step 2: 更新 common/Index.ets 导出**

添加: `export { EmptyState } from './src/main/ets/component/EmptyState'`

- [ ] **Step 3: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add common/
git commit -m "feat: add EmptyState component to common"
```

### Task 9: 创建 DeleteConfirmDialog 组件

**Files:**
- Create: `common/src/main/ets/component/DeleteConfirmDialog.ets`
- Modify: `common/Index.ets`

- [ ] **Step 1: 创建 DeleteConfirmDialog.ets**

```typescript
export function showDeleteConfirm(
  uiContext: UIContext,
  fileName: string,
  onConfirm: () => void
): void {
  uiContext.showAlertDialog({
    title: '确认删除',
    message: `确定要删除「${fileName}」吗？此操作不可恢复。`,
    autoCancel: true,
    alignment: DialogAlignment.Center,
    primaryButton: {
      value: '取消',
      action: () => {}
    },
    secondaryButton: {
      value: '删除',
      action: () => { onConfirm(); }
    }
  });
}
```

- [ ] **Step 2: 更新 common/Index.ets 导出**

添加: `export { showDeleteConfirm } from './src/main/ets/component/DeleteConfirmDialog'`

- [ ] **Step 3: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add common/
git commit -m "feat: add showDeleteConfirm utility to common"
```

### Task 10: 创建 SearchBar 组件

**Files:**
- Create: `common/src/main/ets/component/SearchBar.ets`
- Modify: `common/Index.ets`

- [ ] **Step 1: 创建 SearchBar.ets**

```typescript
@Component
export struct SearchBar {
  placeholder: string = '搜索文件';
  onSearch: (keyword: string) => void = () => {};
  onChange: (keyword: string) => void = () => {};

  build() {
    Search({ value: '', placeholder: this.placeholder })
      .width('100%')
      .height(40)
      .onChange((value: string) => { this.onChange(value); })
      .onSubmit((value: string) => { this.onSearch(value); })
  }
}
```

- [ ] **Step 2: 更新 common/Index.ets 导出**

添加: `export { SearchBar } from './src/main/ets/component/SearchBar'`

- [ ] **Step 3: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add common/
git commit -m "feat: add SearchBar component to common"
```

### Task 11: 创建 FileListCard 组件

**Files:**
- Create: `common/src/main/ets/component/FileListCard.ets`
- Modify: `common/Index.ets`

- [ ] **Step 1: 创建 FileListCard.ets**

需要先读取 StarredPage.ets 的 listCard builder 作为参考模板，提取为独立组件。组件参数全部用 primitive 类型。

```typescript
@Component
export struct FileListCard {
  name: string = '';
  subtitle: string = '';
  isStar: boolean = false;
  groupId: number = -1;
  groupName: string = '';
  onTap: () => void = () => {};
  onStar: () => void = () => {};
  onDelete: () => void = () => {};

  build() {
    ListItem() {
      Row() {
        SymbolGlyph($r('sys.symbol.doc_plaintext_fill'))
          .fontSize(24)
          .fontColor([$r('sys.color.brand')])
          .margin({ right: 12 })
        Column() {
          Text(this.name)
            .fontSize(16)
            .fontWeight(500)
            .fontColor($r('sys.color.font_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.subtitle) {
            Text(this.subtitle)
              .fontSize(12)
              .fontColor($r('sys.color.font_secondary'))
              .margin({ top: 4 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        if (this.groupId !== -1 && this.groupName) {
          Text(this.groupName)
            .fontSize(10)
            .fontColor($r('sys.color.brand'))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor($r('sys.color.comp_emphasize_secondary'))
            .borderRadius(4)
            .margin({ right: 8 })
        }
        SymbolGlyph(this.isStar ? $r('sys.symbol.star_fill') : $r('sys.symbol.star'))
          .fontSize(20)
          .fontColor([this.isStar ? '#FFC83D' : $r('sys.color.font_tertiary')])
          .onClick(() => { this.onStar(); })
      }
      .width('100%')
      .height(64)
      .padding({ left: 16, right: 16 })
    }
    .swipeAction({
      end: this.onDelete ? (() => {
        Button() {
          SymbolGlyph($r('sys.symbol.trash_fill'))
            .fontSize(20)
            .fontColor([Color.White])
        }
        .type(ButtonType.Circle)
        .width(40)
        .height(40)
        .backgroundColor($r('sys.color.warning'))
        .onClick(() => { this.onDelete(); })
      })() : undefined
    })
    .onClick(() => { this.onTap(); })
  }
}
```

- [ ] **Step 2: 更新 common/Index.ets 导出**

添加: `export { FileListCard } from './src/main/ets/component/FileListCard'`

- [ ] **Step 3: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add common/
git commit -m "feat: add FileListCard component to common"
```

### Task 12: 创建 GroupSheetContent 组件

**Files:**
- Create: `common/src/main/ets/component/GroupSheetContent.ets`
- Modify: `common/Index.ets`

- [ ] **Step 1: 读取 MarkdownViewerPage.ets 的 groupSheetBuilder 作为参考**

读取 `feature/markdown/page/MarkdownViewerPage.ets` 中的 groupSheetBuilder 实现。

- [ ] **Step 2: 创建 GroupSheetContent.ets**

参数用 primitive 类型（`groups: Array<{id: number, name: string}>`），不引用 FileGroup。

```typescript
interface GroupItem {
  id: number;
  name: string;
}

@Component
export struct GroupSheetContent {
  currentGroupId: number = -1;
  groups: GroupItem[] = [];
  newGroupName: string = '';
  onAssign: (id: number, name: string) => void = () => {};
  onRemove: () => void = () => {};
  onCreate: (name: string) => void = () => {};

  build() {
    Column() {
      Row() {
        TextInput({ placeholder: '创建新分组', text: this.newGroupName })
          .layoutWeight(1)
          .onChange((value: string) => { this.newGroupName = value; })
          .onSubmit(() => { this.onCreate(this.newGroupName); });
        Button('创建')
          .type(ButtonType.Capsule)
          .backgroundColor($r('sys.color.brand'))
          .fontColor(Color.White)
          .height(40)
          .margin({ left: 8 })
          .enabled(this.newGroupName.trim().length > 0)
          .onClick(() => { this.onCreate(this.newGroupName); });
      }
      .width('100%')
      .margin({ bottom: 12 });

      if (this.groups.length > 0) {
        List({ space: 8 }) {
          ForEach(this.groups, (group: GroupItem) => {
            ListItem() {
              Row() {
                SymbolGlyph($r('sys.symbol.arrow_right_folder_fill'))
                  .fontSize(24)
                  .fontColor([$r('sys.color.brand')]);
                Text(group.name)
                  .fontSize(16)
                  .fontColor($r('sys.color.font_primary'))
                  .margin({ left: 12 })
                  .layoutWeight(1);
                if (this.currentGroupId === group.id) {
                  SymbolGlyph($r('sys.symbol.checkmark_circle'))
                    .fontSize(24)
                    .fontColor([$r('sys.color.brand')]);
                }
              }
              .backgroundColor(this.currentGroupId === group.id
                ? $r('sys.color.comp_emphasize_secondary')
                : $r('sys.color.comp_background_primary'))
              .height(56)
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .borderRadius(16)
              .onClick(() => { this.onAssign(group.id, group.name); });
            }
          }, (group: GroupItem) => group.id.toString());
        }
        .height(undefined)
        .width('100%')
      }

      if (this.currentGroupId !== -1) {
        Row() {
          SymbolGlyph($r('sys.symbol.clean_fill'))
            .fontSize(24)
            .fontColor([$r('sys.color.warning')]);
          Text('移出当前分组')
            .fontColor($r('sys.color.warning'))
            .margin({ left: 12 })
            .layoutWeight(1);
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .height(56)
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .borderRadius(16)
        .margin({ top: 12 })
        .onClick(() => { this.onRemove(); });
      }
    }
    .padding({ right: 16, left: 16 })
    .width('100%')
  }
}
```

- [ ] **Step 3: 更新 common/Index.ets 导出**

添加: `export { GroupSheetContent } from './src/main/ets/component/GroupSheetContent'`

- [ ] **Step 4: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add common/
git commit -m "feat: add GroupSheetContent component to common"
```

---

## Phase 3: 拆分大文件

### Task 13: 创建 FileGridCard 组件

**Files:**
- Create: `feature/markdown/component/FileGridCard.ets`

- [ ] **Step 1: 读取 MdView.ets 的 gridCard builder**

读取 `feature/markdown/page/MdView.ets` 中的 gridCard 实现（搜索 `@Builder gridCard`）。

- [ ] **Step 2: 创建 FileGridCard.ets**

提取网格卡片为独立组件，参数用 MarkdownFile class（markdown 模块内部可用）。

```typescript
import { MarkdownFile } from '../class/MarkdownFile';
import { formatRelativeTime } from 'common';

@Component
export struct FileGridCard {
  file: MarkdownFile = new MarkdownFile('', '', '', 0);
  onTap: () => void = () => {};
  onStar: () => void = () => {};

  build() {
    Column() {
      // icon + group tag row
      Row() {
        SymbolGlyph($r('sys.symbol.doc_plaintext_fill'))
          .fontSize(28)
          .fontColor([$r('sys.color.brand')])
        Blank()
        if (this.file.groupId !== -1) {
          Text(this.file.groupName)
            .fontSize(10)
            .fontColor($r('sys.color.brand'))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor($r('sys.color.comp_emphasize_secondary'))
            .borderRadius(4)
        }
      }
      .width('100%')

      // filename
      Text(this.file.name)
        .fontSize(14)
        .fontWeight(500)
        .fontColor($r('sys.color.font_primary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })

      // size + time row
      Row() {
        Text(this.file.size)
          .fontSize(11)
          .fontColor($r('sys.color.font_secondary'))
        Blank()
        Text(formatRelativeTime(this.file.lastViewedAt))
          .fontSize(11)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .margin({ top: 4 })

      // star icon
      Row() {
        Blank()
        SymbolGlyph(this.file.isStar ? $r('sys.symbol.star_fill') : $r('sys.symbol.star'))
          .fontSize(18)
          .fontColor([this.file.isStar ? '#FFC83D' : $r('sys.color.font_tertiary')])
          .onClick(() => { this.onStar(); })
      }
      .width('100%')
    }
    .padding(12)
    .width('100%')
    .height(140)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(12)
    .onClick(() => { this.onTap(); })
  }
}
```

- [ ] **Step 3: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add feature/markdown/
git commit -m "feat: extract FileGridCard component from MdView"
```

### Task 14: 创建 FileActionBar 组件

**Files:**
- Create: `feature/markdown/component/FileActionBar.ets`

- [ ] **Step 1: 读取 MdView.ets 的底部操作栏**

读取 `feature/markdown/page/MdView.ets` 中的 actionButton / TabBarBuilder 实现。

- [ ] **Step 2: 创建 FileActionBar.ets**

```typescript
import { MarkdownFile } from '../class/MarkdownFile';

@Component
export struct FileActionBar {
  file: MarkdownFile = new MarkdownFile('', '', '', 0);
  onGroup: () => void = () => {};
  onStar: () => void = () => {};
  onDelete: () => void = () => {};

  @Builder
  actionButton(icon: Resource, label: string, color: ResourceColor, action: () => void) {
    Column() {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([color])
      Text(label)
        .fontSize(9)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .onClick(() => { action(); })
  }

  build() {
    Row() {
      this.actionButton(
        $r('sys.symbol.folder_fill'),
        this.file.groupId !== -1 ? this.file.groupName : '分组',
        this.file.groupId !== -1 ? $r('sys.color.confirm') : $r('sys.color.icon_primary'),
        () => { this.onGroup(); }
      )
      this.actionButton(
        $r('sys.symbol.star_fill'),
        this.file.isStar ? '取消收藏' : '收藏',
        this.file.isStar ? '#FFC83D' : $r('sys.color.icon_primary'),
        () => { this.onStar(); }
      )
      this.actionButton(
        $r('sys.symbol.trash_fill'),
        '删除',
        $r('sys.color.icon_primary'),
        () => { this.onDelete(); }
      )
    }
    .justifyContent(FlexAlign.Center)
    .width(180)
  }
}
```

- [ ] **Step 3: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add feature/markdown/
git commit -m "feat: extract FileActionBar component from MdView"
```

### Task 15: 创建 BatchToolbar 组件

**Files:**
- Create: `feature/markdown/component/BatchToolbar.ets`

- [ ] **Step 1: 读取 MultiSelectPage.ets 的底部工具栏**

读取 `feature/markdown/page/MultiSelectPage.ets` 中的批量操作工具栏实现。

- [ ] **Step 2: 创建 BatchToolbar.ets**

```typescript
@Component
export struct BatchToolbar {
  selectedCount: number = 0;
  onShare: () => void = () => {};
  onGroup: () => void = () => {};
  onStar: () => void = () => {};
  onDelete: () => void = () => {};
  onCancel: () => void = () => {};

  build() {
    Row() {
      Button('取消')
        .type(ButtonType.Capsule)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .fontColor($r('sys.color.font_primary'))
        .onClick(() => { this.onCancel(); })
      Blank()
      Text(`已选 ${this.selectedCount}`)
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
      Blank()
      SymbolGlyph($r('sys.symbol.share'))
        .fontSize(22)
        .fontColor([$r('sys.color.icon_primary')])
        .onClick(() => { this.onShare(); })
        .margin({ right: 16 })
      SymbolGlyph($r('sys.symbol.folder_fill'))
        .fontSize(22)
        .fontColor([$r('sys.color.icon_primary')])
        .onClick(() => { this.onGroup(); })
        .margin({ right: 16 })
      SymbolGlyph($r('sys.symbol.star_fill'))
        .fontSize(22)
        .fontColor([$r('sys.color.icon_primary')])
        .onClick(() => { this.onStar(); })
        .margin({ right: 16 })
      SymbolGlyph($r('sys.symbol.trash_fill'))
        .fontSize(22)
        .fontColor([$r('sys.color.warning')])
        .onClick(() => { this.onDelete(); })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('sys.color.comp_background_primary'))
  }
}
```

- [ ] **Step 3: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add feature/markdown/
git commit -m "feat: extract BatchToolbar component from MultiSelectPage"
```

### Task 16: 将 RenameDialog 独立为文件

**Files:**
- Create: `feature/markdown/component/RenameDialog.ets`
- Modify: `feature/markdown/page/MarkdownViewerPage.ets`

- [ ] **Step 1: 读取 MarkdownViewerPage.ets 中的 RenameDialog**

读取 `feature/markdown/page/MarkdownViewerPage.ets` 底部的 `@CustomDialog @Component struct RenameDialog`。

- [ ] **Step 2: 创建 feature/markdown/component/RenameDialog.ets**

将 RenameDialog struct 从 MarkdownViewerPage.ets 移到独立文件。

```typescript
@CustomDialog
@Component
export struct RenameDialog {
  initialName: string = '';
  @State inputText: string = '';
  controller: CustomDialogController = new CustomDialogController({builder: () => {}});
  onConfirm: (name: string) => void = () => {};

  aboutToAppear(): void {
    this.inputText = this.initialName;
  }

  build() {
    Column() {
      Text('重命名')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })
      TextInput({ text: this.inputText })
        .onChange((value: string) => { this.inputText = value; })
        .width('100%')
        .margin({ bottom: 16 })
      Row() {
        Button('取消')
          .type(ButtonType.Capsule)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
          .margin({ right: 8 })
          .onClick(() => { this.controller.close(); })
        Button('确认')
          .type(ButtonType.Capsule)
          .backgroundColor($r('sys.color.brand'))
          .fontColor(Color.White)
          .layoutWeight(1)
          .onClick(() => {
            this.onConfirm(this.inputText);
            this.controller.close();
          })
      }
      .width('100%')
    }
    .padding(16)
    .width('100%')
  }
}
```

- [ ] **Step 3: 更新 MarkdownViewerPage.ets**

删除底部的 RenameDialog 定义，添加 import:
```typescript
import { RenameDialog } from '../component/RenameDialog';
```

- [ ] **Step 4: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add feature/markdown/
git commit -m "refactor: extract RenameDialog to standalone file"
```

### Task 17: 重构 MarkdownViewerPage 使用 common 组件

**Files:**
- Modify: `feature/markdown/page/MarkdownViewerPage.ets`

- [ ] **Step 1: 读取当前 MarkdownViewerPage.ets 全文**

- [ ] **Step 2: 替换 groupSheetBuilder 为 GroupSheetContent**

将 `groupSheetBuilder` 中的分组列表逻辑替换为使用 common 的 `GroupSheetContent` 组件。

需要：
1. 添加 import: `import { GroupSheetContent, showDeleteConfirm } from 'common'`
2. 将 `@Builder groupSheetBuilder()` 中的分组列表替换为 `GroupSheetContent` 组件
3. 将 `showDeleteConfirm()` 方法替换为调用 `showDeleteConfirm(this.getUIContext(), this.fileData.name, () => { this.deleteFile(); })`

- [ ] **Step 3: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add feature/markdown/
git commit -m "refactor: MarkdownViewerPage uses common GroupSheetContent and showDeleteConfirm"
```

### Task 18: 重构 MdView 使用 common 组件 + FileGridCard

**Files:**
- Modify: `feature/markdown/page/MdView.ets`

- [ ] **Step 1: 读取当前 MdView.ets 全文**

- [ ] **Step 2: 添加 imports**

```typescript
import { FileListCard, SearchBar, GroupSheetContent, showDeleteConfirm, formatRelativeTime } from 'common';
import { FileGridCard } from '../component/FileGridCard';
```

- [ ] **Step 3: 替换 listCard builder 为 FileListCard**

将列表模式的 `@Builder listCard` 调用替换为 `FileListCard` 组件，传入 primitive 参数：
```
FileListCard({
  name: item.name,
  subtitle: formatRelativeTime(item.lastViewedAt),
  isStar: item.isStar,
  groupId: item.groupId,
  groupName: item.groupName,
  onTap: () => { ... },
  onStar: () => { this.toggleStar(item); },
  onDelete: () => { this.confirmDeleteFile(item); }
})
```

- [ ] **Step 4: 替换 gridCard builder 为 FileGridCard**

将网格模式的 `@Builder gridCard` 调用替换为 `FileGridCard` 组件。

- [ ] **Step 5: 替换搜索栏为 SearchBar**

将 `@Builder BottomBuilder` 替换为 `SearchBar` 组件调用。

- [ ] **Step 6: 替换 groupSheetBuilder 为 GroupSheetContent**

将 `@Builder groupSheetBuilder` 替换为使用 `GroupSheetContent`。

- [ ] **Step 7: 替换删除确认为 showDeleteConfirm**

将 `confirmDeleteFile` 方法替换为调用 `showDeleteConfirm`。

- [ ] **Step 8: 删除已替换的 builder 和方法**

删除 `listCard`、`gridCard`、`BottomBuilder`、`groupSheetBuilder`、`confirmDeleteFile` 等已替换的代码。删除 `formatRelativeTime` 方法（改用 common 的）。

- [ ] **Step 9: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 10: Commit**

```bash
git add feature/markdown/
git commit -m "refactor: MdView uses common components (FileListCard, FileGridCard, SearchBar, GroupSheetContent)"
```

### Task 19: 重构 MultiSelectPage 使用 common 组件

**Files:**
- Modify: `feature/markdown/page/MultiSelectPage.ets`

- [ ] **Step 1: 读取当前 MultiSelectPage.ets 全文**

- [ ] **Step 2: 添加 imports**

```typescript
import { FileListCard, GroupSheetContent, showDeleteConfirm } from 'common';
import { BatchToolbar } from '../component/BatchToolbar';
```

- [ ] **Step 3: 替换 listCard 为 FileListCard**

- [ ] **Step 4: 替换 groupSheetBuilder 为 GroupSheetContent**

- [ ] **Step 5: 替换删除确认为 showDeleteConfirm**

- [ ] **Step 6: 替换底部工具栏为 BatchToolbar**

- [ ] **Step 7: 删除已替换的 builder 和方法**

- [ ] **Step 8: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 9: Commit**

```bash
git add feature/markdown/
git commit -m "refactor: MultiSelectPage uses common components and BatchToolbar"
```

---

## Phase 4: 服务层整理

### Task 20: FileService → FileUtil 迁移

**Files:**
- Create: `feature/markdown/utils/FileUtil.ets`
- Delete: `feature/markdown/service/FileService.ets`
- Modify: 引用 FileService 的文件

- [ ] **Step 1: 检查谁引用了 FileService**

Run: `grep -r "FileService" --include="*.ets" .`

- [ ] **Step 2: 创建 feature/markdown/utils/FileUtil.ets**

```typescript
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { MarkdownFile } from '../class/MarkdownFile';

const BASE_DIR: string = '/md_docs';

export function getTargetDir(context: common.UIAbilityContext): string {
  return context.filesDir + BASE_DIR;
}

export function initDir(context: common.UIAbilityContext): void {
  const targetDir = getTargetDir(context);
  if (!fs.accessSync(targetDir)) {
    fs.mkdirSync(targetDir);
  }
}

export function loadLocalFiles(context: common.UIAbilityContext): MarkdownFile[] {
  const targetDir = getTargetDir(context);
  const fileList: MarkdownFile[] = [];
  try {
    if (fs.accessSync(targetDir)) {
      const fileNames: string[] = fs.listFileSync(targetDir);
      for (let fileName of fileNames) {
        const path: string = `${targetDir}/${fileName}`;
        const stats = fs.statSync(path);
        fileList.push(new MarkdownFile(fileName, '', path, stats.size, false, undefined, -1, '', 0, stats.mtime * 1000));
      }
    }
  } catch (err) {
    console.error('[FileUtil] 加载文件失败:', JSON.stringify(err));
  }
  return fileList;
}
```

- [ ] **Step 3: 更新所有引用 FileService 的文件**

将 `FileService.getInstance(context).loadLocalFiles()` 替换为 `loadLocalFiles(context)`。
将 `FileService.getInstance(context).getTargetDir()` 替换为 `getTargetDir(context)`。

- [ ] **Step 4: 删除 FileService.ets**

```bash
rm feature/markdown/service/FileService.ets
```

- [ ] **Step 5: 更新 feature/markdown/Index.ets**

移除 FileService 相关导出（如果有）。

- [ ] **Step 6: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 7: Commit**

```bash
git add feature/markdown/
git commit -m "refactor: replace FileService singleton with FileUtil functions"
```

### Task 21: MdDbService 优化 refreshGroupCache

**Files:**
- Modify: `feature/markdown/service/MdDbService.ets`

- [ ] **Step 1: 读取 MdDbService.ets 的 queryAll 和 refreshGroupCache**

- [ ] **Step 2: 在 queryAll 内部自动调用 refreshGroupCache**

在 `queryAll()` 方法开头添加 `await this.refreshGroupCache()`。这样调用方不需要手动调用。

- [ ] **Step 3: 检查所有手动调用 refreshGroupCache 的地方**

Run: `grep -r "refreshGroupCache" --include="*.ets" .`

逐步移除手动调用（在每个页面的 loadData 中）。每次移除一个，验证构建。

- [ ] **Step 4: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add feature/markdown/
git commit -m "refactor: auto-refresh group cache in MdDbService.queryAll"
```

---

## Phase 5: 消除 star 模块跨模块重复

### Task 22: 重构 StarredPage 使用 common 组件

**Files:**
- Modify: `feature/star/page/StarredPage.ets`

- [ ] **Step 1: 读取当前 StarredPage.ets 全文**

- [ ] **Step 2: 添加 imports**

```typescript
import { FileListCard, SearchBar, GroupSheetContent, EmptyState } from 'common';
```

- [ ] **Step 3: 替换 listCard builder 为 FileListCard**

将 `@Builder listCard` 替换为 `FileListCard` 组件调用。

- [ ] **Step 4: 替换 SearchBuilder 为 SearchBar**

将 `@Builder SearchBuilder` 替换为 `SearchBar` 组件调用。

- [ ] **Step 5: 替换 groupDialogBuilder 为 GroupSheetContent**

将 `@Builder groupDialogBuilder` 替换为 `GroupSheetContent` 组件调用。

- [ ] **Step 6: 替换空状态为 EmptyState**

将内联的空状态 UI 替换为 `EmptyState` 组件。

- [ ] **Step 7: 精简 toggleStar / assignToGroup / removeFromGroup**

将重复的 wrapper 方法精简为直接调用 MdDbService + dataSource 更新。

- [ ] **Step 8: 删除已替换的 builder 和方法**

删除 `listCard`、`SearchBuilder`、`groupDialogBuilder` 等。

- [ ] **Step 9: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 10: Commit**

```bash
git add feature/star/
git commit -m "refactor: StarredPage uses common components (FileListCard, SearchBar, GroupSheetContent)"
```

### Task 23: 重构 RecentPage 使用 common 组件

**Files:**
- Modify: `feature/star/page/RecentPage.ets`

- [ ] **Step 1: 读取当前 RecentPage.ets 全文**

- [ ] **Step 2: 添加 imports**

```typescript
import { FileListCard, SearchBar, EmptyState, formatRelativeTime } from 'common';
```

- [ ] **Step 3: 替换 listCard builder 为 FileListCard**

subtitle 使用 `formatRelativeTime(item.lastViewedAt)`。

- [ ] **Step 4: 替换 SearchBuilder 为 SearchBar**

- [ ] **Step 5: 替换空状态为 EmptyState**

- [ ] **Step 6: 删除 formatTime 方法（改用 common 的 formatRelativeTime）**

- [ ] **Step 7: 精简 toggleStar**

- [ ] **Step 8: 删除已替换的 builder 和方法**

- [ ] **Step 9: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 10: Commit**

```bash
git add feature/star/
git commit -m "refactor: RecentPage uses common components (FileListCard, SearchBar, formatRelativeTime)"
```

### Task 24: 重构 GroupDetailPage 使用 common 组件

**Files:**
- Modify: `feature/star/page/GroupDetailPage.ets`

- [ ] **Step 1: 读取当前 GroupDetailPage.ets 全文**

- [ ] **Step 2: 添加 imports**

```typescript
import { FileListCard, SearchBar, EmptyState, showDeleteConfirm } from 'common';
```

- [ ] **Step 3: 替换 listCard builder 为 FileListCard**

- [ ] **Step 4: 替换 SearchBuilder 为 SearchBar**

- [ ] **Step 5: 替换空状态为 EmptyState**

- [ ] **Step 6: 替换 showDeleteConfirm 为 common 的 showDeleteConfirm**

- [ ] **Step 7: 精简 toggleStar / assignToGroup / removeFromGroup**

- [ ] **Step 8: 删除已替换的 builder 和方法**

- [ ] **Step 9: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 10: Commit**

```bash
git add feature/star/
git commit -m "refactor: GroupDetailPage uses common components (FileListCard, SearchBar, showDeleteConfirm)"
```

### Task 25: 重构 GroupListPage 使用 common 组件

**Files:**
- Modify: `feature/star/page/GroupListPage.ets`

- [ ] **Step 1: 读取当前 GroupListPage.ets 全文**

- [ ] **Step 2: 添加 imports**

```typescript
import { SearchBar, EmptyState } from 'common';
```

- [ ] **Step 3: 替换 SearchBuilder 为 SearchBar**

- [ ] **Step 4: 替换空状态为 EmptyState**

- [ ] **Step 5: 精简 createGroup 方法**

- [ ] **Step 6: 删除已替换的 builder**

- [ ] **Step 7: 验证构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 8: Commit**

```bash
git add feature/star/
git commit -m "refactor: GroupListPage uses common components (SearchBar, EmptyState)"
```

---

## Final Verification

- [ ] **Step 1: 完整构建**

Run: `hvigorw assembleHap --mode module -p product=default`
Expected: BUILD SUCCESSFUL

- [ ] **Step 2: 检查文件行数**

Run:
```bash
wc -l feature/markdown/page/MdView.ets
wc -l feature/markdown/page/MarkdownViewerPage.ets
```
Expected: MdView < 450 lines, MarkdownViewerPage < 380 lines

- [ ] **Step 3: 检查 star 模块代码量**

Run: `wc -l feature/star/src/main/ets/page/*.ets`
Expected: 总量减少 50%+

- [ ] **Step 4: 检查无残留死代码**

Run: `find . -name "*.ets" -empty`
Expected: no results

- [ ] **Step 5: 最终 Commit**

```bash
git add -A
git commit -m "chore: code structure optimization complete"
```
