import { HdsNavDestination, ScrollEffectType, PrefixCustomBuilder } from '@hms.hds.hdsBaseComponent';
import { LengthMetrics, promptAction, SymbolGlyphModifier } from '@kit.ArkUI';
import { MarkdownFile, FileDataSource, MdDbService } from 'markdown';
import { common } from '@kit.AbilityKit';
import { HdsListItem, hdsMaterial, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { EmptyState, formatRelativeTime, BreakpointType, GlobalInfoModel, StorageKey } from 'common';

const TITLE_BAR_HEIGHT_FREE: number = 56 + 56 + 8;

@Component
export struct RecentPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @Consume('dataSource') dataSource: FileDataSource;
  @Consume('dataVersion') dataVersion: number;
  @State titleMode: HdsNavDestinationTitleMode = HdsNavDestinationTitleMode.MINI;
  @State blankHeight: number = TITLE_BAR_HEIGHT_FREE;
  @StorageProp('safeTop') safeTop: number = 0;
  @StorageProp('safeBottom') safeBottom: number = 0;
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
  @State allFiles: MarkdownFile[] = [];
  @State filteredFiles: MarkdownFile[] = [];
  @State searchKeyword: string = '';
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private scroller: Scroller = new Scroller();

  @Builder
  listCard(item: MarkdownFile): void {
    Row() {
      SymbolGlyph($r('sys.symbol.doc_plaintext_fill'))
        .fontSize($r('sys.float.Title_M'))
        .fontColor([$r('sys.color.alert')]);
      Column() {
        Text(item.name)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        Text(formatRelativeTime(item.lastViewedAt))
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
      this.allFiles = await dbService.queryRecentlyViewed();
      this.applyFilter();
    } catch (e) {
      console.error('[RecentPage] 加载数据失败:', JSON.stringify(e));
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
      const idx: number = this.allFiles.findIndex((f: MarkdownFile) => f.sandboxPath === item.sandboxPath);
      if (idx >= 0) {
        this.allFiles[idx].isStar = isStar;
        this.applyFilter();
      }
      const msg: string = isStar ? '已收藏' : '已取消收藏';
      promptAction.openToast({ message: msg, duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[RecentPage] 切换收藏失败:', JSON.stringify(e));
    }
  }

  @Builder
  SearchBuilder(): void {
    Column() {
      Search({ placeholder: '搜索最近浏览', value: this.searchKeyword })
        .searchButton('搜索', {
          fontColor: $r('sys.color.alert')
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
                        this.pathStack.pushPath({ name: 'MarkdownViewer', param: item });
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
              icon: $r('sys.symbol.clock'),
              text: this.searchKeyword ? '未找到匹配文件' : '暂无浏览记录'
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
          mainTitle: '最近浏览'
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
