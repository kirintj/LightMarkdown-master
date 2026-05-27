import { HdsAnimationMode, hdsMaterial, HdsNavigation, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { DarkModeSetting, Mine, AboutPage, GuidePage, FeedbackPage } from 'mine';
import {  SymbolGlyphModifier, window } from '@kit.ArkUI';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { MarkdownViewerPage, MdView, MarkdownFile, FileDataSource, MdDbService, FileGroup, MultiSelectPage } from 'markdown';
import { common } from '@kit.AbilityKit';
import picker from '@ohos.file.picker';
import { fileIo as fs } from '@kit.CoreFileKit';
import { Star, StarredPage, GroupDetailPage, GroupListPage, RecentPage } from 'star';
import { motion } from '@kit.MultimodalAwarenessKit';
import { BreakpointManager } from 'common';
@Entry
@Component
struct Index {
  @Provide('pathStack') pathStack: NavPathStack = new NavPathStack();
  private controller: HdsTabsController = new HdsTabsController();
  @StorageProp('safeBottom') safeBottom: number = 0
  @StorageProp('currentBreakpoint') @Watch('onBreakpointChange') currentBreakpoint: string = 'sm';
  private breakpointManager: BreakpointManager = BreakpointManager.getInstance();
  @State currentIndex: number = 0;

  @State s1: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.house_fill'));
  @State s2: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.discover_fill'));
  @State s3: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.person_crop_circle_fill_1'));
  @State hand: number = 0;
  @StorageProp('currentColorMode') @Watch('onColorModeChange') currentColorMode: number =
    ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @Provide('dataSource') dataSource: FileDataSource = new FileDataSource();
  @Provide('dataVersion')  dataVersion: number = 0;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  @State minNavBarWidth: Dimension | undefined = undefined;
  @State maxNavBarWidth: Dimension | undefined = undefined;
  @State minContentWidth: Dimension|undefined = 320;

  aboutToAppear(): void {
    this.onColorModeChange();
    this.controller.applyHideAnimation(HdsAnimationMode.CLICK_ANIMATION);
    // 初始化断点管理器
    const windowClass = AppStorage.get<window.Window>('windowClass') as window.Window;
    this.breakpointManager.init(windowClass);
  }


  onBreakpointChange(): void {
    console.info('[Index] Breakpoint changed to: ' + this.currentBreakpoint);
  }

  onColorModeChange(): void {
    // Get the current application window
    let windowClass = AppStorage.get<window.Window>('windowClass') as window.Window;
    if (this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
      // Currently in light color mode
      //Set the font to black
      windowClass.setWindowSystemBarProperties({
        // Status bar text color
        statusBarContentColor: '#000000'
      }).catch(() => {
        // TODO: Implement error handling.
      });
    } else if (this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      // Currently in dark mode
      //Set the font to white
      windowClass.setWindowSystemBarProperties({
        // Status bar text color
        statusBarContentColor: '#FFFFFF'
      }).catch(() => {
        // TODO: Implement error handling.
      });
    } else {
      console.warn("Unsupported color mode")
    }
  }


  @Builder
  PageMap(name: string, param: object) {
    if (name === 'First') {
      MdView()
    } else if (name === 'MarkdownViewer') {
      MarkdownViewerPage({ fileData: param as MarkdownFile })
    } else if (name === 'Star') {
      Star()
    } else if (name === 'Starred') {
      StarredPage()
    } else if (name === 'GroupDetail') {
      GroupDetailPage({ groupData: param as FileGroup })
    } else if (name === 'GroupList') {
      GroupListPage()
    } else if (name === 'Recent') {
      RecentPage()
    } else if (name === 'MultiSelect') {
      MultiSelectPage()
    } else if (name === 'Mine') {
      Mine()
    }else if(name === 'DarkModeSetting'){
      DarkModeSetting()
    } else if (name === 'AboutPage') {
      AboutPage()
    } else if (name === 'GuidePage') {
      GuidePage()
    } else if (name === 'FeedbackPage') {
      FeedbackPage()
    }
  }

  build() {
    HdsNavigation(this.pathStack) {
      Stack() {
        if (this.breakpointManager.isPhone()) {
          // 手机布局：单列
          this.buildPhoneLayout()
        } else if (this.breakpointManager.isFoldable()) {
          // 折叠屏布局：可选双列
          this.buildFoldableLayout()
        } else {
          // 平板布局：双栏或三栏
          this.buildTabletLayout()
        }
      }
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.PageMap)
    .width('100%')
    .height('100%')
  }

  @Builder
  buildPhoneLayout() {
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
    .barPosition(BarPosition.End)
    .vertical(false)
    .scrollable(false)
    .backgroundColor(Color.Transparent)
    .animationDuration(0)
  }

  @Builder
  buildFoldableLayout() {
    Row() {
      // 侧边栏（可收起）
      Column() {
        // 导航菜单
      }
      .width(this.currentBreakpoint === 'md' ? '30%' : '0%')
      .height('100%')

      // 内容区
      Column() {
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
        .barPosition(BarPosition.End)
        .vertical(false)
        .scrollable(false)
        .backgroundColor(Color.Transparent)
        .animationDuration(0)
      }
      .width(this.currentBreakpoint === 'md' ? '70%' : '100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTabletLayout() {
    Row() {
      // 侧边栏（常驻）
      Column() {
        // 导航菜单
      }
      .width('20%')
      .height('100%')

      // 内容区
      Column() {
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
        .barPosition(BarPosition.End)
        .vertical(false)
        .scrollable(false)
        .backgroundColor(Color.Transparent)
        .animationDuration(0)
      }
      .width('80%')
      .height('100%')
    }
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
      this.readPickerFile()
    })
  }

  // Index 页面 - 支持多选导入文件
  async readPickerFile() {
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

    } catch (err) {
      console.error("批量导入失败: " + JSON.stringify(err));
    }
  }
}
