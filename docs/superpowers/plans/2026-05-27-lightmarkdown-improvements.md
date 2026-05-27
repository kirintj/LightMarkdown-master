# LightMarkdown 改进实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 LightMarkdown 添加编辑器、改版"我的" tab、统一删除确认、文件重命名、增强网格卡片。

**Architecture:** 改动集中在现有 feature 模块内，不新增模块。编辑器改造 MarkdownViewerPage，"我的"改版 Mine.ets，其余为 MdView.ets 局部修改。

**Tech Stack:** HarmonyOS Next, ArkTS, ArkUI, HDS Design Kit, @luvi/lv-markdown-in, relationalStore

---

## 文件结构

### 修改的文件

| 文件 | 改动 |
|------|------|
| `feature/markdown/src/main/ets/component/MarkdownViewerPage.ets` | 编辑器模式（TextArea + Tab 切换 + toolbar + 保存 + dirty 检测）、重命名菜单 |
| `feature/markdown/src/main/ets/page/MdView.ets` | 删除确认弹窗、网格卡片增强（文件大小+相对时间） |
| `feature/markdown/src/main/ets/service/MdDbService.ets` | 新增 `renameFile()` 方法 |
| `feature/markdown/src/main/ets/class/MarkdownFile.ets` | FileDataSource 新增 `updateItemPath()` 方法 |
| `feature/mine/src/main/ets/page/Mine.ets` | 全面改版：存储统计、设置、账户、关于 |
| `feature/markdown/Index.ets` | 导出新增的工具函数（如有） |

### 新增的文件

| 文件 | 用途 |
|------|------|
| `feature/mine/src/main/ets/page/AboutPage.ets` | 关于页面 |

---

## Task 1: 文件重命名 — MdDbService + FileDataSource

**Files:**
- Modify: `feature/markdown/src/main/ets/service/MdDbService.ets`
- Modify: `feature/markdown/src/main/ets/class/MarkdownFile.ets`

- [ ] **Step 1: 在 MdDbService 添加 renameFile 方法**

在 `MdDbService.ets` 的 `removeFileGroup` 方法之后添加：

```typescript
async renameFile(oldPath: string, newName: string): Promise<string> {
  const store = this.ensureStore();
  const lastSlash = oldPath.lastIndexOf('/');
  const newDir = oldPath.substring(0, lastSlash + 1);
  const newPath = newDir + newName;

  // 校验新文件名
  if (!newName.trim()) {
    throw new Error('文件名不能为空');
  }
  if (!newName.endsWith('.md')) {
    throw new Error('文件名必须以 .md 结尾');
  }
  const illegalChars = /[\\/:*?"<>|]/;
  if (illegalChars.test(newName)) {
    throw new Error('文件名包含非法字符');
  }

  // 检查是否重名（且不是自身）
  if (oldPath !== newPath) {
    const existing = await this.queryByPath(newPath);
    if (existing) {
      throw new Error('已存在同名文件');
    }
    // 重命名文件系统文件
    const { fileIo as fs } = await import('@kit.CoreFileKit');
    fs.renameSync(oldPath, newPath);
  }

  // 更新数据库
  const value: relationalStore.ValuesBucket = {
    sandboxPath: newPath,
    name: newName
  };
  const predicates = new relationalStore.RdbPredicates('markdown_files');
  predicates.equalTo('sandboxPath', oldPath);
  await store.update(value, predicates);

  return newPath;
}
```

- [ ] **Step 2: 在 FileDataSource 添加 updateItemPath 方法**

在 `FileDataSource.ets` 的 `updateItemGroup` 方法之后添加：

```typescript
public updateItemPath(oldPath: string, newName: string, newPath: string): void {
  const index = this.getIndexByPath(oldPath);
  if (index >= 0) {
    this.dataArray[index].name = newName;
    this.dataArray[index].sandboxPath = newPath;
    this.notifyDataChange(index);
  }
}
```

- [ ] **Step 3: 验证编译通过**

在 DevEco Studio 中 build 项目，确认无编译错误。

---

## Task 2: 文件重命名 — UI 入口

**Files:**
- Modify: `feature/markdown/src/main/ets/component/MarkdownViewerPage.ets:515-537`（titleBar menu 区域）

- [ ] **Step 1: 添加重命名状态变量**

在 `MarkdownViewerPage` 组件的 `@State showGroupSheet: boolean = false;` 之后添加：

```typescript
@State showRenameDialog: boolean = false;
@State renameInput: string = '';
```

- [ ] **Step 2: 添加重命名方法**

在 `showDeleteConfirm()` 方法之后添加：

