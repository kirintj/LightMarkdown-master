# LightMarkdown 代码结构优化设计

## 概述

对 LightMarkdown (com.markdownbox.cn v1.0.2) 进行文件结构和代码架构优化。采用自底向上策略：清理 common → 提取公共组件到 common → 拆分大文件 → 整理服务层 → 消除 star 模块跨模块重复。

## 依赖关系

```
common → (无)          ← 所有通用组件放这里，参数化解耦
markdown → common
star → markdown, common
mine → markdown, common
entry → 全部
```

所有通用组件放 common 模块，通过参数接口（primitive types）解耦，不引用 markdown 的 class 类型。

---

## Phase 1: Common 模块清理

### 删除死代码

- `common/src/main/ets/component/SearchTwo.ets` — 空文件，删除
- `common/src/main/ets/service/GroupGlobalService.ets` — 空文件，删除
- `common/src/main/ets/database/MarkdownFile.ets` — 315 行 RDB 演示代码，应用未引用，删除
- 删除 `common/src/main/ets/database/` 目录（删除后为空）
- 删除 `common/src/main/ets/service/` 目录（删除后为空）

### 统一 MarkdownFile 定义

- 删除 `common/src/main/ets/model/MarkdownFile.ets`（6 行 interface）
- 所有模块统一使用 `feature/markdown/class/MarkdownFile.ets` 导出的 class
- 检查所有 import 路径，确保无引用 common 里的 MarkdownFile
- 更新 `common/Index.ets`，移除相关导出（如果有的话）

### 命名/目录修正

| 原路径 | 新路径 | 原因 |
|--------|--------|------|
| `feature/markdown/component/SideCompoent.ets` | `feature/markdown/component/SideComponent.ets` | 拼写修复 |
| `feature/markdown/component/MarkdownViewerPage.ets` | `feature/markdown/page/MarkdownViewerPage.ets` | 本质是页面，移到 page/ |
| `feature/mine/settingpage/DarkModeSetting.ets` | `feature/mine/page/DarkModeSetting.ets` | 统一目录 |
| `feature/mine/viewmodel/ColorModeChangeFunctions.ets` | `feature/mine/utils/ColorModeChangeFunctions.ets` | 更准确的分类 |

移动文件后更新所有 import 路径。删除空的 `settingpage/` 和 `viewmodel/` 目录。

---

## Phase 2: 提取公共组件到 common（参数化解耦，无类型依赖）

### 新增 `common/src/main/ets/util/TimeUtil.ets`

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

### 新增 `common/src/main/ets/component/DeleteConfirmDialog.ets`

统一删除确认弹窗：
- 参数：`fileName: string`、`onConfirm: () => void`
- 使用 `AlertDialog` 实现

### 新增 `common/src/main/ets/component/EmptyState.ets`

通用空状态组件：
- 参数：`icon: Resource`、`text: string`
- 居中显示 icon + 文字

### 新增 `common/src/main/ets/component/SearchBar.ets`

统一搜索栏，替代 5 处重复的 SearchBuilder：
- 参数：`placeholder: string`、`onSearch: (keyword: string) => void`、`onChange: (keyword: string) => void`
- 纯 UI，无类型依赖

### 新增 `common/src/main/ets/component/FileListCard.ets`

统一文件列表卡片，替代 6 处重复的 listCard builder：
- 参数：`name: string`、`subtitle: string`、`isStar: boolean`、`groupId: number`、`groupName: string`、`onTap`、`onStar`、`onDelete`
- 纯 primitive 参数，不引用 MarkdownFile class
- 使用方负责把 MarkdownFile 转成参数传入

### 新增 `common/src/main/ets/component/GroupSheetContent.ets`

统一分组选择 sheet，替代 7 处重复的 groupSheetBuilder：
- 参数：`currentGroupId: number`、`groups: Array<{id: number, name: string}>`、`onAssign: (id, name) => void`、`onRemove: () => void`、`onCreate: (name) => void`
- 纯 primitive 参数，不引用 FileGroup class
- 包含：创建新分组输入框 + 分组列表 + 移出分组按钮

### 更新 `common/Index.ets` 导出

新增导出：`TimeUtil`、`DeleteConfirmDialog`、`EmptyState`、`SearchBar`、`FileListCard`、`GroupSheetContent`

---

