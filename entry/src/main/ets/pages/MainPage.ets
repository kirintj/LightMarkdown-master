import { HdsAnimationMode, hdsMaterial, HdsNavigation, HdsNavDestination, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { DarkModeSetting, Mine, AboutPage, GuidePage, FeedbackPage } from 'mine';
import { SymbolGlyphModifier, window } from '@kit.ArkUI';
import { ConfigurationConstant, common } from '@kit.AbilityKit';
import { MarkdownViewerPage, MdView, MarkdownFile, FileDataSource, FileGroup, MultiSelectPage } from 'markdown';
import { Star, StarredPage, GroupDetailPage, GroupListPage, RecentPage } from 'star';
import { PageContext, PageEnum, StorageKey, GlobalInfoModel, BreakpointType } from 'common';

@Component
struct MainPage {
  @StorageLink(StorageKey.HOME_PAGE_CONTEXT) pageContext: PageContext = new PageContext();
  private controller: HdsTabsController = new HdsTabsController();
  @StorageProp('safeBottom') safeBottom: number = 0;
  @State currentIndex: number = 0;

  @State s1: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.house_fill'));
  @State s2: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.discover_fill'));
  @State s3: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.person_crop_circle_fill_1'));
  @StorageProp('currentColorMode') @Watch('onColorModeChange') currentColorMode: number =
    ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @Provide('dataSource') dataSource: FileDataSource = new FileDataSource();
  @Provide('dataVersion') @Watch('onDataVersionChange') dataVersion: number = 0;
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();

  aboutToAppear(): void {
    this.onColorModeChange();
    this.controller.applyHideAnimation(HdsAnimationMode.CLICK_ANIMATION);
    AppStorage.setOrCreate<FileDataSource>('dataSource', this.dataSource);
    AppStorage.setOrCreate<number>('dataVersion', 0);
  }

  onColorModeChange(): void {
    let windowClass = AppStorage.get<window.Window>('windowClass');
    if (!windowClass) return;
    if (this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
      windowClass.setWindowSystemBarProperties({
        statusBarContentColor: '#000000'
      }).catch(() => {});
    } else if (this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      windowClass.setWindowSystemBarProperties({
        statusBarContentColor: '#FFFFFF'
      }).catch(() => {});
    }
  }

  onDataVersionChange(): void {
    AppStorage.setOrCreate<number>('dataVersion', this.dataVersion);
  }

  build() {
    HdsNavigation(this.pageContext.navPathStack) {
      HdsNavDestination() {
        HdsTabs({ controller: this.controller }) {
          TabContent() {
            MdView()
          }
          .tabBar(new BottomTabBarStyle({
            normal: this.s1,
          }, '首页'))

          TabContent() {
            Star()
          }
          .tabBar(new BottomTabBarStyle({
            normal: this.s2,
          }, '速览'))

          TabContent() {
            Mine()
          }
          .tabBar(new BottomTabBarStyle({
            normal: this.s3,
          }, '我的'))
        }
        .barFloatingStyle({
          barBottomMargin: this.safeBottom,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.IMMERSIVE,
            materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
          },
          miniBar: {
            miniBarBuilder: () => this.miniSearch(),
            miniBarWidth: {
              largeWidth: 56,
              mediumWidth: 56,
            }
          },
          adaptToHandedness: true
        })
        .barOverlap(true)
        .barPosition(this.globalInfoModel.widthBreakpoint === WidthBreakpoint.WIDTH_LG ?
          BarPosition.Start : BarPosition.End)
        .vertical(this.globalInfoModel.widthBreakpoint === WidthBreakpoint.WIDTH_LG)
        .barHeight(new BreakpointType<Length>({
          sm: 56,
          md: 56,
          lg: '100%',
        }).getValue(this.globalInfoModel.widthBreakpoint))
        .scrollable(false)
        .backgroundColor(Color.Transparent)
        .animationDuration(0)
      }
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.PageMap)
    .width('100%')
    .height('100%')
  }

  @Builder
  miniSearch() {
    Row() {
      Column() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(24)
          .fontColor([$r('sys.color.font_tertiary')])
      }
      .width(56).height(56).justifyContent(FlexAlign.Center)
    }
    .onClick(() => {
      this.pageContext.openPage({ routerName: PageEnum.MULTI_SELECT_PAGE });
    })
  }

  @Builder
  PageMap(name: string, param: object) {
    if (name === PageEnum.MARKDOWN_VIEWER) {
      MarkdownViewerPage({ fileData: param as MarkdownFile })
    } else if (name === PageEnum.STARRED_PAGE) {
      StarredPage()
    } else if (name === PageEnum.GROUP_DETAIL_PAGE) {
      GroupDetailPage({ groupData: param as FileGroup })
    } else if (name === PageEnum.GROUP_LIST_PAGE) {
      GroupListPage()
    } else if (name === PageEnum.RECENT_PAGE) {
      RecentPage()
    } else if (name === PageEnum.MULTI_SELECT_PAGE) {
      MultiSelectPage()
    } else if (name === PageEnum.DARK_MODE_SETTING) {
      DarkModeSetting()
    } else if (name === PageEnum.ABOUT_PAGE) {
      AboutPage()
    } else if (name === PageEnum.GUIDE_PAGE) {
      GuidePage()
    } else if (name === PageEnum.FEEDBACK_PAGE) {
      FeedbackPage()
    }
  }
}

@Builder
export function MainPageBuilder() {
  MainPage()
}

@Builder
export function MarkdownViewerBuilder() {
  // Handled by PageMap
}

@Builder
export function StarredPageBuilder() {
  // Handled by PageMap
}

@Builder
export function GroupDetailPageBuilder() {
  // Handled by PageMap
}

@Builder
export function GroupListPageBuilder() {
  // Handled by PageMap
}

@Builder
export function RecentPageBuilder() {
  // Handled by PageMap
}

@Builder
export function MultiSelectPageBuilder() {
  // Handled by PageMap
}

@Builder
export function DarkModeSettingBuilder() {
  // Handled by PageMap
}

@Builder
export function AboutPageBuilder() {
  // Handled by PageMap
}

@Builder
export function GuidePageBuilder() {
  // Handled by PageMap
}

@Builder
export function FeedbackPageBuilder() {
  // Handled by PageMap
}