```typescript
private showRenameInputDialog(): void {
  this.renameInput = this.fileData.name;
  this.getUIContext().showAlertDialog({
    title: '重命名',
    message: '输入新的文件名',
    autoCancel: true,
    alignment: DialogAlignment.Center,
    primaryButton: {
      value: '取消',
      action: () => {}
    },
    secondaryButton: {
      value: '确认',
      action: () => { this.doRename(); }
    },
    builder: () => {
      TextInput({ text: this.renameInput })
        .onChange((value: string) => { this.renameInput = value; })
        .width('100%')
        .margin({ top: 8 })
    }
  });
}

private async doRename(): Promise<void> {
  const newName = this.renameInput.trim();
  if (!newName || newName === this.fileData.name) return;
  try {
    const dbService = MdDbService.getInstance(this.context);
    const newPath = await dbService.renameFile(this.fileData.sandboxPath, newName);
    this.dataSource.updateItemPath(this.fileData.sandboxPath, newName, newPath);
    this.fileData = new MarkdownFile(
      newName, this.fileData.uri, newPath, 0,
      this.fileData.isStar, this.fileData.size,
      this.fileData.groupId, this.fileData.groupName,
      this.fileData.lastViewedAt, this.fileData.createdAt
    );
    this.dataVersion++;
    this.getUIContext().getPromptAction().showToast({ message: '重命名成功' });
  } catch (e) {
    const msg = e instanceof Error ? e.message : '重命名失败';
    this.getUIContext().getPromptAction().showToast({ message: msg });
  }
}
```

- [ ] **Step 3: 在 titleBar menu 中添加重命名入口**

将 `MarkdownViewerPage` 的 `build()` 方法中的 `titleBar` menu 部分从：

```typescript
menu: {
  value: [{
    content: {
      label: '分享',
      icon: $r('sys.symbol.share'),
      isEnabled: true,
      action: () => { this.doSystemShare(); }
    }
  }]
}
```

改为：

```typescript
menu: {
  value: [
    {
      content: {
        label: '重命名',
        icon: $r('sys.symbol.pencil'),
        isEnabled: true,
        action: () => { this.showRenameInputDialog(); }
      }
    },
    {
      content: {
        label: '分享',
        icon: $r('sys.symbol.share'),
        isEnabled: true,
        action: () => { this.doSystemShare(); }
      }
    }
  ]
}
```

- [ ] **Step 4: 验证**

运行 app → 打开一个文件 → 点击标题栏菜单 → 看到"重命名"选项 → 点击 → 弹出对话框 → 输入新名字 → 确认 → 文件名更新。

---

## Task 3: 统一删除确认

**Files:**
- Modify: `feature/markdown/src/main/ets/page/MdView.ets:866-905`（收藏 tab 滑动删除）
- Modify: `feature/markdown/src/main/ets/page/MdView.ets:982-1024`（全部 tab 滑动删除）

- [ ] **Step 1: 封装删除确认方法**

在 `MdView` 组件的 `createAndAssignGroup()` 方法之后添加：

```typescript
private confirmDeleteFile(item: MarkdownFile): void {
  this.getUIContext().showAlertDialog({
    title: '确认删除',
    message: `确定要删除「${item.name}」吗？此操作不可恢复。`,
    autoCancel: true,
    alignment: DialogAlignment.Center,
    primaryButton: {
      value: '取消',
      action: () => {}
    },
    secondaryButton: {
      value: '删除',
      action: () => { this.executeDeleteFile(item); }
    }
  });
}

private executeDeleteFile(item: MarkdownFile): void {
  const index = this.dataSource.getIndex(item);
  if (index >= 0) {
    try {
      fs.unlinkSync(item.sandboxPath);
      MdDbService.getInstance(this.context).deleteFile(item.sandboxPath);
      this.dataSource.removeItem(index);
      this.dataVersion++;
      this.refreshData();
    } catch (e) {
      console.error("删除文件失败:", JSON.stringify(e));
    }
  }
}
```

- [ ] **Step 2: 替换收藏 tab 滑动删除逻辑**

在 `MdView.ets` 中，收藏 tab 的 `deleteIconOptions.onAction` 部分（约 866-885 行），将：

```typescript
deleteIconOptions: {
  backgroundColor: '#FF5A5F',
  iconColor: Color.White,
  onAction: () => {
    promptAction.openToast({ message: '删除成功', duration: 100 }).catch(() => {});
    this.getUIContext()?.animateTo({ duration: 350 }, () => {
      const index = this.dataSource.getIndex(item);
      if (index >= 0) {
        try {
          fs.unlinkSync(item.sandboxPath);
          MdDbService.getInstance(this.context).deleteFile(item.sandboxPath);
          this.dataSource.removeItem(index);
          this.dataVersion++;
          this.refreshData();
        } catch (e) {
          console.error("删除文件失败:", JSON.stringify(e));
        }
      }
    });
  },
},
```

