import { HdsAnimationMode, hdsMaterial, HdsNavDestination, HdsTabs, HdsTabsController,  } from '@kit.UIDesignKit';
import { SymbolGlyphModifier, window } from '@kit.ArkUI';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { MdView, FileDataSource } from 'markdown';
import { Star } from 'star';
import { Mine } from 'mine';
import { PageContext, PageEnum, StorageKey, GlobalInfoModel, BreakpointType, TabBarType, TABS_LIST, HdsUtil } from 'common';

@Component({ freezeWhenInactive: true })
export struct MainPage {
  @State currentIndex: number = 0;
  @StorageLink(StorageKey.HOME_PAGE_CONTEXT) pageContext: PageContext = new PageContext();
  private controller: HdsTabsController = new HdsTabsController();
  @StorageProp('safeBottom') safeBottom: number = 0;

  // 每个 Tab 的 Scroller
  private homeScroller: Scroller = new Scroller();
  private starScroller: Scroller = new Scroller();
  private mineScroller: Scroller = new Scroller();

  @StorageProp('currentColorMode') @Watch('onColorModeChange') currentColorMode: number =
    ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @Provide('dataSource') dataSource: FileDataSource = new FileDataSource();
  @StorageLink('dataVersion') @Watch('onDataVersionChange') dataVersion: number = 0;
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();

  aboutToAppear(): void {
    this.onColorModeChange();
    this.controller.applyHideAnimation(HdsAnimationMode.CLICK_ANIMATION);
    // 绑定 Scroller 到 Tab
    this.controller.bindScroller(TabBarType.HOME, this.homeScroller);
    this.controller.bindScroller(TabBarType.STAR, this.starScroller);
    this.controller.bindScroller(TabBarType.MINE, this.mineScroller);
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

  bottomTabBarStyle(tabType: TabBarType): BottomTabBarStyle {
    const tabItem = TABS_LIST[tabType];
    const normalGlyphModifier = new SymbolGlyphModifier(tabItem.icon)
      .renderingStrategy(HdsUtil.isSupportNewMaterialApi() ? SymbolRenderingStrategy.SINGLE :
        SymbolRenderingStrategy.MULTIPLE_OPACITY);
    if (HdsUtil.isSupportNewMaterialApi()) {
      normalGlyphModifier.fontColor(HdsUtil.isSupportNewMaterialApi() ? [$r('sys.color.icon_primary')] : [])
    }
    return BottomTabBarStyle.of({
      normal: normalGlyphModifier,
      selected: new SymbolGlyphModifier(tabItem.icon)
        .renderingStrategy(HdsUtil.isSupportNewMaterialApi() ? SymbolRenderingStrategy.SINGLE :
          SymbolRenderingStrategy.MULTIPLE_OPACITY)
    }, tabItem.title)
      .labelStyle(HdsUtil.isSupportNewMaterialApi() ? { unselectedColor: $r('sys.color.font_primary') } : undefined)
      .padding({
        bottom: (this.globalInfoModel.widthBreakpoint === WidthBreakpoint.WIDTH_LG ||
          HdsUtil.isSupportNewMaterialApi()) ? 0 : this.globalInfoModel.naviIndicatorHeight
      })
  }

  @Builder
  TabContentsBuilder(showTabBar: boolean) {
    TabContent() {
      MdView({ scroller: this.homeScroller })
    }
    .tabBar(showTabBar ? this.bottomTabBarStyle(TabBarType.HOME) : new SubTabBarStyle(''))

    TabContent() {
      Star({ scroller: this.starScroller })
    }
    .tabBar(showTabBar ? this.bottomTabBarStyle(TabBarType.STAR) : new SubTabBarStyle(''))

    TabContent() {
      Mine({ scroller: this.mineScroller })
    }
    .tabBar(showTabBar ? this.bottomTabBarStyle(TabBarType.MINE) : new SubTabBarStyle(''))
  }

  build() {
    HdsNavDestination() {
      HdsTabs({ controller: this.controller, index: this.currentIndex }) {
        this.TabContentsBuilder(this.globalInfoModel.widthBreakpoint !== WidthBreakpoint.WIDTH_XL)
      }
      .onChange((index: number) => {
        this.currentIndex = index;
      })
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
        xl: 0,
      }).getValue(this.globalInfoModel.widthBreakpoint))
      .scrollable(false)
      .backgroundColor(Color.Transparent)
      .animationDuration(0)
    }
    .hideTitleBar(true)
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
}

@Builder
export function MainPageBuilder() {
  MainPage()
}
