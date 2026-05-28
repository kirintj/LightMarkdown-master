import { hdsMaterial, HdsNavDestination, ScrollEffectType } from '@kit.UIDesignKit';
import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';
import { MarkdownFile, FileGroup, FileDataSource } from '../class/MarkdownFile';
import { MdDbService } from '../service/MdDbService';
import { common } from '@kit.AbilityKit';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { RenameDialog } from '../component/RenameDialog';
import { GroupSheetContent, GroupItem, showDeleteConfirm, BreakpointType, GlobalInfoModel, StorageKey, PageContext, PageEnum, AnimUtil } from 'common';

const TITLE_BAR_HEIGHT_FREE: number = 58 + 16 + 4;
const DEFAULT_SHARE_DESCRIPTION: string = 'Markdown文档';

@Component
export struct MarkdownViewerPage {
  // 路由状态
  private pageContext: PageContext = AppStorage.get<PageContext>(StorageKey.HOME_PAGE_CONTEXT) ?? new PageContext();
  private dataSource: FileDataSource = AppStorage.get<FileDataSource>('dataSource') ?? new FileDataSource();
  @StorageLink('dataVersion') dataVersion: number = 0;
  @State fileData: MarkdownFile = new MarkdownFile('', '', '', 0);

  // 滚动 & 控制器
  private scroller: Scroller = new Scroller();
  controller: MarkdownController = new MarkdownController();
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  // UI 状态
  @State blankHeight: number = TITLE_BAR_HEIGHT_FREE;
  @State isLoading: boolean = true;
  @State showMarkdown: boolean = false;

  // 分组状态
  @State showGroupSheet: boolean = false;
  @State groups: FileGroup[] = [];
  @State newGroupName: string = '';

  // 主题
  @StorageProp('currentColorMode') @Watch('onColorModeChange') currentColorMode: number = 0;

  // 分享
  private shareController: systemShare.ShareController | null = null;
  // 重命名弹窗控制器
  private renameController: CustomDialogController | null = null;

  // 防护标记
  private isShareListenerRegistered: boolean = false;
  private isDestroyed: boolean = false;
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();

  aboutToAppear(): void {
    this.initMarkdownController();
    this.registerHarmonyShareListeners();
    setTimeout(() => {
      if (this.isDestroyed) return;
      this.recordView();
      this.showMarkdown = true;
    }, 0);
    setTimeout(() => {
      this.isLoading = false
    }, 2000);
  }

  aboutToDisappear(): void {
    this.isDestroyed = true;
    this.unregisterHarmonyShareListeners();
    this.dismissShareController();
  }

  private initMarkdownController(): void {
    this.controller
      .setTitleColor($r("sys.color.title_primary_color"))
      .setTextColor($r("sys.color.ohos_fa_text_primary"))
      .setQuoteBackgroundColor($r("sys.color.background_secondary"))
      .setQuoteBorderColor($r('sys.color.brand'));
    this.controller.setCodeBlockTheme(this.currentColorMode === 0 ? 'dark' : 'light');
  }

  onColorModeChange(): void {
    if (this.isDestroyed) return;
    this.controller.setCodeBlockTheme(this.currentColorMode === 0 ? 'dark' : 'light');
  }

