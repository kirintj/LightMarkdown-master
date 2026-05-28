import { HdsNavDestination, ScrollEffectType, PrefixCustomBuilder } from '@hms.hds.hdsBaseComponent';
import { LengthMetrics, promptAction, SymbolGlyphModifier } from '@kit.ArkUI';
import { MarkdownFile, FileDataSource, FileGroup, MdDbService } from 'markdown';
import { common } from '@kit.AbilityKit';
import { HdsListItem, hdsMaterial, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { HdsMiniBarButton } from 'hds_button';
import { GroupSheetContent, EmptyState, GroupItem, formatRelativeTime, BreakpointType, GlobalInfoModel, StorageKey, PageContext, PageEnum } from 'common';

const TITLE_BAR_HEIGHT_FREE: number = 56 + 56 + 8;

@Component
export struct StarredPage {
  private pageContext: PageContext = AppStorage.get<PageContext>(StorageKey.HOME_PAGE_CONTEXT) ?? new PageContext();
  private dataSource: FileDataSource = AppStorage.get<FileDataSource>('dataSource') ?? new FileDataSource();
  @StorageLink('dataVersion') dataVersion: number = 0;
  @State titleMode: HdsNavDestinationTitleMode = HdsNavDestinationTitleMode.MINI;
  @State blankHeight: number = TITLE_BAR_HEIGHT_FREE;
  @StorageProp('safeTop') safeTop: number = 0;
  @StorageProp('safeBottom') safeBottom: number = 0;
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
  @State allFiles: MarkdownFile[] = [];
  @State filteredFiles: MarkdownFile[] = [];
  @State searchKeyword: string = '';
  @State groups: FileGroup[] = [];
  @State showGroupDialog: boolean = false;
  @State selectedFileForGroup: MarkdownFile | null = null;
  @State newGroupName: string = '';
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private scroller: Scroller = new Scroller();

  @Builder
  listCard(item: MarkdownFile): void {
    Row() {
      SymbolGlyph($r('sys.symbol.doc_plaintext_fill'))
        .fontSize($r('sys.float.Title_M'))
        .fontColor(['#FFC83D']);
      Column() {
        Text(item.name)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        if (item.groupName) {
          Text(item.groupName)
            .fontSize($r('sys.float.Caption_S'))
            .fontColor($r('sys.color.confirm'))
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

  async aboutToAppear(): Promise<void> {
    await this.loadData();
  }

  async loadData(): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.init();
      this.allFiles = await dbService.queryStarred();
      this.applyFilter();
      this.groups = await dbService.queryAllGroups();
    } catch (e) {
      console.error('[StarredPage] 加载数据失败:', JSON.stringify(e));
    }
  }

  private applyFilter(): void {
    if (!this.searchKeyword) {
      this.filteredFiles = [...this.allFiles];
      return;
    }
    const keyword: string = this.searchKeyword.toLowerCase();
    this.filteredFiles = this.allFiles.filter((f: MarkdownFile) => f.name.toLowerCase().includes(keyword));
  }

  private async toggleStar(item: MarkdownFile): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      const isStar: boolean = await dbService.toggleStar(item.sandboxPath);
      this.dataSource.updateItemStar(item.sandboxPath, isStar);
      this.dataVersion++;
      if (!isStar) {
        this.allFiles = this.allFiles.filter((f: MarkdownFile) => f.sandboxPath !== item.sandboxPath);
        this.applyFilter();
      }
      const msg: string = isStar ? '已收藏' : '已取消收藏';
      promptAction.openToast({ message: msg, duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[StarredPage] 切换收藏失败:', JSON.stringify(e));
    }
  }

  private async openGroupDialog(item: MarkdownFile): Promise<void> {
    this.selectedFileForGroup = item;
    const dbService = MdDbService.getInstance(this.context);
    this.groups = await dbService.queryAllGroups();
    this.showGroupDialog = true;
  }

  private async assignToGroup(groupId: number, groupName: string): Promise<void> {
    if (!this.selectedFileForGroup) return;
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.setFileGroup(this.selectedFileForGroup.sandboxPath, groupId);
      this.dataSource.updateItemGroup(this.selectedFileForGroup.sandboxPath, groupId, groupName);
      this.showGroupDialog = false;
      this.dataVersion++;
      promptAction.openToast({ message: `已加入分组「${groupName}」`, duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[StarredPage] 分组失败:', JSON.stringify(e));
    }
  }

  private async removeFromGroup(): Promise<void> {
    if (!this.selectedFileForGroup) return;
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.removeFileGroup(this.selectedFileForGroup.sandboxPath);
      this.dataSource.updateItemGroup(this.selectedFileForGroup.sandboxPath, -1, '');
      this.showGroupDialog = false;
      this.dataVersion++;
      promptAction.openToast({ message: '已移出分组', duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[StarredPage] 移出分组失败:', JSON.stringify(e));
    }
  }

  private async createAndAssignGroup(): Promise<void> {
    if (!this.newGroupName.trim()) return;
    try {
      const dbService = MdDbService.getInstance(this.context);
      const groupId: number = await dbService.createGroup(this.newGroupName.trim());
      if (this.selectedFileForGroup) {
        await dbService.setFileGroup(this.selectedFileForGroup.sandboxPath, groupId);
        this.dataSource.updateItemGroup(this.selectedFileForGroup.sandboxPath, groupId, this.newGroupName.trim());
      }
      const groupName: string = this.newGroupName.trim();
      this.newGroupName = '';
      this.showGroupDialog = false;
      this.dataVersion++;
      promptAction.openToast({ message: `已创建分组「${groupName}」`, duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[StarredPage] 创建分组失败:', JSON.stringify(e));
    }
  }

  @Builder
  SearchBuilder(): void {
    Column() {
      Search({ placeholder: '搜索收藏文件', value: this.searchKeyword })
        .searchButton('搜索', {
          fontColor: '#FFC83D'
        })
        .onChange((value: string) => {
          this.searchKeyword = value;
          this.applyFilter();
        })
        .onSubmit((value: string) => {
          this.searchKeyword = value;
          this.applyFilter();
        });
    }
    .padding(new BreakpointType<Padding>({
        sm: { left: 16, right: 16 },
        md: { left: 24, right: 24 },
        lg: { left: 32, right: 32 },
      }).getValue(this.globalInfoModel.widthBreakpoint))
  }

  build(): void {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.filteredFiles.length > 0) {
          Scroll(this.scroller) {
            Column() {
              Blank().height(this.blankHeight + this.safeTop);
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
                          icon: new SymbolGlyphModifier($r('sys.symbol.star_fill')).fontColor([Color.White]),
                          backgroundColor: '#FFC83D',
                          onAction: () => {
                            this.toggleStar(item);
                          }
                        }
                      ]
                    }
                  });
                }, (item: MarkdownFile) => item.sandboxPath);
              }
              .width('100%')
              Blank().height(this.safeBottom)
            }
            .width('100%')
            .constraintSize({ minHeight: '100%' })
          }
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)
          .width('100%')
          .height('100%');
        } else {
          Column() {
            Blank().height(this.blankHeight + this.safeTop);
            EmptyState({
              icon: $r('sys.symbol.star'),
              text: this.searchKeyword ? '未找到匹配文件' : '暂无收藏文件'
            });
          }
          .width('100%')
          .height('100%')
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center);
        }
      }
      .padding(new BreakpointType<Padding>({
        sm: { left: 16, right: 16 },
        md: { left: 24, right: 24 },
        lg: { left: 32, right: 32 },
      }).getValue(this.globalInfoModel.widthBreakpoint))
    }
    .bindContentCover(this.showGroupDialog, () => {
      GroupSheetContent({
        currentGroupId: this.selectedFileForGroup ? this.selectedFileForGroup.groupId : -1,
        groups: this.groups.map((g: FileGroup): GroupItem => ({ id: g.id, name: g.name })),
        onAssign: (id: number, name: string) => { this.assignToGroup(id, name); },
        onRemove: () => { this.removeFromGroup(); },
        onCreate: (name: string) => { this.newGroupName = name; this.createAndAssignGroup(); }
      });
    }, {
      modalTransition: ModalTransition.NONE,
      onDisappear: () => { this.showGroupDialog = false; }
    })
    .backgroundColor($r('sys.color.background_secondary'))
    .titleBar({
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(0),
          blurEffectiveEndOffset: LengthMetrics.vp(20)
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
          mainTitle: '收藏文件'
        },
        bottomBuilder: {
          builder: () => { this.SearchBuilder(); },
          showType: 1
        }
      }
    })
    .titleMode(this.titleMode)
    .hideBackButton(false)
    .hideTitleBar(false);
  }
}

@Builder
export function StarredPageBuilder() {
  StarredPage()
}