## Phase 3: 拆分大文件

### MdView.ets（1150 行 → ~400 行）

提取到 `feature/markdown/src/main/ets/component/`：

**FileGridCard.ets** — 网格模式文件卡片
- 参数：`file: MarkdownFile`、`onTap`、`onStar`、`onDelete`
- 显示：icon + 分组 tag、文件名、大小 + 相对时间、收藏图标
- 保留流光特效（UV_BACKGROUND_FLOW_LIGHT）

**FileActionBar.ets** — 底部操作栏
- 参数：`file: MarkdownFile`、`onGroup`、`onStar`、`onDelete`
- 三个按钮：分组、收藏、删除

MdView 保留：数据加载、搜索过滤逻辑、列表/网格容器切换、Sheet 管理

列表模式的 listCard 改用 common 的 `FileListCard`。搜索栏改用 common 的 `SearchBar`。分组 sheet 改用 common 的 `GroupSheetContent`。

### MarkdownViewerPage.ets（638 行 → ~350 行）

- `RenameDialog.ets` 独立为 `feature/markdown/component/RenameDialog.ets`
- group sheet 逻辑改用 common 的 `GroupSheetContent`
- 删除确认改用 common 的 `DeleteConfirmDialog`

### MultiSelectPage.ets（540 行 → ~300 行）

提取 `BatchToolbar.ets`：
- 参数：`selectedCount`、`onShare`、`onGroup`、`onStar`、`onDelete`、`onCancel`
- 底部批量操作工具栏

---

## Phase 4: 服务层整理

### FileService.ets 处理

当前 `FileService.ets`（61 行）只做文件加载和目录初始化，职责与 MdDbService 重叠。

方案：将 `loadFiles()` 和 `initDir()` 移入新文件 `feature/markdown/utils/FileUtil.ets`，删除 `FileService.ets`。更新所有引用。

### MdDbService.ets 保持不变

463 行但职责单一（RDB 操作），不拆分。唯一改进：优化 `refreshGroupCache` 调用时机（在 `queryAll` 内部自动刷新，而非手动调用）。

### Logger.ets 保持不变

保留现有 Logger 工具，本次不统一替换 console 调用（YAGNI）。

---

## Phase 5: 消除 star 模块跨模块重复

star 模块 60-65% 代码与 markdown 结构重复。Phase 2 提取的 common 组件可直接复用。

### StarredPage.ets（375行 → ~150行）

- listCard → 使用 common 的 `FileListCard`
- groupDialogBuilder → 使用 common 的 `GroupSheetContent`
- SearchBuilder → 使用 common 的 `SearchBar`
- toggleStar / assignToGroup / removeFromGroup → 精简为直接调 MdDbService（删除重复的 wrapper 方法）
- 删除重复的 applyFilter、loadData boilerplate

### RecentPage.ets（225行 → ~100行）

- listCard → 使用 common 的 `FileListCard`
- formatTime → 使用 common 的 `TimeUtil`
- toggleStar → 精简
- SearchBuilder → 使用 common 的 `SearchBar`

### GroupDetailPage.ets（416行 → ~200行）

- listCard → 使用 common 的 `FileListCard`
- toggleStar / assignToGroup → 精简
- showDeleteConfirm → 使用 common 的 `DeleteConfirmDialog`
- SearchBuilder → 使用 common 的 `SearchBar`

### GroupListPage.ets（303行 → ~150行）

- createGroup → 精简
- SearchBuilder → 使用 common 的 `SearchBar`
- EmptyState → 使用 common 的 `EmptyState`

---

## 不做的事情（YAGNI）

- 不统一替换 console → Logger
- 不拆分 MdDbService（职责单一，拆分反而增加复杂度）
- Star.ets 的图表组件不移动（star 独有功能）
- 不新建 shared 模块（所有通用组件放 common，参数化解耦）

## 验证标准

1. 构建通过：`hvigorw assembleHap` 无错误
2. 功能不退化：文件导入、查看、分组、收藏、删除、重命名、分享均正常
3. 无死代码残留：空文件删除后无编译错误
4. 无重复定义：MarkdownFile 只有一个来源
5. 大文件瘦身：MdView < 450 行，MarkdownViewerPage < 380 行
6. 跨模块重复消除：star 模块代码量减少 50%+
7. 无循环依赖
