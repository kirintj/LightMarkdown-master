import { ScrollEffectType, HdsNavDestination, HdsNavDestinationTitleMode, PrefixCustomBuilder} from '@hms.hds.hdsBaseComponent';
import { LengthMetrics, promptAction, SymbolGlyphModifier } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { MarkdownFile, FileGroup, FileDataSource } from '../class/MarkdownFile';
import { common } from '@kit.AbilityKit';
import { hdsEffect, HdsListItem, hdsMaterial } from '@kit.UIDesignKit';
import { EmptyView } from '../component/EmptyComponent';
import { MdDbService } from '../service/MdDbService';
import { ItemRestriction, SegmentButton, SegmentButtonOptions, SegmentButtonTextItem } from '@kit.ArkUI';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { FloatBall } from '../component/FloatBall'
import { GroupSheetContent, GroupItem, showDeleteConfirm, formatRelativeTime, BreakpointType, GlobalInfoModel, StorageKey, PageContext, PageEnum } from 'common';
import { FileGridCard } from '../component/FileGridCard';
const TITLE_BAR_HEIGHT_FREE: number = 56 + 56 + 8;

@Component
export struct MdView {
  private pageContext: PageContext = AppStorage.get<PageContext>(StorageKey.HOME_PAGE_CONTEXT) ?? new PageContext();
  scroller: Scroller = new Scroller();
  @State blankHeight: number = TITLE_BAR_HEIGHT_FREE;
  @State isHideBackButton: boolean = false;
  @State titleMode: HdsNavDestinationTitleMode = HdsNavDestinationTitleMode.MINI;
  @StorageProp('safeTop') safeTop: number = 0;
  @StorageProp('safeBottom') safeBottom: number = 0;
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
  @Consume('dataSource') dataSource: FileDataSource;
  @StorageLink('dataVersion') @Watch('onDataVersionChange') dataVersion: number = 0;
  @State searchKeyword: string = '';
  @State filteredFiles: MarkdownFile[] = [];
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private shareController: systemShare.ShareController | null = null;
  private shareTargetFile: MarkdownFile | null = null;
  @State isGridView: boolean = false;
  @State tabOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [{ text: '全部' }, { text: '收藏' }] as ItemRestriction<SegmentButtonTextItem>,
    selectedFontColor: $r('sys.color.brand'),
    selectedBackgroundColor: $r('sys.color.comp_background_primary_contrary'),
    textPadding: {
      top: 6,
      right: 5,
      bottom: 6,
      left: 5
    }
  });
  @State tabSelectedIndexes: number[] = [0];
  @State starredFiles: MarkdownFile[] = [];
  @State allFiles: MarkdownFile[] = [];
  @State controller: hdsEffect.ShaderEffectController = new hdsEffect.ShaderEffectController();
  private isFirstShow: boolean = true;

  @Builder
  listCard(item: MarkdownFile): void {
    Row() {
      SymbolGlyph($r('sys.symbol.doc_plaintext_fill'))
        .fontSize($r('sys.float.Title_M'))
        .fontColor([$r('sys.color.brand')]);
      Column() {
        Text(item.name)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        if (item.groupName) {
          Text(item.groupName)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .fontSize($r('sys.float.Caption_S'))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.white'))
            .backgroundColor($r('sys.color.confirm'))
            .borderRadius(8)
            .margin({ top: 2 });
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: $r('sys.float.padding_level6') })
      .layoutWeight(1);
      Blank();
      if (item.isStar) {
        SymbolGlyph($r('sys.symbol.star_fill'))
          .fontSize(24)
          .fontColor(['#FFC83D']);
      }
    }
    .width('100%')
    .padding($r('sys.float.padding_level6'));
  }

  @State sortMode: number = 0;
  @State menuVisible: boolean = false;
  @State showGroupSheet: boolean = false;
  @State groups: FileGroup[] = [];
  @State groupTargetFile: MarkdownFile | null = null;
  @State newGroupName: string = '';
  @State s1: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.plus_circle'));
  @State s2: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.checkmark_circle'));
  @State s3: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.person_crop_circle_fill_1'));
  @State expandSymbolModifier: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.chevron_down')).fontSize(24)

  private isStarTab(): boolean {
    return this.tabSelectedIndexes.length > 0 && this.tabSelectedIndexes[0] === 1;
  }

  private sortFiles(files: MarkdownFile[]): MarkdownFile[] {
    const sorted = Array.from(files);
    if (this.sortMode === 0) {
      sorted.sort((a: MarkdownFile, b: MarkdownFile) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
    } else if (this.sortMode === 1) {
      sorted.sort((a: MarkdownFile, b: MarkdownFile) => b.createdAt - a.createdAt);
    } else if (this.sortMode === 2) {
      sorted.sort((a: MarkdownFile, b: MarkdownFile) => {
        const aHasGroup: boolean = a.groupId !== -1;
        const bHasGroup: boolean = b.groupId !== -1;
        if (aHasGroup !== bHasGroup) {
          return aHasGroup ? -1 : 1;
        }
        if (aHasGroup && bHasGroup) {
          const groupCmp: number = a.groupName.localeCompare(b.groupName);
          if (groupCmp !== 0) return groupCmp;
        }
        return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
      });
    }
    return sorted;
  }

  private refreshStarredFiles(): void {
    this.starredFiles = this.sortFiles(this.allFiles.filter((f: MarkdownFile) => f.isStar));
  }

  private refreshData(): void {
    this.allFiles = this.sortFiles(Array.from(this.dataSource.getAll()));
    this.refreshStarredFiles();
    this.applySearchFilter();
  }

  private onDataVersionChange(): void {
    this.refreshData();
  }

  @Builder
  stackBuilder() {
    Row() {
      Flex({ justifyContent: FlexAlign.Center }) {
        SegmentButton({
          options: this.tabOptions,
          selectedIndexes: $tabSelectedIndexes,
        })
          .width(150)
      }
      .margin({ left: 16, right: 16 })
    }
    .width('100%')
  }


  @Builder
  BottomBuilder(): void {
    Column() {
      Search({ placeholder: '搜索markdown文件', value: this.searchKeyword })
        .searchButton('搜索', {
          fontColor: $r('sys.color.brand')
        })
        .onChange((value: string) => {
          this.searchKeyword = value;
          this.applySearchFilter();
        })
        .onSubmit((value: string) => {
          this.searchKeyword = value;
          this.applySearchFilter();
        });
    }
    .padding(new BreakpointType<Padding>({
      sm: { left: 16, right: 16 },
      md: { left: 24, right: 24 },
      lg: { left: 32, right: 32 },
    }).getValue(this.globalInfoModel.widthBreakpoint))
  }

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

  aboutToDisappear(): void {
    this.unregisterHarmonyShareListeners();
    this.dismissShareController();
  }

  private buildShareData(item: MarkdownFile): systemShare.SharedData {
    const fileUriStr = fileUri.getUriFromPath(item.sandboxPath);
    return new systemShare.SharedData({
      utd: utd.UniformDataType.FILE,
      uri: fileUriStr,
      title: item.name,
      description: 'Markdown文档',
    });
  }

  private doSystemShare(item: MarkdownFile): void {
    try {
      const shareData = this.buildShareData(item);
      this.shareController = new systemShare.ShareController(shareData);
      this.shareController.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
        console.info('[MdView] 分享完成, 渠道: ' + result.targetAbilityInfo.name);
      });
      this.shareController.show(this.context, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE,
      });
    } catch (e) {
      const err = e as BusinessError;
      console.error('[MdView] 拉起分享面板失败: ' + err.code + ' ' + err.message);
    }
  }

  private knockShareCallback = (sharableTarget: harmonyShare.SharableTarget): void => {
    if (!this.shareTargetFile) {
      sharableTarget.clarifyNonShare({ message: '请先选择要分享的文件' });
      return;
    }
    try {
      const shareData = this.buildShareData(this.shareTargetFile);
      sharableTarget.share(shareData);
      console.info('[MdView] 碰一碰分享已触发');
    } catch (e) {
      const err = e as BusinessError;
      console.error('[MdView] 碰一碰分享失败: ' + err.code + ' ' + err.message);
      sharableTarget.reject(harmonyShare.SharableErrorCode.DOWNLOAD_ERROR);
    }
  }

  private gesturesShareCallback = (sharableTarget: harmonyShare.SharableTarget): void => {
    if (!this.shareTargetFile) {
      sharableTarget.clarifyNonShare({ message: '请先选择要分享的文件' });
      return;
    }
    try {
      const shareData = this.buildShareData(this.shareTargetFile);
      sharableTarget.share(shareData);
      console.info('[MdView] 隔空传送已触发');
    } catch (e) {
      const err = e as BusinessError;
      console.error('[MdView] 隔空传送失败: ' + err.code + ' ' + err.message);
      sharableTarget.reject(harmonyShare.SharableErrorCode.DOWNLOAD_ERROR);
    }
  }

  private registerHarmonyShareListeners(): void {
    try {
      harmonyShare.on('knockShare', this.knockShareCallback);
    } catch (e) {
      console.error('[MdView] 注册碰一碰监听失败: ' + JSON.stringify(e));
    }
    try {
      harmonyShare.on('gesturesShare', this.gesturesShareCallback);
    } catch (e) {
      console.error('[MdView] 注册隔空传送监听失败: ' + JSON.stringify(e));
    }
  }

  private unregisterHarmonyShareListeners(): void {
    try {
      harmonyShare.off('knockShare', this.knockShareCallback);
    } catch (e) {
      console.error('[MdView] 注销碰一碰监听失败: ' + JSON.stringify(e));
    }
    try {
      harmonyShare.off('gesturesShare', this.gesturesShareCallback);
    } catch (e) {
      console.error('[MdView] 注销隔空传送监听失败: ' + JSON.stringify(e));
    }
  }

  private dismissShareController(): void {
    if (this.shareController) {
      this.shareController.off('shareCompleted');
      this.shareController = null;
    }
  }

  async loadLocalFiles(): Promise<void> {
    const dbService = MdDbService.getInstance(this.context);
    await dbService.init();

    const targetDir = this.context.filesDir + "/md_docs";
    const fsFiles: MarkdownFile[] = [];

    try {
      if (fs.accessSync(targetDir)) {
        const fileNames = fs.listFileSync(targetDir);
        for (const fileName of fileNames) {
          const targetPath = `${targetDir}/${fileName}`;
          const stats = fs.statSync(targetPath);
          fsFiles.push(new MarkdownFile(fileName, '', targetPath, stats.size, false, undefined, -1, '', 0, stats.mtime * 1000));
        }
      }
    } catch (err) {
      console.error('[MdView] 读取文件系统失败:', JSON.stringify(err));
    }

    await dbService.syncFromFileSystem(fsFiles);

    this.dataSource.clear();
    const dbFiles = await dbService.queryAll();
    for (const file of dbFiles) {
      this.dataSource.pushItem(file);
    }
    this.dataVersion++;
    this.refreshData();
  }

  private applySearchFilter(): void {
    if (!this.searchKeyword) {
      this.filteredFiles = [];
      return;
    }
    const keyword: string = this.searchKeyword.toLowerCase();
    const source: MarkdownFile[] = this.isStarTab()
      ? this.starredFiles
      : this.allFiles;
    this.filteredFiles = this.sortFiles(source.filter((f: MarkdownFile) => f.name.toLowerCase().includes(keyword)));
  }

  async readPickerFile(): Promise<void> {
    try {
      let pickerOpt = new picker.DocumentSelectOptions();
      pickerOpt.maxSelectNumber = 50;
      pickerOpt.fileSuffixFilters = ['.md', 'application/markdown', 'text/markdown', 'text/x-markdown'];

      const documentViewPicker = new picker.DocumentViewPicker();
      const uris = await documentViewPicker.select(pickerOpt);

      if (!uris || uris.length === 0) return;

      const targetDir = this.context.filesDir + "/md_docs";
      if (!fs.accessSync(targetDir)) fs.mkdirSync(targetDir);

      const dbService = MdDbService.getInstance(this.context);
      const newFiles: MarkdownFile[] = [];

      for (let sourceUri of uris) {
        try {
          let srcFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY);
          if (!srcFile || !srcFile.name) {
            fs.closeSync(srcFile);
            continue;
          }

          const targetPath = `${targetDir}/${srcFile.name}`;

          let destFile = fs.openSync(targetPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
          fs.copyFileSync(srcFile.fd, destFile.fd);

          const stats = fs.statSync(targetPath);
          const mdFile = new MarkdownFile(srcFile.name, sourceUri, targetPath, stats.size, false, undefined, -1, '', 0, Date.now());
          this.dataSource.pushItem(mdFile);
          newFiles.push(mdFile);

          fs.closeSync(srcFile);
          fs.closeSync(destFile);
        } catch (err) {
          console.error("单个文件处理失败:", JSON.stringify(err));
        }
      }

      await dbService.insertFiles(newFiles);
      this.dataVersion++;
      this.refreshData();

    } catch (err) {
      console.error("批量导入失败: " + JSON.stringify(err));
    }
  }

  private async toggleStar(item: MarkdownFile): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      const isStar: boolean = await dbService.toggleStar(item.sandboxPath);
      this.dataSource.updateItemStar(item.sandboxPath, isStar);
      this.dataVersion++;
      this.refreshData();
      const msg: string = isStar ? '已收藏' : '已取消收藏';
      promptAction.openToast({ message: msg, duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[MdView] 切换收藏失败:', JSON.stringify(e));
    }
  }

  private async openGroupSheet(item: MarkdownFile): Promise<void> {
    this.groupTargetFile = item;
    const dbService = MdDbService.getInstance(this.context);
    this.groups = await dbService.queryAllGroups();
    this.showGroupSheet = true;
  }

  private async assignToGroup(groupId: number, groupName: string): Promise<void> {
    if (!this.groupTargetFile) return;
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.setFileGroup(this.groupTargetFile.sandboxPath, groupId);
      this.dataSource.updateItemGroup(this.groupTargetFile.sandboxPath, groupId, groupName);
      this.dataVersion++;
      this.showGroupSheet = false;
      this.groupTargetFile = null;
      promptAction.openToast({ message: `已加入分组「${groupName}」`, duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[MdView] 分组失败:', JSON.stringify(e));
    }
  }

  private async removeFromGroup(): Promise<void> {
    if (!this.groupTargetFile) return;
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.removeFileGroup(this.groupTargetFile.sandboxPath);
      this.dataSource.updateItemGroup(this.groupTargetFile.sandboxPath, -1, '');
      this.dataVersion++;
      this.showGroupSheet = false;
      this.groupTargetFile = null;
      promptAction.openToast({ message: '已移出分组', duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[MdView] 移出分组失败:', JSON.stringify(e));
    }
  }

  private async createAndAssignGroup(): Promise<void> {
    if (!this.groupTargetFile || !this.newGroupName.trim()) return;
    const groupName: string = this.newGroupName.trim();
    try {
      const dbService = MdDbService.getInstance(this.context);
      const groupId: number = await dbService.createGroup(groupName);
      await dbService.setFileGroup(this.groupTargetFile.sandboxPath, groupId);
      this.dataSource.updateItemGroup(this.groupTargetFile.sandboxPath, groupId, groupName);
      this.dataVersion++;
      this.newGroupName = '';
      this.showGroupSheet = false;
      this.groupTargetFile = null;
      promptAction.openToast({ message: `已创建分组「${groupName}」并加入`, duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[MdView] 创建分组失败:', JSON.stringify(e));
    }
  }

  private confirmDeleteFile(item: MarkdownFile): void {
    showDeleteConfirm(this.getUIContext(), item.name, () => { this.executeDeleteFile(item); });
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

  @Builder
  groupSheetBuilder() {
    HdsNavDestination() {
      GroupSheetContent({
        currentGroupId: this.groupTargetFile ? this.groupTargetFile.groupId : -1,
        groups: this.groups.map((g: FileGroup): GroupItem => {
          const item: GroupItem = { id: g.id, name: g.name };
          return item;
        }),
        onAssign: (id: number, name: string) => { this.assignToGroup(id, name); },
        onRemove: () => { this.removeFromGroup(); },
        onCreate: (name: string) => { this.newGroupName = name; this.createAndAssignGroup(); }
      })
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .hideBackButton(true)
    .titleMode(HdsNavDestinationTitleMode.MODAL)
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
      enableComponentSafeArea: true,
      content: {
        title: {
          mainTitle: '分组',
        },
        menu: {
          value: [{
            content: {
              icon: $r('sys.symbol.xmark'),
              action: () => {
                this.showGroupSheet = false;
              },
            }
          }]
        },
      },
    })
  }

  @Builder
  SubMenu() {
    Menu() {
      MenuItem({
        content: "按名称排序",
        symbolEndIcon: this.sortMode === 0 ? this.s2 : null,
      })
        .onChange(()=>{
          this.menuVisible = false; this.sortMode = 0; this.refreshData()
        })
      MenuItem({
        content: "按时间排序",
        symbolEndIcon: this.sortMode === 1 ? this.s2 : null
      })
        .onChange(()=>{
          this.menuVisible = false; this.sortMode = 1; this.refreshData()
        })
      MenuItem({
        content: "按分组排序",
        symbolEndIcon: this.sortMode === 2 ? this.s2 : null
      })
        .onChange(()=>{
          this.menuVisible = false; this.sortMode = 2; this.refreshData()
        })
    }
    .menuItemDivider(
      {
        strokeWidth: LengthMetrics.vp(0.5),
        color: $r('sys.color.comp_divider'),
        mode: DividerMode.EMBEDDED_IN_MENU
      }
    )
  }
  @Builder
  MyMenu(){
    Menu() {
      MenuItem({
        content: "添加文件",
        symbolEndIcon: this.s1
      })
        .onChange(()=>{
          this.menuVisible = false; this.readPickerFile();
        })
      MenuItem({
        content: "排序方式",
        builder: (): void => this.SubMenu(),
      })
      MenuItem({
        content: "多选",
        symbolEndIcon: this.s2
      })
        .onChange(() => {
          this.menuVisible = false;
          this.pageContext.openPage({ routerName: PageEnum.MULTI_SELECT_PAGE });
        })
    }
    .width(200)
    .menuItemDivider(
      {
        strokeWidth: LengthMetrics.vp(0.5),
        color: $r('sys.color.comp_divider'),
        mode: DividerMode.EMBEDDED_IN_MENU
      }
    )
    .subMenuExpandingMode(SubMenuExpandingMode.EMBEDDED_EXPAND)
    .subMenuExpandSymbol(this.expandSymbolModifier)
  }

  @Builder
  ContentBuilder(){
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Column()
          .width(1)
          .height(1)
          .position({ x: '100%', y: 0 })
          .translate({ x: -16, y: this.safeTop + 47 })
          .bindMenu(this.menuVisible, this.MyMenu(),{
            placement: Placement.BottomRight,
            onDisappear: () => { this.menuVisible = false; }
          })
        if (this.allFiles.length > 0) {
          Scroll(this.scroller) {
            Column() {
              Blank().height(this.blankHeight + this.safeTop);
              if (this.searchKeyword && this.filteredFiles.length === 0) {
                Column() {
                  Text('未找到匹配文件')
                    .fontSize(16)
                    .fontColor($r('sys.color.font_secondary'));
                }
                .width('100%')
                .height('60%')
                .justifyContent(FlexAlign.Center);
              } else if (this.searchKeyword) {
                if (this.isGridView) {
                  GridRow({
                    columns: new BreakpointType({
                      sm: 2,
                      md: 3,
                      lg: 4,
                    }).getValue(this.globalInfoModel.widthBreakpoint),
                    gutter: { x: 12, y: 12 }
                  }) {
                    ForEach(this.filteredFiles, (item: MarkdownFile) => {
                      GridCol() {
                        FileGridCard({
                          file: item,
                          onTap: () => { this.pageContext.openPage({ routerName: PageEnum.MARKDOWN_VIEWER, param: item }); },
                          onStar: () => { this.toggleStar(item); },
                          controller: this.controller
                        })
                      }
                    }, (item: MarkdownFile) => `${item.sandboxPath}_${item.isStar}_${item.groupName}`);
                  }
                  .width('100%')
                } else {
                  List({
                    space: new BreakpointType({
                      sm: 12,
                      md: 16,
                      lg: 20,
                    }).getValue(this.globalInfoModel.widthBreakpoint)
                  }) {
                    ForEach(this.filteredFiles, (item: MarkdownFile) => {
                      HdsListItem({
                        hdsListItemCard: {
                          prefixItem: new PrefixCustomBuilder(() => {
                            this.listCard(item);
                          }),
                          cardHeight: 64,
                          cardPrefixMargin:0,
                          cardSuffixMargin:0,
                          onClick: () => {
                            this.pageContext.openPage({ routerName: PageEnum.MARKDOWN_VIEWER, param: item });
                          },
                        },
                        swipeActionOptions: {
                          icons: [
                            {
                              icon: new SymbolGlyphModifier($r('sys.symbol.arrow_right_folder_fill')).fontColor([Color.White]).fontSize(16),
                              backgroundColor: '#36C972',
                              onAction: () => {
                                this.openGroupSheet(item);
                              }
                            },
                            {
                              icon: new SymbolGlyphModifier($r('sys.symbol.share')).fontColor([Color.White]).fontSize(16),
                              backgroundColor: '#3A7BFF',
                              onAction: () => {
                                this.shareTargetFile = item;
                                this.doSystemShare(item);
                              }
                            },
                            {
                              icon: new SymbolGlyphModifier($r('sys.symbol.star_fill')).fontColor([Color.White]).fontSize(16),
                              backgroundColor: '#FFC83D',
                              onAction: () => {
                                this.toggleStar(item);
                              }
                            }
                          ],
                          deleteIconOptions: {
                            backgroundColor: '#FF5A5F',
                            iconColor: Color.White,
                            onAction: () => {
                              this.confirmDeleteFile(item);
                            },
                          },
                          fullDeleteOptions: {
                            isFullDelete: true,
                            onFullDeleteAction: () => {
                              this.confirmDeleteFile(item);
                            }
                          }
                        }
                      });
                    }, (item: MarkdownFile) => `${item.sandboxPath}_${item.isStar}_${item.groupName}`);
                  }
                  .height(undefined)
                  .width('100%');
                }
              } else if (this.isStarTab()) {
                if (this.starredFiles.length > 0) {
                  if (this.isGridView) {
                    GridRow({
                      columns: new BreakpointType({
                        sm: 2,
                        md: 3,
                        lg: 4,
                      }).getValue(this.globalInfoModel.widthBreakpoint),
                      gutter: { x: 12, y: 12 }
                    }) {
                      ForEach(this.starredFiles, (item: MarkdownFile) => {
                        GridCol() {
                          FileGridCard({
                            file: item,
                            onTap: () => { this.pageContext.openPage({ routerName: PageEnum.MARKDOWN_VIEWER, param: item }); },
                            onStar: () => { this.toggleStar(item); },
                            controller: this.controller
                          })
                        }
                      }, (item: MarkdownFile) => `${item.sandboxPath}_${item.isStar}_${item.groupName}`);
                    }
                    .width('100%')
                  } else {
                    List({
                      space: new BreakpointType({
                        sm: 12,
                        md: 16,
                        lg: 20,
                      }).getValue(this.globalInfoModel.widthBreakpoint)
                    }) {
                      ForEach(this.starredFiles, (item: MarkdownFile) => {
                        HdsListItem({
                          hdsListItemCard: {
                            prefixItem: new PrefixCustomBuilder(() => {
                              this.listCard(item);
                            }),
                            cardHeight: 64,
                            cardPrefixMargin:0,
                            cardSuffixMargin:0,
                            onClick: () => {
                              this.pageContext.openPage({ routerName: PageEnum.MARKDOWN_VIEWER, param: item });
                            },
                          },
                          swipeActionOptions: {
                            icons: [
                              {
                                icon: new SymbolGlyphModifier($r('sys.symbol.folder_fill')).fontColor([Color.White]).fontSize(16),
                                backgroundColor: '#36C972',
                                onAction: () => {
                                  this.openGroupSheet(item);
                                }
                              },
                              {
                                icon: new SymbolGlyphModifier($r('sys.symbol.share')).fontColor([Color.White]).fontSize(16),
                                backgroundColor: '#3A7BFF',
                                onAction: () => {
                                  this.shareTargetFile = item;
                                  this.doSystemShare(item);
                                }
                              },
                              {
                                icon: new SymbolGlyphModifier($r('sys.symbol.star_fill')).fontColor([Color.White]).fontSize(16),
                                backgroundColor: '#FFC83D',
                                onAction: () => {
                                  this.toggleStar(item);
                                }
                              }
                            ],
                            deleteIconOptions: {
                              backgroundColor: '#FF5A5F',
                              iconColor: Color.White,
                              onAction: () => {
                                this.confirmDeleteFile(item);
                              },
                            },
                            fullDeleteOptions: {
                              isFullDelete: true,
                              onFullDeleteAction: () => {
                                this.confirmDeleteFile(item);
                              }
                            }
                          }
                        });
                      }, (item: MarkdownFile) => `${item.sandboxPath}_${item.isStar}_${item.groupName}`);
                    }
                    .height(undefined)
                    .width('100%');
                  }
                } else {
                  Column() {
                    SymbolGlyph($r('sys.symbol.star'))
                      .fontSize(48)
                      .fontColor([$r('sys.color.font_tertiary')])
                      .margin({ bottom: 12 });
                    Text('暂无收藏文件')
                      .fontSize(16)
                      .fontColor($r('sys.color.font_secondary'));
                  }
                  .width('100%')
                  .height('60%')
                  .justifyContent(FlexAlign.Center);
                }
              } else {
                if (this.isGridView) {
                  GridRow({
                    columns: new BreakpointType({
                      sm: 2,
                      md: 3,
                      lg: 4,
                    }).getValue(this.globalInfoModel.widthBreakpoint),
                    gutter: { x: 12, y: 12 }
                  }) {
                    ForEach(this.allFiles, (item: MarkdownFile) => {
                      GridCol() {
                        FileGridCard({
                          file: item,
                          onTap: () => { this.pageContext.openPage({ routerName: PageEnum.MARKDOWN_VIEWER, param: item }); },
                          onStar: () => { this.toggleStar(item); },
                          controller: this.controller
                        })
                      }
                    }, (item: MarkdownFile) => `${item.sandboxPath}_${item.isStar}_${item.groupName}`);
                  }
                  .width('100%')
                } else {
                  List({
                    space: new BreakpointType({
                      sm: 12,
                      md: 16,
                      lg: 20,
                    }).getValue(this.globalInfoModel.widthBreakpoint)
                  }) {
                    ForEach(this.allFiles, (item: MarkdownFile) => {
                      HdsListItem({
                        hdsListItemCard: {
                          prefixItem: new PrefixCustomBuilder(() => {
                            this.listCard(item);
                          }),
                          cardHeight: 64,
                          cardPrefixMargin:0,
                          cardSuffixMargin:0,
                          onClick: () => {
                            this.pageContext.openPage({ routerName: PageEnum.MARKDOWN_VIEWER, param: item });
                          },
                        },
                        swipeActionOptions: {
                          icons: [
                            {
                              icon: new SymbolGlyphModifier($r('sys.symbol.arrow_right_folder_fill')).fontColor([Color.White]).fontSize(16),
                              backgroundColor: '#36C972',
                              onAction: () => {
                                this.openGroupSheet(item);
                              }
                            },
                            {
                              icon: new SymbolGlyphModifier($r('sys.symbol.share')).fontColor([Color.White]).fontSize(16),
                              backgroundColor: '#3A7BFF',
                              onAction: () => {
                                this.shareTargetFile = item;
                                this.doSystemShare(item);
                              }
                            },
                            {
                              icon: new SymbolGlyphModifier($r('sys.symbol.star_fill')).fontColor([Color.White]).fontSize(16),
                              backgroundColor: '#FFC83D',
                              onAction: () => {
                                this.toggleStar(item);
                              }
                            }
                          ],
                          deleteIconOptions: {
                            backgroundColor: '#FF5A5F',
                            iconColor: Color.White,
                            onAction: () => {
                              this.confirmDeleteFile(item);
                            },
                          },
                          fullDeleteOptions: {
                            isFullDelete: true,
                            onFullDeleteAction: () => {
                              this.confirmDeleteFile(item);
                            }
                          }
                        }
                      });
                    }, (item: MarkdownFile) => `${item.sandboxPath}_${item.isStar}_${item.groupName}`);
                  }
                  .height(undefined)
                  .width('100%');
                }
              }
              Blank().height(56 + this.safeBottom + 8)
            }
            .width('100%')
            .constraintSize({ minHeight: '100%' })
          }
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)
          .width('100%')
          .height('100%');
        } else {
          EmptyView();
        }
      }
      .padding(new BreakpointType<Padding>({
        sm: { left: 16, right: 16 },
        md: { left: 24, right: 24 },
        lg: { left: 32, right: 32 },
      }).getValue(this.globalInfoModel.widthBreakpoint))
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .titleBar({
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(0),
          blurEffectiveEndOffset: LengthMetrics.vp(20),
        },
        scrollEffectStyle: {
          backgroundStyle: { maskExtraHeight: 56.0 }
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        }
      },
      avoidLayoutSafeArea: true,
      content: {
        title: {
          mainTitle: ''
        },
        stackBuilder: (): void => this.stackBuilder(),
        bottomBuilder: {
          builder: () => { this.BottomBuilder(); },
          showType: 1
        },
        menu: {
          value: [
            {
              content: {
                label: 'moreMenu',
                icon: $r('sys.symbol.dot_grid_2x2'),
                isEnabled: true,
                action: () => {
                  this.menuVisible = !this.menuVisible;
                }
              }
            }
          ]
        },
        subIcon: {
          content: {
            label: 'viewToggle',
            icon: this.isGridView ? $r('sys.symbol.list_bullet') : $r('sys.symbol.square_grid_2x2'),
            action: () =>{
              this.isGridView = !this.isGridView;
            }
          }
        },
      }
    })
    .titleMode(this.titleMode)
    .hideBackButton(true)
    .hideTitleBar(false)
    .onShown(() => {
      if (this.isFirstShow) {
        this.isFirstShow = false;
        return;
      }
      this.loadLocalFiles();
    })
    .bindSheet(this.showGroupSheet, this.groupSheetBuilder(), {
      detents: [SheetSize.MEDIUM, SheetSize.LARGE, 200],
      showClose: false,
      enableFloatingDragBar: true,
      dragBar: false,
      onDisappear: () => {
        this.showGroupSheet = false;
        this.groupTargetFile = null;
      }
    });

  }
  build(): void {
    this.ContentBuilder()
  }
}

@Builder
export function MdViewBuilder(): void {
  MdView();
}