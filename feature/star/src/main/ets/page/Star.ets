import { HdsNavDestination, ScrollEffectType } from "@hms.hds.hdsBaseComponent";
import { hdsMaterial, HdsNavDestinationTitleMode } from "@kit.UIDesignKit";
import { MarkdownFile, FileDataSource, FileGroup, MdDbService } from "markdown";
import { common, ConfigurationConstant } from "@kit.AbilityKit";
import { promptAction } from "@kit.ArkUI";
import { CardItem } from '../component/CardItem'
import { McBarChart, McPieChart, Options } from '@mcui/mccharts'
import { BreakpointType, GlobalInfoModel, StorageKey } from "common";

const TITLE_BAR_HEIGHT_FREE = 56

class PieDataItem {
  value: number = 0
  name: string = ''
  constructor(value: number, name: string) {
    this.value = value
    this.name = name
  }
}

@Component
export struct Star {
  @State blankHeight: number = TITLE_BAR_HEIGHT_FREE;
  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0;
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
  @Consume('pathStack') pathStack: NavPathStack;
  @State titleMode: HdsNavDestinationTitleMode = HdsNavDestinationTitleMode.MINI;
  @Consume('dataSource') dataSource: FileDataSource;
  @Consume('dataVersion') @Watch('onDataVersionChange') dataVersion: number;
  @StorageProp('currentColorMode') @Watch('onChartColorModeChange') currentColorMode: number =
    ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @State starCount: number = 0;
  @State totalCount: number = 0;
  @State groupCount: number = 0;
  @State recentCount: number = 0;
  @State ungroupedCount: number = 0;
  @State groups: FileGroup[] = [];
  @State groupFileMap: Map<number, MarkdownFile[]> = new Map();
  @State showCreateGroupSheet: boolean = false;
  @State newGroupName: string = '';
  @State columns: number = 2;
  private scroller: Scroller = new Scroller();
  @State overviewOption: Options = new Options({
    title: { show: false },
    legend: { show: false },
    tooltip: {
      show: true,
      backgroundColor: '#E6FFFFFF',
      borderWidth: 0,
      textStyle: { color: '#182431', fontSize: 40 }
    },
    grid: { left: 36, right: 12, top: 12, bottom: 28 },
    color: ['#317AF7', '#FFC83D', '#36C972', '#C5C5C5'],
    xAxis: {
      data: ['总数', '收藏', '已分组', '未分组'],
      axisLine: { show: false },
      axisTick: { show: false },
      axisLabel: { color: '#99000000', fontSize: 42 },
    },
    yAxis: {
      axisLine: { show: false },
      axisTick: { show: false },
      splitLine: { show: true, lineStyle: { color: '#14000000', type: 'dashed' } },
      axisLabel: { color: '#99000000', fontSize: 42 }
    },
    animation: true,
    series: [{
      name: '文件数',
      data: [0, 0, 0, 0],
      barStyle: {
        width: 30,
        borderRadius: [6, 6]
      },
      itemStyle: { borderRadius: 6 }
    }]
  });
  @State groupOption: Options = new Options({
    title: { show: false },
    legend: {
      icon: 'roundRect',
      textStyle: { fontSize: 42 }
    },
    tooltip: {
      show: true,
      backgroundColor: '#E6FFFFFF',
      borderWidth: 0,
      textStyle: { color: '#182431', fontSize: 12 }
    },
    animation: true,
    series: [{
      name: '分组分布',
      radius: '75%',
      position: 'center',
      label: {
        fontSize: 12,
        formatter: (params: Object) => {
          let p = params as Record<string, Object>;
          let percent = p['percentForLabel'] as string;
          return percent + '%';
        }
      },
      labelLine: { show: true, length: 8, length2: 6 },
      data: [] as PieDataItem[]
    }]
  });
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  async aboutToAppear() {
    let lastCount = AppStorage.get<number>('columnsCount');
    if (typeof lastCount != 'undefined') {
      this.columns = lastCount;
    }
    await this.loadAllData();
  }

  onDataVersionChange(): void {
    let offset = this.scroller.currentOffset().yOffset;
    this.loadAllData().then(() => {
      this.scroller.scrollTo({ xOffset: 0, yOffset: offset });
    });
  }