改为：

```typescript
deleteIconOptions: {
  backgroundColor: '#FF5A5F',
  iconColor: Color.White,
  onAction: () => {
    this.confirmDeleteFile(item);
  },
},
```

- [ ] **Step 3: 替换收藏 tab 的 fullDeleteOptions**

将收藏 tab 的 `fullDeleteOptions.onFullDeleteAction` 同样替换为调用 `this.confirmDeleteFile(item)`。

- [ ] **Step 4: 替换全部 tab 滑动删除逻辑**

对全部 tab 的 `deleteIconOptions.onAction` 和 `fullDeleteOptions.onFullDeleteAction` 做同样的替换（约 982-1024 行）。

- [ ] **Step 5: 验证**

运行 app → 在列表页左滑文件 → 点删除 → 弹确认框 → 取消 → 文件保留。再试一次 → 确认删除 → 文件消失。

---

## Task 4: 网格卡片增强

**Files:**
- Modify: `feature/markdown/src/main/ets/page/MdView.ets:382-439`（gridCard builder）

- [ ] **Step 1: 添加相对时间格式化函数**

在 `MdView` 组件中添加私有方法：

```typescript
private formatRelativeTime(timestamp: number): string {
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

- [ ] **Step 2: 改造 gridCard builder**

将 `MdView.ets` 的 `gridCard` builder（约 382-439 行）替换为：

```typescript
@Builder
gridCard(item: MarkdownFile): void {
  Stack({ alignContent: Alignment.TopEnd }) {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.doc_plaintext_fill'))
          .fontSize(20)
          .fontColor(item.isStar ? ['#FFC83D'] : [$r('sys.color.white')]);
        Text(item.groupName ? item.groupName : '')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.white'))
          .backgroundColor($r('sys.color.confirm'))
          .borderRadius(8)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .visibility(item.groupName ? Visibility.Visible : Visibility.Hidden);
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Text(item.name)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.white'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.LEFT)
        .lineHeight(24)
        .margin({ top: 8 })

      Row() {
        Text(item.size)
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.7)')
        if (this.formatRelativeTime(item.lastViewedAt)) {
          Text(' · ')
            .fontSize(11)
            .fontColor('rgba(255,255,255,0.5)')
          Text(this.formatRelativeTime(item.lastViewedAt))
            .fontSize(11)
            .fontColor('rgba(255,255,255,0.7)')
        }
      }
      .margin({ top: 4 })

      Row() {
        Blank()
        if (item.isStar) {
          SymbolGlyph($r('sys.symbol.star_fill'))
            .fontSize(14)
            .fontColor(['#FFC83D']);
        }
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width('100%')
    .height(undefined)
    .padding({ left: 12, right: 12, top: 14, bottom: 12 })
    .alignItems(HorizontalAlign.Center)
  }
  .visualEffect(new hdsEffect.HdsEffectBuilder()
    .shaderEffect({
      effectType: hdsEffect.EffectType.UV_BACKGROUND_FLOW_LIGHT,
      animation: {
        duration: 10000,
        iterations: -1,
        autoPlay: true,
        curve: Curve.FastOutSlowIn,
        onFinish: () => {
          console.info('Succeeded in finishing');
        }
      },
      controller: this.controller
    })
    .buildEffect())
  .borderRadius(16)
  .width('100%')
}
```

- [ ] **Step 3: 验证**

运行 app → 切换到网格视图 → 卡片显示文件大小、最后浏览时间、收藏图标。布局不溢出。

---

## Task 5: Markdown 编辑器 — 状态与数据层

**Files:**
- Modify: `feature/markdown/src/main/ets/component/MarkdownViewerPage.ets`

- [ ] **Step 1: 添加编辑器状态变量**

在 `MarkdownViewerPage` 组件的 `@State showGroupSheet: boolean = false;` 之后添加：

```typescript
@State isEditing: boolean = false;
@State editContent: string = '';
@State isDirty: boolean = false;
@State editorTabIndex: number = 0;
```

- [ ] **Step 2: 添加编辑器相关方法**

在 `toggleStar()` 方法之后添加：

```typescript
private async enterEditMode(): Promise<void> {
  try {
    const content = await fs.readText(this.fileData.sandboxPath);
    this.editContent = content;
    this.isEditing = true;
    this.isDirty = false;
    this.editorTabIndex = 0;
  } catch (e) {
    console.error('[MarkdownViewerPage] 读取文件失败: ' + JSON.stringify(e));
    this.getUIContext().getPromptAction().showToast({ message: '无法打开编辑' });
  }
}

