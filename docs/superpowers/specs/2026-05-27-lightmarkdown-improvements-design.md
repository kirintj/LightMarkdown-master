# LightMarkdown 改进设计

## 概述

LightMarkdown (com.markdownbox.cn v1.0.2) 是 HarmonyOS Next 平台的 Markdown 文件管理器。本次改进涵盖五个方向：完整编辑器、"我的" tab 改版、统一删除确认、文件重命名、网格卡片增强。

## 1. Markdown 编辑器

### 目标

让用户在应用内直接编辑 Markdown 文件，无需导出到外部编辑器。

### Phase 1（本次实现）

**入口：** MarkdownViewerPage 标题栏增加"编辑"按钮（铅笔图标）。

**编辑模式 UI：**
- 顶部 Tab 切换：`编辑 | 预览`
- 编辑 Tab：TextArea 源码编辑，占满内容区
- 预览 Tab：复用现有 `@luvi/lv-markdown-in` Markdown 组件渲染
- 底部 toolbar：快捷插入按钮（加粗 `**`、斜体 `*`、标题 `#`、无序列表 `-`、有序列表 `1.`、代码块 `` ``` ``、链接 `[]()`、图片 `![]()`）
- toolbar 点击后在 TextArea 光标位置插入对应语法

**保存机制：**
- 标题栏显示"保存"按钮，点击写回 sandboxPath 文件
- 脏检测（dirty flag）：内容修改后设置 dirty = true
- 离开页面时若 dirty，弹 AlertDialog 提示"未保存的更改将丢失，是否保存？"
- 三个按钮：保存 / 不保存 / 取消（留在编辑页）

**数据流：**
```
用户编辑 TextArea → dirty = true
点击保存 → fs.writeFile(sandboxPath, content) → dirty = false
离开页面 → dirty ? 弹确认 : 直接离开
```

### Phase 2（后续迭代）

- 语法高亮：正则着色渲染
- 左右分栏实时预览
- 图片插入：从相册选择 → 写入 sandbox → 插入 Markdown 图片语法
- 撤销/重做

### 关键文件

- `feature/markdown/src/main/ets/component/MarkdownViewerPage.ets` — 主要改造文件
- `feature/markdown/src/main/ets/class/MarkdownFile.ets` — 可能需要增加 content 缓存字段

---

## 2. "我的" Tab 改版

### 目标

将"我的"从只有一个深色模式设置扩展为完整的个人中心。

### 结构设计

```
┌─────────────────────────────┐
│ 标题栏: 我的                  │
├─────────────────────────────┤
│ [存储统计卡片]                │
│  已用空间: 2.3 MB            │
│  文件总数: 12                │
│  分组数量: 3                 │
├─────────────────────────────┤
│ 设置                         │
│  ├ 默认排序方式    [名称 ▾]   │
│  ├ 默认视图模式    [列表 ▾]   │
│  └ 深色模式        [开关]     │
├─────────────────────────────┤
│ 账户与同步                    │
│  ├ 登录/账号信息              │
│  ├ 云同步           [开关]    │
│  ├ 立即备份                  │
│  └ 恢复数据                  │
├─────────────────────────────┤
│ 关于                         │
│  ├ 版本 1.0.2   [检查更新]   │
│  ├ 使用指南                  │
│  ├ 意见反馈                  │
│  └ 隐私政策                  │
└─────────────────────────────┘
```

### 实现方案

- 使用 `List` + `ListItemGroup` 分区
- 存储统计：通过 `MdDbService` 查询 totalCount / groupCount，`fs.statSync` 计算 md_docs 目录大小
- 默认排序/视图：通过 `AppStorage` 持久化用户偏好，首页 `MdView.aboutToAppear()` 读取
- 账户+云同步：预留接口，Phase 1 先做 UI 骨架，云同步逻辑后续接入
- 关于页：版本号从 `app.json5` 读取

### 关键文件

- `feature/mine/src/main/ets/page/Mine.ets` — 主要改造文件
- 新增 `feature/mine/src/main/ets/page/AboutPage.ets`
- 新增 `feature/mine/src/main/ets/page/SettingsPage.ets`（可选，或直接内嵌在 Mine.ets）

---

## 3. 统一删除确认

### 问题

- MdView 列表页滑动删除：直接执行，无确认
- MarkdownViewerPage 详情页：有 AlertDialog 确认
- 行为不一致，用户可能误删

### 方案

所有删除操作统一使用 AlertDialog 确认：

```
标题: 确认删除
内容: 确定要删除「{fileName}」吗？此操作不可恢复。
按钮: [取消] [删除]
```

**涉及位置：**
- `MdView.ets` — 滑动删除的 `deleteIconOptions.onAction` 和 `fullDeleteOptions.onFullDeleteAction`
- `MultiSelectPage.ets` — 批量删除已有确认（保留）
- `MarkdownViewerPage.ets` — 已有确认（保留）

### 关键文件

- `feature/markdown/src/main/ets/page/MdView.ets` — 两处删除逻辑加确认弹窗

---

## 4. 文件重命名

### 目标

支持重命名已导入的 Markdown 文件。

### 入口

1. **MarkdownViewerPage 标题栏菜单** — 增加"重命名"选项
2. **MdView 列表页** — 长按菜单增加"重命名"（可选，或通过滑动操作）

### 交互流程

```
点击重命名 → 弹 AlertDialog (TextInput 预填当前文件名)
→ 用户修改 → 点击确认
→ 校验: 文件名非空、不含非法字符（`/ \ : * ? " < > |`）、不与现有文件重名、必须以 `.md` 结尾
→ 通过: fs.rename(sandboxPath, newPath) + 更新 DB + 更新 dataSource
→ 失败: 提示具体原因
```

### 数据更新

```
1. fs.renameSync(oldPath, newDir + "/" + newName)
2. MdDbService: UPDATE markdown_files SET sandboxPath=newPath, name=newName WHERE sandboxPath=oldPath
3. dataSource: 更新对应 item 的 name 和 sandboxPath
4. dataVersion++
```

### 关键文件

- `feature/markdown/src/main/ets/component/MarkdownViewerPage.ets` — 菜单增加重命名
- `feature/markdown/src/main/ets/service/MdDbService.ets` — 增加 renameFile 方法
- `feature/markdown/src/main/ets/class/MarkdownFile.ets` — FileDataSource 增加 updateItemPath 方法

---

## 5. 网格卡片增强

### 问题

当前网格视图卡片只显示文件名 + 分组 tag，信息密度低。

### 改进方案

卡片布局改为：

```
┌──────────────────────────┐
│ [icon]        [分组tag]   │
│                          │
│ 文件名.md                │
│ 1.2 KB · 2小时前浏览     │
│              [★ 收藏图标] │
└──────────────────────────┘
```

- 增加文件大小显示
- 增加最后浏览时间（相对时间：刚刚 / N分钟前 / N小时前 / N天前）
- 收藏图标移到卡片内右下角
- 保留流光特效（UV_BACKGROUND_FLOW_LIGHT）

### 时间格式化工具函数

```typescript
function formatRelativeTime(timestamp: number): string {
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

### 关键文件

- `feature/markdown/src/main/ets/page/MdView.ets` — `gridCard` builder 改造

---

## 不做的事情（YAGNI）

- 不重构去重代码（groupSheetBuilder / share 逻辑等）— 用户明确说先不改
- 不加全文搜索 — 用户说只搜文件名
- 不加云同步具体实现 — Phase 1 先做 UI 骨架
- 不加语法高亮 — Phase 2 再做

## 验证标准

1. 编辑器：能打开 → 编辑 → 保存 → 文件内容更新
2. 编辑器 dirty 检测：修改后离开 → 弹确认 → 选择保存/不保存/取消均正确
3. "我的" tab：显示存储统计、设置项可切换、关于页可进入
4. 删除确认：列表页滑动删除弹确认框，取消不删除
5. 重命名：改名后文件名更新、DB 同步、列表刷新
6. 网格卡片：显示文件大小和相对时间，布局不溢出
