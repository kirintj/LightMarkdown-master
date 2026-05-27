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

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }){
        Scroll(){
          Column(){
            Blank().width('100%').height(this.blankHeight + this.safeTop)

            // Stats card
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

            // Settings section
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

            // Account section
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
                    symbolSrc: $r('sys.symbol.person'),
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
                    symbolSrc: $r('sys.symbol.arrow_clockwise_circle_fill'),
                    onclick: () => {},
                  })
                }
                .height(undefined)
                .width('100%')

                ListItem({ style: ListItemStyle.CARD }) {
                  CardItem({
                    isShow: true,
                    textContent: '恢复数据',
                    symbolSrc: $r('sys.symbol.arrow_2_circlepath'),
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

            // About section
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
                    onclick: () => {
                      this.pathStack.pushPath({ name: 'GuidePage' });
                    },
                  })
                }
                .height(undefined)
                .width('100%')

                ListItem({ style: ListItemStyle.CARD }) {
                  CardItem({
                    isShow: true,
                    textContent: '意见反馈',
                    symbolSrc: $r('sys.symbol.warning'),
                    onclick: () => {
                      this.pathStack.pushPath({ name: 'FeedbackPage' });
                    },
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

@Builder
export function MineBuilder() {
  Mine()
}