private async saveFile(): Promise<void> {
  try {
    const { fileIo as fsKit } = await import('@kit.CoreFileKit');
    const fd = fsKit.openSync(this.fileData.sandboxPath, fsKit.OpenMode.WRITE_ONLY | fsKit.OpenMode.CREATE);
    fsKit.writeSync(fd.fd, this.editContent);
    fsKit.closeSync(fd);
    this.isDirty = false;
    this.getUIContext().getPromptAction().showToast({ message: '已保存' });
  } catch (e) {
    console.error('[MarkdownViewerPage] 保存失败: ' + JSON.stringify(e));
    this.getUIContext().getPromptAction().showToast({ message: '保存失败' });
  }
}

private exitEditMode(): void {
  if (this.isDirty) {
    this.getUIContext().showAlertDialog({
      title: '未保存的更改',
      message: '当前有未保存的修改，是否保存？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '不保存',
        action: () => {
          this.isEditing = false;
          this.isDirty = false;
        }
      },
      // 注：ArkUI AlertDialog 不支持三按钮，用 builder 自定义
    });
  } else {
    this.isEditing = false;
  }
}

private onEditContentChange(value: string): void {
  this.editContent = value;
  this.isDirty = true;
}

private insertMarkdownSyntax(prefix: string, suffix: string): void {
  // 在当前内容末尾插入（简化版本，后续可支持光标位置插入）
  this.editContent += prefix + suffix;
  this.isDirty = true;
}
```

- [ ] **Step 3: 验证编译**

Build 项目，确认无编译错误。

---

## Task 6: Markdown 编辑器 — UI

**Files:**
- Modify: `feature/markdown/src/main/ets/component/MarkdownViewerPage.ets`（build 方法和 TabBarBuilder）

- [ ] **Step 1: 添加编辑模式下的 toolbar builder**

在 `TabBarBuilder` 之前添加：

```typescript
@Builder
editorToolbar(): void {
  Row({ space: 0 }) {
    this.toolbarBtn('B', '**', '**')
    this.toolbarBtn('I', '*', '*')
    this.toolbarBtn('H', '\n## ', '')
    this.toolbarBtn('•', '\n- ', '')
    this.toolbarBtn('1.', '\n1. ', '')
    this.toolbarBtn('<>', '\n```\n', '\n```\n')
    this.toolbarBtn('[]', '[', '](url)')
    this.toolbarBtn('🖼', '![', '](url)')
  }
  .width('100%')
  .height(44)
  .padding({ left: 8, right: 8 })
  .justifyContent(FlexAlign.SpaceAround)
  .backgroundColor($r('sys.color.comp_background_primary'))
}

