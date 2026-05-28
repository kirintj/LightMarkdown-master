import { HdsNavDestination, ScrollEffectType, PrefixCustomBuilder } from '@hms.hds.hdsBaseComponent';
import { LengthMetrics, promptAction, SymbolGlyphModifier } from '@kit.ArkUI';
import { MarkdownFile, FileDataSource, FileGroup, MdDbService } from 'markdown';
import { common } from '@kit.AbilityKit';
import { HdsListItem, hdsMaterial, HdsNavDestinationTitleMode, IconStyleMode } from '@kit.UIDesignKit';
import { EmptyState, showDeleteConfirm, BreakpointType, GlobalInfoModel, StorageKey, PageContext, PageEnum } from 'common';
const TITLE_BAR_HEIGHT_FREE: number = 56 + 56 + 8;

@Component
export struct GroupDetailPage {
  private pageContext: PageContext = AppStorage.get<PageContext>(StorageKey.HOME_PAGE_CONTEXT) ?? new PageContext();
  private dataSource: FileDataSource = AppStorage.get<FileDataSource>('dataSource') ?? new FileDataSource();
  @StorageLink('dataVersion') dataVersion: number = 0;
  @State titleMode: HdsNavDestinationTitleMode = HdsNavDestinationTitleMode.MINI;
  @State blankHeight: number = TITLE_BAR_HEIGHT_FREE;
  @StorageProp('safeTop') safeTop: number = 0;
  @StorageProp('safeBottom') safeBottom: number = 0;
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
  groupData: FileGroup = new FileGroup(-1, '未命名分组');
  @State allFiles: MarkdownFile[] = [];
  @State filteredFiles: MarkdownFile[] = [];
  @State searchKeyword: string = '';
  @State showAddSheet: boolean = false;
  @State candidateFiles: MarkdownFile[] = [];
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private scroller: Scroller = new Scroller();

