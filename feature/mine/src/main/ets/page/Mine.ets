import { HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType,
  hdsMaterial } from "@kit.UIDesignKit";
import { ConfigurationConstant } from "@kit.AbilityKit";
import { CardItem, BreakpointType, GlobalInfoModel, StorageKey, PageContext, PageEnum,
  AccountService, UserAccount, AccountEvent } from "common";
import { MdDbService, FileDataSource, MarkdownFile } from 'markdown';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { emitter } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

const TITLE_BAR_HEIGHT_FREE: number = 56;

@Component
export struct Mine {
  scroller: Scroller = new Scroller();
  @State blankHeight: number = TITLE_BAR_HEIGHT_FREE;
  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
  private pageContext: PageContext = AppStorage.get<PageContext>(StorageKey.HOME_PAGE_CONTEXT) ?? new PageContext();
  @Consume('dataSource') dataSource: FileDataSource;
  @StorageLink('dataVersion') @Watch('onDataVersionChange') dataVersion: number = 0;
  @State titleMode: HdsNavDestinationTitleMode = HdsNavDestinationTitleMode.MINI;
  @StorageProp('currentColorMode') isDarkMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  @State totalCount: number = 0;
  @State groupCount: number = 0;
  @State storageUsed: string = '计算中...';
  @State sortMode: number = 0;
  @State defaultViewIsGrid: boolean = false;
  @State isLogin: boolean = false;
  @State avatarUrl: string = '';
  @State nickName: string = '';
  @State isShowAccountInfo: boolean = false;
  @State showConfirmLoginDialog: boolean = false;
  @State tempAvatarUrl: string = '';
  @State tempNickName: string = '';
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  async aboutToAppear(): Promise<void> {
    await this.loadStats();
    this.sortMode = AppStorage.get<number>('defaultSortMode') ?? 0;
    this.defaultViewIsGrid = AppStorage.get<boolean>('defaultViewIsGrid') ?? false;

    // 监听登录事件
    emitter.on(AccountEvent.BIND_MINE_LOGIN_EVENT, () => {
      this.updateAccountData();
    });

    // 监听登出事件
    emitter.on(AccountEvent.BIND_LOGOUT_EVENT, () => {
      this.updateAccountData();
    });

    // 初始化账号状态
    this.updateAccountData();
  }