  async loadAllData() {
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.init();
      await dbService.refreshGroupCache();
      this.starCount = await dbService.getStarCount();
      this.totalCount = await dbService.getTotalCount();
      this.groupCount = await dbService.getGroupCount();
      this.recentCount = await dbService.getRecentlyViewedCount();
      this.groups = await dbService.queryAllGroups();

      this.groupFileMap = new Map();
      for (const group of this.groups) {
        const files = await dbService.queryByGroup(group.id);
        this.groupFileMap.set(group.id, files);
      }
      const ungroupedFiles = await dbService.queryUngrouped();
      this.ungroupedCount = ungroupedFiles.length;

      this.overviewOption.setVal({
        series: [{
          name: '文件数',
          data: [this.totalCount, this.starCount, this.totalCount - this.ungroupedCount, this.ungroupedCount]
        }]
      });

      let pieData: PieDataItem[] = [];
      for (const group of this.groups) {
        const files = this.groupFileMap.get(group.id);
        let count = files !== undefined ? files.length : 0;
        pieData.push(new PieDataItem(count, group.name));
      }
      if (this.ungroupedCount > 0) {
        pieData.push(new PieDataItem(this.ungroupedCount, '未分组'));
      }
      this.groupOption.setVal({
        series: [{
          name: '分组分布',
          data: pieData
        }]
      });
      this.updateChartColors();
    } catch (err) {
      console.error('[Star] 加载数据失败:', JSON.stringify(err));
    }
  }

  private async createGroup() {
    if (!this.newGroupName.trim()) return;
    try {
      const dbService = MdDbService.getInstance(this.context);
      await dbService.createGroup(this.newGroupName.trim());
      await dbService.refreshGroupCache();
      const groupName = this.newGroupName.trim();
      this.newGroupName = '';
      this.showCreateGroupSheet = false;
      this.dataVersion++;
      await this.loadAllData();
      promptAction.openToast({ message: `分组「${groupName}」创建成功`, duration: 1000 }).catch(() => {});
    } catch (e) {
      console.error('[Star] 创建分组失败:', JSON.stringify(e));
    }
  }

  private isDarkMode(): boolean {
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  private updateChartColors(): void {
    let axisLabelColor = this.isDarkMode() ? '#99FFFFFF' : '#99000000';
    let splitLineColor = this.isDarkMode() ? '#14FFFFFF' : '#14000000';
    let tooltipBg = this.isDarkMode() ? '#CC222222' : '#E6FFFFFF';
    let tooltipText = this.isDarkMode() ? '#E6FFFFFF' : '#182431';
    let legendColor = this.isDarkMode() ? '#DEFFFFFF' : '#E6000000';
    let labelColor = this.isDarkMode() ? '#CCFFFFFF' : '#CC000000';
    let labelLineColor = this.isDarkMode() ? '#66FFFFFF' : '#99000000';

    this.overviewOption.setVal({
      xAxis: {
        axisLabel: { color: axisLabelColor , size: 42}
      },
      yAxis: {
        splitLine: { show: true, lineStyle: { color: splitLineColor, type: 'dashed' } },
        axisLabel: { color: axisLabelColor }
      },
      tooltip: {
        backgroundColor: tooltipBg,
        textStyle: { color: tooltipText }
      }
    });

    this.groupOption.setVal({
      legend: {
        textStyle: { color: legendColor }
      },
      tooltip: {
        backgroundColor: tooltipBg,
        textStyle: { color: tooltipText }
      },
      series: [{
        name: '分组分布',
        label: { color: labelColor },
        labelLine: { show: true, length: 8, length2: 6, lineStyle: { color: labelLineColor } }
      }]
    });
  }

  onChartColorModeChange(): void {
    this.updateChartColors();
  }

  @Builder
  sectionTitle(title: string) {
    Text(title)
      .fontSize($r('sys.float.Subtitle_M'))
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_secondary'))
      .width('100%')
      .margin({ top: 20, bottom: 12 })
  }

  @Builder
  groupCard(group: FileGroup, files: MarkdownFile[]) {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.folder_fill'))
          .fontSize(20)
          .fontColor([$r('sys.color.brand')])
        Text(group.name)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .margin({ left: 8 })
          .layoutWeight(1)
        Text(`${files.length} 个文件`)
          .fontSize($r('sys.float.Caption_S'))
          .fontColor($r('sys.color.font_secondary'))
          .margin({ right: 8 })
        SymbolGlyph($r('sys.symbol.chevron_forward'))
          .fontSize(14)
          .fontColor([$r('sys.color.font_tertiary')])
      }
      .height(56)
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    }
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .onClick(() => {
      this.pathStack.pushPath({ name: 'GroupDetail', param: group });
    })
  }

  @Builder
  createGroupSheetBuilder() {
      Column() {
        Column() {
          TextInput({ placeholder: '输入分组名称' })
            .id('group_name_input')
            .defaultFocus(true)
            .onChange((value: string) => { this.newGroupName = value; })
            .onSubmit(() => this.createGroup())
            .margin({bottom: 8})
          Button('创建')
            .type(ButtonType.Capsule)
            .backgroundColor($r('sys.color.brand'))
            .fontColor(Color.White)
            .height(36)
            .width('100%')
            .enabled(this.newGroupName.trim().length > 0)
            .onClick(() => this.createGroup())
        }
        .height(100)
        .width('100%')
        .padding({ left: 16, right: 16,})
        Blank().height(100)
      }
      .width('100%')
      .height(250)
  }

  build() {
    HdsNavDestination() {
      Scroll(this.scroller) {
        Column() {
          Blank().width('100%').height(this.blankHeight + this.safeTop)
          Grid() {
            GridItem() {
              CardItem({
                icon: $r('sys.symbol.doc_plaintext_fill_1'),
                content: '总数',
                str1: this.totalCount.toString(),
                str2: '个',
                bgcolor: $r('sys.color.brand')
              })
            }
            GridItem() {
              CardItem({
                icon: $r('sys.symbol.eye'),
                content: '最近浏览',
                str1: this.recentCount.toString(),
                str2: '个',
                bgcolor: $r('sys.color.alert')
              })
                .onClick(() => {
                  this.pathStack.pushPath({ name: 'Recent' });
                })
            }
            GridItem() {
              CardItem({
                icon: $r('sys.symbol.star_fill'),
                content: '收藏',
                str1: this.starCount.toString(),
                str2: '个',
                bgcolor: '#FFC83D',
              })
                .onClick(() => {
                  this.pathStack.pushPath({ name: 'Starred' });
                })
            }
            GridItem() {
              CardItem({
                icon: $r('sys.symbol.folder_fill'),
                content: '分组',
                str1: this.groupCount.toString(),
                str2: '个',
                bgcolor: $r('sys.color.confirm')
              })
                .onClick(() => {
                  this.pathStack.pushPath({ name: 'GroupList' });
                })
            }
          }
          .columnsTemplate('1fr '.repeat(this.columns))
          .columnsGap(16)
          .rowsGap(16)
          .width('100%')
          .scrollBar(BarState.Off)
          .height(200)

          this.sectionTitle('数据概览')
          Column() {
            McBarChart({ options: this.overviewOption })
          }
          .width('100%')
          .height(240)
          .padding({ top: 8, bottom: 8 })
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius(16)
          .shadow({ radius: 8, color: '#0A000000', offsetY: 2 })

          if (this.groups.length > 0 || this.ungroupedCount > 0) {
            this.sectionTitle('分组分布')
            Row() {
              McPieChart({ options: this.groupOption })
            }
            .width('100%')
            .height(300)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius(16)
            .shadow({ radius: 8, color: '#0A000000', offsetY: 2 })
          }
          Blank().height(56 + this.safeBottom + 8)
        }
        .padding(new BreakpointType<Padding>({
          sm: { left: 16, right: 16 },
          md: { left: 24, right: 24 },
          lg: { left: 32, right: 32 },
        }).getValue(this.globalInfoModel.widthBreakpoint))
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .constraintSize({ minHeight: '100%' })
      }
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')
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
          mainTitle: '速览',
        }
      }
    })
    .bindSheet(this.showCreateGroupSheet, this.createGroupSheetBuilder(), {
      height: 480,
      blurStyle: BlurStyle.Thick,
      title: {
        title: '新建分组',
      },
      backgroundColor: $r('sys.color.comp_background_primary'),
      onAppear: () => {
        setTimeout(() => {
          try {
            this.getUIContext()?.getFocusController()?.requestFocus('group_name_input');
          } catch (error) {
          }
        }, 300);
      },
      onDisappear: () => { this.showCreateGroupSheet = false; }
    })
  }
}