  @Builder
  listCard(item: MarkdownFile): void {
    Row() {
      SymbolGlyph($r('sys.symbol.doc_plaintext_fill'))
        .fontSize($r('sys.float.Title_M'))
        .fontColor([$r('sys.color.confirm')]);
      Column() {
        Text(item.name)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        Text(item.size)
          .fontSize($r('sys.float.Caption_S'))
          .fontColor($r('sys.color.font_secondary'))
          .margin({ top: 2 });
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
      this.allFiles = await dbService.queryByGroup(this.groupData.id);
      this.applyFilter();
    } catch (e) {
      console.error('[GroupDetailPage] 加载数据失败:', JSON.stringify(e));
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

  private async loadCandidateFiles(): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      const all: MarkdownFile[] = await dbService.queryAll();
      this.candidateFiles = all.filter((f: MarkdownFile) => f.groupId !== this.groupData.id);
    } catch (e) {
      console.error('[GroupDetailPage] 加载候选文件失败:', JSON.stringify(e));
    }
  }

  private async addFileToGroup(file: MarkdownFile): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.setFileGroup(file.sandboxPath, this.groupData.id);
      this.dataSource.updateItemGroup(file.sandboxPath, this.groupData.id, this.groupData.name);
      this.dataVersion++;
      await this.loadData();
      promptAction.openToast({ message: `已添加「${file.name}」`, duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[GroupDetailPage] 添加文件失败:', JSON.stringify(e));
    }
  }

  private async removeFileFromGroup(file: MarkdownFile): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.removeFileGroup(file.sandboxPath);
      this.dataSource.updateItemGroup(file.sandboxPath, -1, '');
      this.dataVersion++;
      await this.loadData();
      promptAction.openToast({ message: '已移出分组', duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[GroupDetailPage] 移出分组失败:', JSON.stringify(e));
    }
  }

  private async toggleStar(item: MarkdownFile): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      const isStar: boolean = await dbService.toggleStar(item.sandboxPath);
      this.dataSource.updateItemStar(item.sandboxPath, isStar);
      this.dataVersion++;
      await this.loadData();
      const msg: string = isStar ? '已收藏' : '已取消收藏';
      promptAction.openToast({ message: msg, duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[GroupDetailPage] 切换收藏失败:', JSON.stringify(e));
    }
  }

  private showDeleteGroup(): void {
    showDeleteConfirm(this.getUIContext(), `分组「${this.groupData.name}」`, () => { this.deleteGroup(); });
  }

  private async deleteGroup(): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.deleteGroup(this.groupData.id);
      this.dataSource.removeItemGroup(this.groupData.id);
      this.dataVersion++;
      this.pageContext.popPage();
      promptAction.openToast({ message: '分组已删除', duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[GroupDetailPage] 删除分组失败:', JSON.stringify(e));
    }
  }

  @Builder
  addFileSheetBuilder(){
      HdsNavDestination(){
        Scroll(this.scroller){
          Column(){
            if (this.candidateFiles.length > 0) {
              List({ space: 8 }) {
                ForEach(this.candidateFiles, (file: MarkdownFile) => {
                  HdsListItem({
                    hdsListItemCard: {
                      prefixItem: new PrefixCustomBuilder(() => {
                        this.candidateFileCard(file);
                      }),
                      cardHeight: 64,
                      cardPrefixMargin:0,
                      cardSuffixMargin:0,
                      onClick: () => {
                        this.addFileToGroup(file);
                      },
                    },
                  });
                }, (file: MarkdownFile) => file.sandboxPath);
              }
              .height(undefined)
              .width('100%')
            } else {
              Column() {
                Text('没有可添加的文件')
                  .fontSize(14)
                  .fontColor($r('sys.color.font_secondary'));
              }
              .width('100%')
              .height(120)
              .justifyContent(FlexAlign.Center);
            }
          }
          .constraintSize({ minHeight: '100%' })
          .width('100%')
        }
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .height('100%')
      }
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
            mainTitle: '添加文件到分组',
          },
          menu: {
            value: [{
              content: {
                icon: $r('sys.symbol.xmark'),
                type: IconStyleMode.SMALL,
                action: () => {
                  this.showAddSheet = false;
                },
              }
            }]
          },
        },
      })
  }

  @Builder
  candidateFileCard(file: MarkdownFile): void {
    Row() {
      SymbolGlyph($r('sys.symbol.doc_plaintext_fill'))
        .fontSize($r('sys.float.Title_M'))
        .fontColor([$r('sys.color.brand')]);
      Column() {
        Text(file.name)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        Text(file.size)
          .fontSize($r('sys.float.Caption_S'))
          .fontColor($r('sys.color.font_secondary'))
          .margin({ top: 2 });
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: $r('sys.float.padding_level6') })
      .layoutWeight(1);
      Blank();
      SymbolGlyph($r('sys.symbol.plus_circle'))
        .fontSize(24)
        .fontColor([$r('sys.color.brand')]);
    }
    .width('100%')
    .padding($r('sys.float.padding_level6'));
  }

  @Builder
  SearchBuilder(): void {
    Column() {
      Search({ placeholder: '搜索分组内文件', value: this.searchKeyword })
        .searchButton('搜索', {
          fontColor: $r('sys.color.confirm')
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
    .height(56);
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.filteredFiles.length > 0) {
          Scroll() {
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
                          icon: new SymbolGlyphModifier($r('sys.symbol.folder_badge_arrow_left')).fontColor([Color.White]),
                          backgroundColor: '#FF9500',
                          onAction: () => {
                            this.removeFileFromGroup(item);
                          }
                        },
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
              icon: $r('sys.symbol.folder'),
              text: this.searchKeyword ? '未找到匹配文件' : '分组内暂无文件'
            });
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center);
        }
      }
      .padding(new BreakpointType<Padding>({
        sm: { left: 16, right: 16 },
        md: { left: 24, right: 24 },
        lg: { left: 32, right: 32 },
      }).getValue(this.globalInfoModel.widthBreakpoint))
    }
    .bindSheet(this.showAddSheet, this.addFileSheetBuilder(), {
      detents: [SheetSize.MEDIUM, SheetSize.LARGE],
      showClose: false,
      enableFloatingDragBar: true,
      onDisappear: () => { this.showAddSheet = false; }
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
          mainTitle: this.groupData.name?.trim() || '分组详情'
        },
        bottomBuilder: {
          builder: () => { this.SearchBuilder(); },
          showType: 1
        },
        menu: {
          value: [{
            content: {
              label: '添加',
              icon: $r('sys.symbol.arrow_right_folder_circle'),
              isEnabled: true,
              action: () => {
                this.loadCandidateFiles();
                this.showAddSheet = true;
              }
            }
          }, {
            content: {
              label: '删除分组',
              icon: $r('sys.symbol.trash'),
              isEnabled: true,
              action: () => {
                this.showDeleteGroup();
              }
            }
          }]
        }
      }
    })
    .titleMode(this.titleMode)
    .hideBackButton(false)
    .hideTitleBar(false);
  }
}

@Builder
export function GroupDetailPageBuilder() {
  GroupDetailPage()
}