  aboutToDisappear() {
    emitter.off(AccountEvent.BIND_MINE_LOGIN_EVENT);
    emitter.off(AccountEvent.BIND_LOGOUT_EVENT);
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

  updateAccountData() {
    const userInfo = AccountService.getInstance().getUserInfo();
    if (userInfo) {
      this.isLogin = true;
      this.avatarUrl = userInfo.avatarUrl;
      this.nickName = userInfo.nickname;
    } else {
      this.isLogin = false;
      this.avatarUrl = '';
      this.nickName = '';
    }
  }

  handleLogin() {
    const uiContext = this.getUIContext();
    AccountService.getInstance().login(uiContext)
      .then((userAccount) => {
        this.tempAvatarUrl = userAccount.avatarUrl;
        this.tempNickName = userAccount.nickname;
        this.showConfirmLoginDialog = true;
      })
  }

  handleConfirmLogin() {
    AccountService.getInstance().confirmLogin();
    this.showConfirmLoginDialog = false;
  }

  build() {
    this.ContentBuilder()
  }

  @Builder
  ContentBuilder() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }){
        Scroll(this.scroller){
          Column(){
            Blank().width('100%').height(this.blankHeight + this.safeTop)
            List({ space: 0 }) {
              ListItemGroup() {
                ListItem({ style: ListItemStyle.CARD }) {
                  Row() {
                    if (this.isLogin) {
                      if (this.avatarUrl) {
                        Image(this.avatarUrl)
                          .draggable(false)
                          .width(48)
                          .height(48)
                          .borderRadius(24)
                      } else {
                        Text(this.nickName.slice(-1))
                          .width(48)
                          .height(48)
                          .borderRadius(24)
                          .backgroundColor($r('sys.color.ohos_id_color_tertiary'))
                          .linearGradient({
                            colors: [
                              [$r('sys.color.ohos_id_color_tertiary'), 0.0],
                              [$r('sys.color.ohos_id_color_foreground_contrary'), 1.0],
                            ],
                          })
                          .fontColor($r('sys.color.font_on_primary'))
                          .fontSize(20)
                          .fontWeight(FontWeight.Bold)
                          .textAlign(TextAlign.Center)
                      }
                      Text(this.nickName)
                        .margin({ left: 12 })
                        .fontColor($r('sys.color.font_primary'))
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                    } else {
                      SymbolGlyph($r('sys.symbol.person_crop_circle_fill_1'))
                        .fontSize(48)
                        .fontColor([$r('sys.color.icon_fourth')])
                      Text('未登录')
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                        .fontColor($r('sys.color.font_primary'))
                        .margin({ left: 12 })
                    }
                  }
                  .width('100%')
                  .height(68)
                  .bindSheet($$this.isShowAccountInfo, this.AccountSheetBuilder, {
                    height: 200,
                    preferType: SheetType.CENTER,
                    enableOutsideInteractive: false,
                  })
                  .onClick(() => {
                    if (!this.isLogin) {
                      this.handleLogin();
                    } else {
                      this.isShowAccountInfo = true;
                    }
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
            .margin({bottom: 12})
            .height(undefined)
            .width('100%')
            .edgeEffect(EdgeEffect.Spring)

            List({ space: 0 }) {
              ListItemGroup() {
                ListItem({ style: ListItemStyle.CARD }) {
                  Row() {
                    SymbolGlyph($r('sys.symbol.text_and_arrow_down'))
                      .fontSize($r('sys.float.Title_M'))
                      .fontColor([$r('sys.color.icon_secondary')])
                    Text('默认排序方式')
                      .fontSize($r('sys.float.Subtitle_M'))
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('sys.color.font_primary'))
                      .margin({ left: $r('sys.float.padding_level8') })
                    Blank()
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
                    SymbolGlyph($r('sys.symbol.rectangle_3_group'))
                      .fontSize($r('sys.float.Title_M'))
                      .fontColor([$r('sys.color.icon_secondary')])
                    Text('默认视图方式')
                      .fontSize($r('sys.float.Subtitle_M'))
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('sys.color.font_primary'))
                      .margin({ left: $r('sys.float.padding_level8') })
                    Blank()
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
                      this.pageContext.openPage({ routerName: PageEnum.DARK_MODE_SETTING })
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
            .margin({bottom: 12})
            .height(undefined)
            .width('100%')
            .edgeEffect(EdgeEffect.Spring)


            List({ space: 0 }) {
              ListItemGroup() {
                ListItem({ style: ListItemStyle.CARD }) {
                  CardItem({
                    isShow: true,
                    textContent: '关于轻Markdown',
                    symbolSrc: $r('sys.symbol.info_circle'),
                    onclick: () => {
                      this.pageContext.openPage({ routerName: PageEnum.ABOUT_PAGE });
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
                      this.pageContext.openPage({ routerName: PageEnum.GUIDE_PAGE });
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
                      this.pageContext.openPage({ routerName: PageEnum.FEEDBACK_PAGE });
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

            Blank().height(56 + this.safeBottom + 8)
          }
          .width('100%')
          .constraintSize({ minHeight: '100%' })
          .padding(new BreakpointType<Padding>({
            sm: { left: 16, right: 16 },
            md: { left: 24, right: 24 },
            lg: { left: 32, right: 32 },
          }).getValue(this.globalInfoModel.widthBreakpoint))
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
    .bindSheet($$this.isShowAccountInfo, this.AccountSheetBuilder, {
      height: 200,
      dragBar: true,
    })
    .bindSheet($$this.showConfirmLoginDialog, this.ConfirmLoginSheetBuilder, {
      height: 280,
      preferType: SheetType.CENTER,
      enableOutsideInteractive: false,
    })
  }

  @Builder
  AccountSheetBuilder() {
    Column() {
      // 头像
      if (this.avatarUrl) {
        Image(this.avatarUrl)
          .draggable(false)
          .width(64)
          .height(64)
          .borderRadius(32)
          .margin({ top: 20 })
      } else {
        Text(this.nickName.slice(-1))
          .width(64)
          .height(64)
          .borderRadius(32)
          .backgroundColor($r('sys.color.ohos_id_color_tertiary'))
          .linearGradient({
            colors: [
              [$r('sys.color.ohos_id_color_tertiary'), 0.0],
              [$r('sys.color.ohos_id_color_foreground_contrary'), 1.0],
            ],
          })
          .fontColor($r('sys.color.font_on_primary'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .margin({ top: 20 })
      }

      // 昵称
      Text(this.nickName)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .margin({ top: 12 })

      Blank()

      // 退出登录按钮
      Button('退出登录')
        .type(ButtonType.Capsule)
        .width('90%')
        .height(44)
        .backgroundColor('#E53935')
        .fontColor(Color.White)
        .margin({ bottom: 20 })
        .onClick(() => {
          AccountService.getInstance().logoutDirect();
          this.isShowAccountInfo = false;
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ConfirmLoginSheetBuilder() {
    Column() {
      Text('确认登录')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .margin({ top: 20 })

      // 头像
      if (this.tempAvatarUrl) {
        Image(this.tempAvatarUrl)
          .draggable(false)
          .width(64)
          .height(64)
          .borderRadius(32)
          .margin({ top: 16 })
      } else {
        Text(this.tempNickName.slice(-1))
          .width(64)
          .height(64)
          .borderRadius(32)
          .backgroundColor($r('sys.color.ohos_id_color_tertiary'))
          .linearGradient({
            colors: [
              [$r('sys.color.ohos_id_color_tertiary'), 0.0],
              [$r('sys.color.ohos_id_color_foreground_contrary'), 1.0],
            ],
          })
          .fontColor($r('sys.color.font_on_primary'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .margin({ top: 16 })
      }

      // 昵称
      Text(this.tempNickName)
        .fontSize(16)
        .fontColor($r('sys.color.font_primary'))
        .margin({ top: 12 })

      Blank()

      // 确认登录按钮
      Button('确认登录')
        .type(ButtonType.Capsule)
        .width('90%')
        .height(44)
        .backgroundColor($r('sys.color.brand'))
        .fontColor(Color.White)
        .margin({ bottom: 12 })
        .onClick(() => {
          this.handleConfirmLogin();
        })

      // 取消按钮
      Button('取消')
        .type(ButtonType.Capsule)
        .width('90%')
        .height(44)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .fontColor($r('sys.color.font_primary'))
        .margin({ bottom: 20 })
        .onClick(() => {
          this.showConfirmLoginDialog = false;
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}

@Builder
export function MineBuilder() {
  Mine()
}