  private async recordView(): Promise<void> {
    if (this.isDestroyed) return;
    if (!this.fileData.sandboxPath) return;
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.init();
      if (this.isDestroyed) return;
      await dbService.updateLastViewedAt(this.fileData.sandboxPath);
      this.dataVersion++;
    } catch (e) {
      console.error('[MarkdownViewerPage] 记录浏览时间失败: ' + JSON.stringify(e));
    }
  }

  private buildShareData(): systemShare.SharedData {
    const fileUriStr = fileUri.getUriFromPath(this.fileData.sandboxPath);
    return new systemShare.SharedData({
      utd: utd.UniformDataType.FILE,
      uri: fileUriStr,
      title: this.fileData.name,
      description: DEFAULT_SHARE_DESCRIPTION,
    });
  }

  private doSystemShare(): void {
    if (!this.fileData.sandboxPath) return;
    try {
      const shareData = this.buildShareData();
      this.shareController = new systemShare.ShareController(shareData);
      this.shareController.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
        console.info('[MarkdownViewerPage] 分享完成, 渠道: ' + result.targetAbilityInfo.name);
      });
      this.shareController.show(this.context, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE,
      }).catch(() => {
        // TODO: Implement error handling.
      });
    } catch (e) {
      console.error('[MarkdownViewerPage] 拉起分享面板失败: ' + JSON.stringify(e));
      this.getUIContext().getPromptAction().showToast({ message: '分享失败' });
    }
  }

  private handleHarmonyShare(sharableTarget: harmonyShare.SharableTarget, shareType: string): void {
    try {
      const shareData = this.buildShareData();
      sharableTarget.share(shareData);
      console.info('[MarkdownViewerPage] ' + shareType + '已触发');
    } catch (e) {
      console.error('[MarkdownViewerPage] ' + shareType + '失败: ' + JSON.stringify(e));
      sharableTarget.reject(harmonyShare.SharableErrorCode.DOWNLOAD_ERROR);
    }
  }

  private knockShareCallback = (sharableTarget: harmonyShare.SharableTarget): void => {
    this.handleHarmonyShare(sharableTarget, '碰一碰分享');
  }

  private gesturesShareCallback = (sharableTarget: harmonyShare.SharableTarget): void => {
    this.handleHarmonyShare(sharableTarget, '隔空传送');
  }

  private registerHarmonyShareListeners(): void {
    if (this.isShareListenerRegistered) return;
    try {
      harmonyShare.on('knockShare', this.knockShareCallback);
    } catch (e) {
      console.error('[MarkdownViewerPage] 注册碰一碰监听失败: ' + JSON.stringify(e));
    }
    try {
      harmonyShare.on('gesturesShare', this.gesturesShareCallback);
    } catch (e) {
      console.error('[MarkdownViewerPage] 注册隔空传送监听失败: ' + JSON.stringify(e));
    }
    this.isShareListenerRegistered = true;
  }

  private unregisterHarmonyShareListeners(): void {
    if (!this.isShareListenerRegistered) return;
    try {
      harmonyShare.off('knockShare', this.knockShareCallback);
    } catch (e) {
      console.error('[MarkdownViewerPage] 注销碰一碰监听失败: ' + JSON.stringify(e));
    }
    try {
      harmonyShare.off('gesturesShare', this.gesturesShareCallback);
    } catch (e) {
      console.error('[MarkdownViewerPage] 注销隔空传送监听失败: ' + JSON.stringify(e));
    }
    this.isShareListenerRegistered = false;
  }

  private dismissShareController(): void {
    if (this.shareController) {
      try {
        this.shareController.off('shareCompleted');
      } catch (e) {
        console.error('[MarkdownViewerPage] 注销分享回调失败: ' + JSON.stringify(e));
      }
      this.shareController = null;
    }
  }

  private async openGroupSheet(): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.init();
      this.groups = await dbService.queryAllGroups();
      this.showGroupSheet = true;
    } catch (e) {
      console.error('[MarkdownViewerPage] 加载分组列表失败: ' + JSON.stringify(e));
    }
  }

  private async assignToGroup(groupId: number, groupName: string): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.setFileGroup(this.fileData.sandboxPath, groupId);
      this.fileData = new MarkdownFile(this.fileData.name, this.fileData.uri, this.fileData.sandboxPath, 0, this.fileData.isStar, this.fileData.size, groupId, groupName, this.fileData.lastViewedAt, this.fileData.createdAt);
      this.dataSource.updateItemGroup(this.fileData.sandboxPath, groupId, groupName);
      this.dataVersion++;
      this.showGroupSheet = false;
      this.getUIContext().getPromptAction().showToast({ message: `已加入分组「${groupName}」` });
    } catch (e) {
      console.error('[MarkdownViewerPage] 分组失败: ' + JSON.stringify(e));
    }
  }

  private async removeFromGroup(): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.removeFileGroup(this.fileData.sandboxPath);
      this.fileData = new MarkdownFile(this.fileData.name, this.fileData.uri, this.fileData.sandboxPath, 0, this.fileData.isStar, this.fileData.size, -1, '', this.fileData.lastViewedAt, this.fileData.createdAt);
      this.dataSource.updateItemGroup(this.fileData.sandboxPath, -1, '');
      this.dataVersion++;
      this.showGroupSheet = false;
      this.getUIContext().getPromptAction().showToast({ message: '已移出分组' });
    } catch (e) {
      console.error('[MarkdownViewerPage] 移出分组失败: ' + JSON.stringify(e));
    }
  }

  private async createAndAssignGroup(): Promise<void> {
    const groupName = this.newGroupName.trim();
    if (!groupName) return;
    try {
      const dbService = MdDbService.getInstance(this.context);
      const groupId = await dbService.createGroup(groupName);
      await dbService.setFileGroup(this.fileData.sandboxPath, groupId);
      this.fileData = new MarkdownFile(this.fileData.name, this.fileData.uri, this.fileData.sandboxPath, 0, this.fileData.isStar, this.fileData.size, groupId, groupName, this.fileData.lastViewedAt, this.fileData.createdAt);
      this.dataSource.updateItemGroup(this.fileData.sandboxPath, groupId, groupName);
      this.dataVersion++;
      this.newGroupName = '';
      this.showGroupSheet = false;
      this.getUIContext().getPromptAction().showToast({ message: `已创建分组「${groupName}」并加入` });
    } catch (e) {
      console.error('[MarkdownViewerPage] 创建分组失败: ' + JSON.stringify(e));
    }
  }

  private async toggleStar(): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.init();
      const isStar = await dbService.toggleStar(this.fileData.sandboxPath);
      this.fileData = new MarkdownFile(this.fileData.name, this.fileData.uri, this.fileData.sandboxPath, 0, isStar, this.fileData.size, this.fileData.groupId, this.fileData.groupName, this.fileData.lastViewedAt, this.fileData.createdAt);
      this.dataSource.updateItemStar(this.fileData.sandboxPath, isStar);
      this.dataVersion++;
      this.getUIContext().getPromptAction().showToast({ message: isStar ? '已收藏' : '已取消收藏' });
    } catch (e) {
      console.error('[MarkdownViewerPage] 切换收藏失败: ' + JSON.stringify(e));
    }
  }

  private async deleteFile(): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.init();
      fs.unlinkSync(this.fileData.sandboxPath);
      await dbService.deleteFile(this.fileData.sandboxPath);
      const index = this.dataSource.getIndex(this.fileData);
      if (index >= 0) {
        this.dataSource.removeItem(index);
      }
      this.dataVersion++;
      this.pageContext.popPage();
      this.getUIContext().getPromptAction().showToast({ message: '已删除' });
    } catch (e) {
      console.error('[MarkdownViewerPage] 删除文件失败: ' + JSON.stringify(e));
    }
  }

  private showDelete(): void {
    showDeleteConfirm(this.getUIContext(), this.fileData.name, () => { this.deleteFile(); });
  }

  private showRenameInputDialog(): void {
    this.renameController = new CustomDialogController({
      builder: RenameDialog({
        initialName: this.fileData.name,
        onConfirm: (name: string) => { this.doRenameWith(name); },
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
    });
    this.renameController.open();
  }

  private async doRenameWith(newName: string): Promise<void> {
    const trimmed = newName.trim();
    if (!trimmed || trimmed === this.fileData.name) return;
    try {
      const dbService = MdDbService.getInstance(this.context);
      const newPath = await dbService.renameFile(this.fileData.sandboxPath, trimmed);
      this.dataSource.updateItemPath(this.fileData.sandboxPath, trimmed, newPath);
      this.fileData = new MarkdownFile(
        trimmed, this.fileData.uri, newPath, 0,
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

  @Builder
  viewingContent() {
    Scroll(this.scroller) {
      Column() {
        Blank().width('100%').height(this.blankHeight);
        if(this.isLoading){
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color($r('sys.color.brand'))
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 32, bottom: 32 })
          .opacity(this.isLoading ? 1 : 0)
          .animation({ duration: 300, curve: Curve.EaseOut })
        }else{
          if (this.showMarkdown) {
            Markdown({
              mode: "sandbox",
              sandboxPath: this.fileData.sandboxPath,
              callback: {
                complete: () => {
                  this.isLoading = false;
                },
                fail: (code: number, msg: string) => {
                  this.isLoading = false;
                  console.error('[MarkdownViewerPage] Markdown加载失败: ' + code + ', ' + msg);
                  try {
                    this.getUIContext().getPromptAction().showToast({ message: '加载失败' });
                  } catch (error) {
                    // TODO: Implement error handling.
                  }
                }
              },
              controller: this.controller
            })
              .width('100%')
              .transition(AnimUtil.fadeInTransition())
          }
        }
      }.padding(new BreakpointType<Padding>({
        sm: { left: 16, right: 16, top: 16, bottom: 16 },
        md: { left: 24, right: 24, top: 20, bottom: 20 },
        lg: { left: 32, right: 32, top: 24, bottom: 24 },
      }).getValue(this.globalInfoModel.widthBreakpoint)).width('100%');
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%');
  }

  @Builder
  groupSheetBuilder() {
    Column() {
      Row() {
        Text('分组')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        Blank()
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(20)
          .fontColor([$r('sys.color.icon_secondary')])
          .onClick(() => { this.showGroupSheet = false; })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      GroupSheetContent({
        currentGroupId: this.fileData.groupId,
        groups: this.groups.map((g: FileGroup): GroupItem => {
          const item: GroupItem = { id: g.id, name: g.name };
          return item;
        }),
        onAssign: (id: number, name: string) => { this.assignToGroup(id, name); },
        onRemove: () => { this.removeFromGroup(); },
        onCreate: (name: string) => { this.newGroupName = name; this.createAndAssignGroup(); }
      })
    }
    .width('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(16)
  }

  build() {
    HdsNavDestination() {
      this.viewingContent();
    }
    .titleBar({
      content: {
        title: {
          mainTitle: this.fileData.name
        },
        menu: {
          value: [
            {
              content: {
                label: '重命名',
                icon: $r('sys.symbol.rename'),
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
      height: 400,
      preferType: SheetType.CENTER,
      enableOutsideInteractive: false,
      dragBar: false,
      showClose: false,
      backgroundColor: $r('sys.color.background_secondary'),
    });
  }
}

@Builder
export function MarkdownViewerPageBuilder() {
  MarkdownViewerPage();
}