@Builder
toolbarBtn(label: string, prefix: string, suffix: string): void {
  Text(label)
    .fontSize(14)
    .fontWeight(FontWeight.Bold)
    .fontColor($r('sys.color.font_primary'))
    .width(36)
    .height(36)
    .textAlign(TextAlign.Center)
    .borderRadius(8)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .onClick(() => { this.insertMarkdownSyntax(prefix, suffix); })
}
```

- [ ] **Step 2: 添加编辑内容区 builder**

在 `editorToolbar` 之后添加：

```typescript
@Builder
editingContent(): void {
  Column() {
    Blank().width('100%').height(this.blankHeight);

    if (this.editorTabIndex === 0) {
      // 编辑模式
      TextArea({ text: this.editContent, placeholder: '输入 Markdown 内容...' })
        .onChange((value: string) => { this.onEditContentChange(value); })
        .width('100%')
        .layoutWeight(1)
        .fontSize(15)
        .fontFamily('monospace')
        .backgroundColor(Color.Transparent)
    } else {
      // 预览模式
      Scroll() {
        Column() {
          if (this.showMarkdown) {
            Markdown({
              mode: "sandbox",
              sandboxPath: this.fileData.sandboxPath,
              callback: {
                complete: () => {},
                fail: (code: number, msg: string) => {
                  console.error('[Editor] 预览失败: ' + code + ', ' + msg);
                }
              },
              controller: this.controller
            })
              .width('100%')
          }
        }.padding(16).width('100%');
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .layoutWeight(1)
    }

    this.editorToolbar();
  }
  .width('100%')
  .height('100%')
}
```

- [ ] **Step 3: 修改 build 方法支持编辑/查看切换**

将 `MarkdownViewerPage` 的 `build()` 方法改为根据 `isEditing` 状态切换：

```typescript
build() {
  HdsNavDestination() {
    if (this.isEditing) {
      // 编辑模式
      HdsTabs() {
        TabContent() {
          this.editingContent();
        }
        .tabBar(new BottomTabBarStyle({
          normal: new SymbolGlyphModifier($r('sys.symbol.pencil')),
        }, '编辑'))

        TabContent() {
          this.editingContent();
        }
        .tabBar(new BottomTabBarStyle({
          normal: new SymbolGlyphModifier($r('sys.symbol.eye')),
        }, '预览'))
      }
      .barWidth(200)
      .barFloatingStyle({
        barBottomMargin: this.safeBottom,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        },
        adaptToHandedness: true,
      })
      .barOverlap(true)
      .barPosition(BarPosition.End)
      .vertical(false)
      .scrollable(false)
      .backgroundColor(Color.Transparent)
      .onChange((index: number) => {
        this.editorTabIndex = index;
      })
    } else {
      // 查看模式（原有代码）
      HdsTabs() {
        TabContent() {
          this.viewingContent();
        }
        .tabBar(this.TabBarBuilder(this.fileData))
      }
      .barWidth(200)
      .barFloatingStyle({
        barBottomMargin: this.safeBottom,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        },
        adaptToHandedness: true,
      })
      .barOverlap(true)
      .barPosition(BarPosition.End)
      .vertical(false)
      .scrollable(false)
      .backgroundColor(Color.Transparent)
    }
  }
  .titleBar({
    content: {
      title: {
        mainTitle: this.fileData.name + (this.isDirty ? ' *' : '')
      },
      menu: {
        value: this.isEditing
          ? [
              {
                content: {
                  label: '保存',
                  icon: $r('sys.symbol.checkmark'),
                  isEnabled: this.isDirty,
                  action: () => { this.saveFile(); }
                }
              },
              {
                content: {
                  label: '退出编辑',
                  icon: $r('sys.symbol.xmark'),
                  action: () => { this.exitEditMode(); }
                }
              }
            ]
          : [
              {
                content: {
                  label: '编辑',
                  icon: $r('sys.symbol.pencil'),
                  action: () => { this.enterEditMode(); }
                }
              },
              {
                content: {
                  label: '重命名',
                  icon: $r('sys.symbol.textformat'),
                  action: () => { this.showRenameInputDialog(); }
                }
              },
              {
                content: {
                  label: '分享',
                  icon: $r('sys.symbol.share'),
                  isEnabled: true,
                  action: () => { this.doSystemShare(); }
                }
              }
            ]
      }
    },
    style: {
      scrollEffectOpts: { scrollEffectType: ScrollEffectType.GRADIENT_BLUR },
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
      },
    },
    avoidLayoutSafeArea: true
  })
  .bindSheet($$this.showGroupSheet, this.groupSheetBuilder(), {
    height: SheetSize.MEDIUM,
    showClose: false,
    enableFloatingDragBar: true,
  });
}
```

- [ ] **Step 4: 验证**

运行 app → 打开文件 → 点编辑 → 出现 TextArea + toolbar → 输入内容 → 切换预览 → 保存 → 退出编辑。测试 dirty 检测：修改后直接退出 → 弹确认。

---

## Task 7: "我的" Tab 改版

**Files:**
- Modify: `feature/mine/src/main/ets/page/Mine.ets`
- Create: `feature/mine/src/main/ets/page/AboutPage.ets`
- Modify: `feature/mine/Index.ets`

- [ ] **Step 1: 添加存储统计状态和加载方法**

重写 `Mine.ets` 的状态变量和 `aboutToAppear`：

```typescript
import { HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType,
  hdsMaterial} from "@kit.UIDesignKit";
import { ConfigurationConstant } from "@kit.AbilityKit";
import { CardItem } from "common";
import { MdDbService, FileDataSource, MarkdownFile } from 'markdown';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';

const TITLE_BAR_HEIGHT_FREE: number = 56;

@Component
export struct Mine {
  @State blankHeight: number = TITLE_BAR_HEIGHT_FREE;
  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0
  @Consume('pathStack') pathStack: NavPathStack;
  @Consume('dataSource') dataSource: FileDataSource;
  @Consume('dataVersion') @Watch('onDataVersionChange') dataVersion: number;
  @State titleMode: HdsNavDestinationTitleMode = HdsNavDestinationTitleMode.MINI;
  @StorageProp('currentColorMode') isDarkMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @State totalCount: number = 0;
  @State groupCount: number = 0;
  @State storageUsed: string = '计算中...';
  @State sortMode: number = 0;
  @State defaultViewIsGrid: boolean = false;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  async aboutToAppear(): Promise<void> {
    await this.loadStats();
    this.sortMode = AppStorage.get<number>('defaultSortMode') ?? 0;
    this.defaultViewIsGrid = AppStorage.get<boolean>('defaultViewIsGrid') ?? false;
  }

