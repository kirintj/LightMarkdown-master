import { HdsNavDestination, ScrollEffectType, PrefixCustomBuilder } from '@hms.hds.hdsBaseComponent';
import { LengthMetrics, promptAction, SymbolGlyphModifier } from '@kit.ArkUI';
import { FileGroup, MdDbService } from 'markdown';
import { common } from '@kit.AbilityKit';
import { HdsListItem, hdsMaterial, HdsNavDestinationTitleMode, IconStyleMode } from '@kit.UIDesignKit';
import { EmptyState } from 'common';

const TITLE_BAR_HEIGHT_FREE: number = 56 + 56 + 8;

@Component
export struct GroupListPage {
  @Consume('pathStack') pathStack: NavPathStack;
  @Consume('dataVersion') dataVersion: number;
  @State titleMode: HdsNavDestinationTitleMode = HdsNavDestinationTitleMode.MINI;
  @State blankHeight: number = TITLE_BAR_HEIGHT_FREE;
  @StorageProp('safeTop') safeTop: number = 0;
  @StorageProp('safeBottom') safeBottom: number = 0;
  @State groups: FileGroup[] = [];
  @State filteredGroups: FileGroup[] = [];
  @State searchKeyword: string = '';
  @State groupFileCounts: Map<number, number> = new Map();
  @State showCreateSheet: boolean = false;
  @State newGroupName: string = '';
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  async aboutToAppear(): Promise<void> {
    await this.loadData();
  }

  async loadData(): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.init();
      this.groups = await dbService.queryAllGroups();
      this.groupFileCounts = new Map();
      for (const group of this.groups) {
        const count: number = await dbService.getGroupFileCount(group.id);
        this.groupFileCounts.set(group.id, count);
      }
      this.applyFilter();
    } catch (e) {
      console.error('[GroupListPage] 加载数据失败:', JSON.stringify(e));
    }
  }

  private applyFilter(): void {
    if (!this.searchKeyword) {
      this.filteredGroups = [...this.groups];
      return;
    }
    const keyword: string = this.searchKeyword.toLowerCase();
    this.filteredGroups = this.groups.filter((g: FileGroup) => g.name.toLowerCase().includes(keyword));
  }

  private async createGroup(): Promise<void> {
    if (!this.newGroupName.trim()) return;
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.createGroup(this.newGroupName.trim());
      const groupName: string = this.newGroupName.trim();
      this.newGroupName = '';
      this.showCreateSheet = false;
      this.dataVersion++;
      await this.loadData();
      promptAction.openToast({ message: `分组「${groupName}」创建成功`, duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[GroupListPage] 创建分组失败:', JSON.stringify(e));
    }
  }

  private async deleteGroup(groupId: number): Promise<void> {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.deleteGroup(groupId);
      this.dataVersion++;
      await this.loadData();
      promptAction.openToast({ message: '分组已删除', duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[GroupListPage] 删除分组失败:', JSON.stringify(e));
    }
  }

  @Builder
  createGroupSheetBuilder() {
    HdsNavDestination(){
      Scroll() {
        Column() {
          TextInput({ placeholder: '输入分组名称' })
            .id('group_name_input')
            .defaultFocus(true)
            .onChange((value: string) => { this.newGroupName = value; })
            .onSubmit(() => this.createGroup())
            .margin({bottom: 16})
          Button('创建')
            .type(ButtonType.Capsule)
            .backgroundColor($r('sys.color.brand'))
            .fontColor(Color.White)
            .height(36)
            .width('100%')
            .enabled(this.newGroupName.trim().length > 0)
            .onClick(() => this.createGroup())
        }
        .width('100%')
        .padding({ left: 16, right: 16,})
      }
      .clip(false)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
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
          mainTitle: '新建分组',
        },
        menu: {
          value: [{
            content: {
              icon: $r('sys.symbol.xmark'),
              type: IconStyleMode.SMALL,
              action: () => {
                this.showCreateSheet = false;
              },
            }
          }]
        },
      },

    })
  }


  @Builder
  listCard(group: FileGroup): void {
    Row() {
      SymbolGlyph($r('sys.symbol.folder_fill'))
        .fontSize($r('sys.float.Title_M'))
        .fontColor([$r('sys.color.confirm')]);
      Column() {
        Text(group.name)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        Text(`${this.groupFileCounts.get(group.id) ?? 0} 个文件`)
          .fontSize($r('sys.float.Caption_S'))
          .fontColor($r('sys.color.font_secondary'))
          .margin({ top: 2 });
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: $r('sys.float.padding_level6') })
      .layoutWeight(1);
      Blank();
      SymbolGlyph($r('sys.symbol.chevron_forward'))
        .fontSize(14)
        .fontColor([$r('sys.color.font_tertiary')]);
    }
    .width('100%')
    .padding($r('sys.float.padding_level6'));
  }

  @Builder
  SearchBuilder(): void {
    Column() {
      Search({ placeholder: '搜索分组', value: this.searchKeyword })
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
    .padding({ left: 16, right: 16 });
  }

  build(): void {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.filteredGroups.length > 0) {
          Scroll() {
            Column() {
              Blank().height(this.blankHeight + this.safeTop);
              List({ space: 12 }) {
                ForEach(this.filteredGroups, (group: FileGroup) => {
                  HdsListItem({
                    hdsListItemCard: {
                      prefixItem: new PrefixCustomBuilder(() => {
                        this.listCard(group);
                      }),
                      cardHeight: 64,
                      onClick: () => {
                        this.pathStack.pushPath({ name: 'GroupDetail', param: group });
                      },
                    },
                    swipeActionOptions: {
                      icons: [
                        {
                          icon: new SymbolGlyphModifier($r('sys.symbol.trash')).fontColor([Color.White]),
                          backgroundColor: '#FF5A5F',
                          onAction: () => {
                            this.deleteGroup(group.id);
                          }
                        }
                      ]
                    }
                  });
                }, (group: FileGroup) => group.id.toString());
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
              text: this.searchKeyword ? '未找到匹配分组' : '暂无分组'
            });
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center);
        }
      }
      //.padding({ left: 16, right: 16 });
    }
    .bindSheet(this.showCreateSheet, this.createGroupSheetBuilder(), {
      showClose: false,
      enableFloatingDragBar: true,
      backgroundColor: $r('sys.color.comp_background_primary'),
      onDisappear: () => { this.showCreateSheet = false; }
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
          mainTitle: '文件分组'
        },
        bottomBuilder: {
          builder: () => { this.SearchBuilder(); },
          showType: 1
        },
        menu: {
          value: [{
            content: {
              label: '新建分组',
              icon: $r('sys.symbol.folder_badge_plus'),
              isEnabled: true,
              action: () => { this.showCreateSheet = true; }
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