  onDataVersionChange(): void {
    this.loadStats();
  }

  private async loadStats(): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.init();
      this.totalCount = await dbService.getTotalCount();
      this.groupCount = await dbService.getGroupCount();
      this.storageUsed = this.calcStorageUsed();
    } catch (e) {
      console.error('[Mine] 加载统计失败:', JSON.stringify(e));
    }
  }

  private calcStorageUsed(): string {
    try {
      const targetDir = this.context.filesDir + "/md_docs";
      if (!fs.accessSync(targetDir)) return '0 KB';
      const fileNames = fs.listFileSync(targetDir);
      let totalBytes = 0;
      for (const name of fileNames) {
        const stats = fs.statSync(`${targetDir}/${name}`);
        totalBytes += stats.size;
      }
      if (totalBytes < 1024) return `${totalBytes} B`;
      if (totalBytes < 1024 * 1024) return `${(totalBytes / 1024).toFixed(1)} KB`;
      return `${(totalBytes / (1024 * 1024)).toFixed(1)} MB`;
    } catch (e) {
      return '未知';
    }
  }

  private saveDefaultSort(mode: number): void {
    this.sortMode = mode;
    AppStorage.setOrCreate<number>('defaultSortMode', mode);
  }

  private saveDefaultView(isGrid: boolean): void {
    this.defaultViewIsGrid = isGrid;
    AppStorage.setOrCreate<boolean>('defaultViewIsGrid', isGrid);
  }
```

- [ ] **Step 2: 重写 build 方法**

```typescript
  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }){
        Scroll(){
          Column(){
            Blank().width('100%').height(this.blankHeight + this.safeTop)

            // 存储统计卡片
            Column() {
              Row() {
                Column() {
                  Text(this.totalCount.toString())
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('sys.color.brand'))
                  Text('文件总数')
                    .fontSize(12)
                    .fontColor($r('sys.color.font_secondary'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Text(this.groupCount.toString())
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('sys.color.confirm'))
                  Text('分组数量')
                    .fontSize(12)
                    .fontColor($r('sys.color.font_secondary'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Text(this.storageUsed)
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('sys.color.alert'))
                  Text('已用空间')
                    .fontSize(12)
                    .fontColor($r('sys.color.font_secondary'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .padding(16)
            }
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius(16)
            .padding(12)

            // 设置区
            Text('设置')
              .fontSize(14)
              .fontColor($r('sys.color.font_secondary'))
              .width('100%')
              .margin({ top: 20, bottom: 8 })

            List({ space: 0 }) {
              ListItemGroup() {
                ListItem({ style: ListItemStyle.CARD }) {
                  Row() {
                    Text('默认排序方式')
                      .fontSize(16)
                      .fontWeight(500)
                      .layoutWeight(1)
                      .padding({ left: 16 })
                    Select([
                      { value: '名称' },
                      { value: '时间' },
                      { value: '分组' }
                    ])
                      .selected(this.sortMode)
                      .value(this.sortMode === 0 ? '名称' : this.sortMode === 1 ? '时间' : '分组')
                      .onSelect((index: number) => { this.saveDefaultSort(index); })
                      .margin({ right: 8 })
                  }
                  .height(56)
                  .width('100%')
                }
                .height(undefined)

                ListItem({ style: ListItemStyle.CARD }) {
                  Row() {
                    Text('默认视图模式')
                      .fontSize(16)
                      .fontWeight(500)
                      .layoutWeight(1)
                      .padding({ left: 16 })
                    Select([
                      { value: '列表' },
                      { value: '网格' }
                    ])
                      .selected(this.defaultViewIsGrid ? 1 : 0)
                      .value(this.defaultViewIsGrid ? '网格' : '列表')
                      .onSelect((index: number) => { this.saveDefaultView(index === 1); })
                      .margin({ right: 8 })
                  }
                  .height(56)
                  .width('100%')
                }
                .height(undefined)

                ListItem({ style: ListItemStyle.CARD }) {
                  CardItem({
                    isShow: true,
                    textContent: '深色模式',
                    symbolSrc: $r('sys.symbol.circle_filled_and_circle'),
                    onclick: () => {
                      this.pathStack.pushPathByName('DarkModeSetting', 0)
                    },
                  })
                }
                .height(undefined)
                .width('100%')
              }
              .divider({
                strokeWidth: 1,
                color: $r('sys.color.comp_divider'),
                startMargin: $r('sys.float.padding_level24'),
                endMargin: $r('sys.float.padding_level6'),
              })
              .padding($r('sys.float.padding_level2'))
              .backgroundColor($r('sys.color.comp_background_primary'))
              .borderRadius($r('sys.float.corner_radius_level8'))
            }
            .height(undefined)
            .width('100%')
            .edgeEffect(EdgeEffect.Spring)

            // 账户与同步区
            Text('账户与同步')
              .fontSize(14)
              .fontColor($r('sys.color.font_secondary'))
              .width('100%')
              .margin({ top: 20, bottom: 8 })

            List({ space: 0 }) {
              ListItemGroup() {
                ListItem({ style: ListItemStyle.CARD }) {
                  CardItem({
                    isShow: true,
                    textContent: '登录 / 账号',
                    symbolSrc: $r('sys.symbol.person_crop_circle'),
                    onclick: () => {},
                  })
                }
                .height(undefined)
                .width('100%')

                ListItem({ style: ListItemStyle.CARD }) {
                  Row() {
                    Text('云同步')
                      .fontSize(16)
                      .fontWeight(500)
                      .layoutWeight(1)
                      .padding({ left: 16 })
                    Toggle({ type: ToggleType.Switch, isOn: false })
                      .enabled(false)
                      .margin({ right: 16 })
                  }
                  .height(56)
                  .width('100%')
                }
                .height(undefined)

                ListItem({ style: ListItemStyle.CARD }) {
                  CardItem({
                    isShow: true,
                    textContent: '立即备份',
                    symbolSrc: $r('sys.symbol.arrow_up_doc'),
                    onclick: () => {},
                  })
                }
                .height(undefined)
                .width('100%')

                ListItem({ style: ListItemStyle.CARD }) {
                  CardItem({
                    isShow: true,
                    textContent: '恢复数据',
                    symbolSrc: $r('sys.symbol.arrow_down_doc'),
                    onclick: () => {},
                  })
                }
                .height(undefined)
                .width('100%')
              }
              .divider({
                strokeWidth: 1,
                color: $r('sys.color.comp_divider'),
                startMargin: $r('sys.float.padding_level24'),
                endMargin: $r('sys.float.padding_level6'),
              })
              .padding($r('sys.float.padding_level2'))
              .backgroundColor($r('sys.color.comp_background_primary'))
              .borderRadius($r('sys.float.corner_radius_level8'))
            }
            .height(undefined)
            .width('100%')
            .edgeEffect(EdgeEffect.Spring)

            // 关于区
            Text('关于')
              .fontSize(14)
              .fontColor($r('sys.color.font_secondary'))
              .width('100%')
              .margin({ top: 20, bottom: 8 })

            List({ space: 0 }) {
              ListItemGroup() {
                ListItem({ style: ListItemStyle.CARD }) {
                  CardItem({
                    isShow: true,
                    textContent: '关于轻Markdown',
                    symbolSrc: $r('sys.symbol.info_circle'),
                    onclick: () => {
                      this.pathStack.pushPath({ name: 'AboutPage' });
                    },
                  })
                }
                .height(undefined)
                .width('100%')

                ListItem({ style: ListItemStyle.CARD }) {
                  CardItem({
                    isShow: true,
                    textContent: '使用指南',
                    symbolSrc: $r('sys.symbol.book'),
                    onclick: () => {},
                  })
                }
                .height(undefined)
                .width('100%')

                ListItem({ style: ListItemStyle.CARD }) {
                  CardItem({
                    isShow: true,
                    textContent: '意见反馈',
                    symbolSrc: $r('sys.symbol.text_bubble'),
                    onclick: () => {},
                  })
                }
                .height(undefined)
                .width('100%')

                ListItem({ style: ListItemStyle.CARD }) {
                  CardItem({
                    isShow: true,
                    textContent: '隐私政策',
                    symbolSrc: $r('sys.symbol.lock_shield'),
                    onclick: () => {},
                  })
                }
                .height(undefined)
                .width('100%')
              }
              .divider({
                strokeWidth: 1,
                color: $r('sys.color.comp_divider'),
                startMargin: $r('sys.float.padding_level24'),
                endMargin: $r('sys.float.padding_level6'),
              })
              .padding($r('sys.float.padding_level2'))
              .backgroundColor($r('sys.color.comp_background_primary'))
              .borderRadius($r('sys.float.corner_radius_level8'))
            }
            .height(undefined)
            .width('100%')
            .edgeEffect(EdgeEffect.Spring)

            Blank().height(56 + this.safeBottom + 8)
          }
          .width('100%')
          .constraintSize({ minHeight: '100%' })
          .padding({ left: 16, right: 16 })
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .height('100%')
      }
    }
    .titleMode(this.titleMode)
    .hideBackButton(true)
    .backgroundColor($r('sys.color.background_secondary'))
    .hideTitleBar(false)
    .titleBar({
      style: {
        scrollEffectOpts: {
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        },
      },
      avoidLayoutSafeArea: true,
      content: {
        title: {
          mainTitle: '我的',
        },
      }
    })
  }
}
```

- [ ] **Step 3: 创建 AboutPage.ets**

创建 `feature/mine/src/main/ets/page/AboutPage.ets`：

```typescript
import { HdsNavDestination, ScrollEffectType, hdsMaterial } from '@kit.UIDesignKit';

@Component
export struct AboutPage {
  @StorageProp('safeTop') safeTop: number = 0;
  @StorageProp('safeBottom') safeBottom: number = 0;

  build() {
    HdsNavDestination() {
      Scroll() {
        Column() {
          Blank().width('100%').height(58 + this.safeTop)

          // Logo
          Image($r('app.media.celi'))
            .width(72)
            .height(72)
            .margin({ bottom: 16 })

          Text('轻Markdown')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))

          Text('v1.0.2')
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: 8 })

          Text('简洁高效的 Markdown 文件管理器')
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: 12 })

          Divider()
            .margin({ top: 24, bottom: 16 })

          Row() {
            Text('版本号')
              .fontSize(16)
              .fontColor($r('sys.color.font_primary'))
              .layoutWeight(1)
            Text('1.0.2')
              .fontSize(14)
              .fontColor($r('sys.color.font_secondary'))
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 16 })

          Row() {
            Text('检查更新')
              .fontSize(16)
              .fontColor($r('sys.color.font_primary'))
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_forward'))
              .fontSize(14)
              .fontColor([$r('sys.color.font_tertiary')])
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 16 })
          .onClick(() => {})

          Blank().height(this.safeBottom)
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 16, right: 16 })
      }
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')
    }
    .titleBar({
      content: {
        title: { mainTitle: '关于' }
      },
      style: {
        scrollEffectOpts: { scrollEffectType: ScrollEffectType.GRADIENT_BLUR },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        }
      },
      avoidLayoutSafeArea: true
    })
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

@Builder
export function AboutPageBuilder() {
  AboutPage();
}
```

- [ ] **Step 4: 更新 mine/Index.ets 导出**

将 `feature/mine/Index.ets` 改为：

```typescript
export { Mine } from './src/main/ets/page/Mine';
export { DarkModeSetting } from './src/main/ets/settingpage/DarkModeSetting';
export { AboutPage } from './src/main/ets/page/AboutPage';
```

- [ ] **Step 5: 在 Index.ets 注册 AboutPage 路由**

在 `entry/src/main/ets/pages/Index.ets` 的 `PageMap` builder 中添加：

```typescript
} else if (name === 'AboutPage') {
  AboutPage()
}
```

并在顶部 import 中添加 `AboutPage`。

- [ ] **Step 6: 验证**

运行 app → "我的" tab → 显示存储统计卡片 → 设置项可切换 → 点击"关于轻Markdown" → 进入关于页 → 显示版本号。

---

## Task 8: 首页读取默认设置

**Files:**
- Modify: `feature/markdown/src/main/ets/page/MdView.ets:140-142`（aboutToAppear）

- [ ] **Step 1: 在 MdView.aboutToAppear 中读取用户偏好**

将 `aboutToAppear` 方法改为：

```typescript
aboutToAppear(): void {
  this.registerHarmonyShareListeners();
  // 读取用户默认设置
  const savedSort = AppStorage.get<number>('defaultSortMode');
  if (savedSort !== undefined) {
    this.sortMode = savedSort;
  }
  const savedGrid = AppStorage.get<boolean>('defaultViewIsGrid');
  if (savedGrid !== undefined) {
    this.isGridView = savedGrid;
  }
  setTimeout(() => { this.loadLocalFiles(); }, 0);
}
```

- [ ] **Step 2: 验证**

运行 app → "我的" tab → 改默认排序为"时间" → 回首页 → 文件按时间排序。

---

## 自检清单

- [ ] 编辑器：打开 → 编辑 → 保存 → 文件内容更新
- [ ] 编辑器 dirty：修改后离开 → 弹确认
- [ ] "我的" tab：存储统计、设置项、关于页
- [ ] 删除确认：列表页滑动删除弹确认框
- [ ] 重命名：改名后 DB + 文件系统 + UI 同步
- [ ] 网格卡片：显示文件大小和相对时间
