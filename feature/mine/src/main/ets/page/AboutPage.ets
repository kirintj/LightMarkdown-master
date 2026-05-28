import { HdsNavDestination, ScrollEffectType, hdsMaterial } from '@kit.UIDesignKit';
import { BreakpointType, GlobalInfoModel, StorageKey, UpdateService,
  AnimUtil, SpringCurve, AnimDuration, ScaleValue } from 'common';
import { bundleManager } from '@kit.AbilityKit';

@Component
export struct AboutPage {
  @StorageProp('safeTop') safeTop: number = 0;
  @StorageProp('safeBottom') safeBottom: number = 0;
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
  @State currentVersion: string = '';
  @State laterVersionExist: boolean = false;
  @State isLoadingUpdate: boolean = false;
  @State animScaleVersion: number = 1;
  @State animScaleUpdate: number = 1;

  async aboutToAppear(): Promise<void> {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      this.currentVersion = bundleInfo.versionName;
    } catch (e) {
      console.error('[AboutPage] getBundleInfoForSelf failed:', JSON.stringify(e));
    }
    this.checkVersion();
  }

  private checkVersion(): void {
    UpdateService.getInstance().checkUpdate()
      .then((hasUpdate: boolean) => {
        this.laterVersionExist = hasUpdate;
      })
      .catch(() => {});
  }

  private handleUpdate(): void {
    if (!this.laterVersionExist) return;
    this.isLoadingUpdate = true;
    UpdateService.getInstance().updateVersion()
      .then(() => {
        this.isLoadingUpdate = false;
      })
      .catch(() => {
        this.isLoadingUpdate = false;
      });
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column() {
          Blank().width('100%').height(58 + this.safeTop)

          Image($r('app.media.app_icon'))
            .width(72)
            .height(72)
            .margin({ bottom: 16 })

          Text('轻Markdown')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))

          Text(this.currentVersion ? `v${this.currentVersion}` : '')
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: 8 })

          Text('简洁高效的 Markdown 文件管理器')
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: 12,bottom:24 })



          List({ space: 0 }) {
            ListItemGroup() {
              ListItem({ style: ListItemStyle.CARD }) {
                Row() {
                  SymbolGlyph($r('sys.symbol.info_circle'))
                    .fontSize($r('sys.float.Title_M'))
                    .fontColor([$r('sys.color.icon_secondary')])
                  Text('版本号')
                    .fontSize($r('sys.float.Subtitle_M'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('sys.color.font_primary'))
                    .margin({ left: $r('sys.float.padding_level8') })
                  Blank()
                  Text(this.currentVersion)
                    .fontSize($r('sys.float.Subtitle_S'))
                    .fontColor($r('sys.color.font_secondary'))
                }
                .width('100%')
                .height(56)
              }
              .height(undefined)
              .width('100%')

              ListItem({ style: ListItemStyle.CARD }) {
                Row() {
                  SymbolGlyph($r('sys.symbol.checkmark_lightbulb_max'))
                    .fontSize($r('sys.float.Title_M'))
                    .fontColor([$r('sys.color.icon_secondary')])
                  Text('检查更新')
                    .fontSize($r('sys.float.Subtitle_M'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('sys.color.font_primary'))
                    .margin({ left: $r('sys.float.padding_level8') })
                  Blank()
                  if (this.isLoadingUpdate) {
                    LoadingProgress()
                      .width(20)
                      .height(20)
                  } else if (this.laterVersionExist) {
                    Stack() {
                      Text('待更新')
                        .fontSize($r('sys.float.Subtitle_S'))
                        .fontColor($r('sys.color.font_secondary'))
                      Circle()
                        .width(6)
                        .height(6)
                        .fill($r('sys.color.ohos_id_color_badge_red'))
                        .offset({ x: 4, y: -8 })
                    }
                  } else {
                    Text('已是最新版本')
                      .fontSize($r('sys.float.Subtitle_S'))
                      .fontColor($r('sys.color.font_secondary'))
                  }
                }
                .width('100%')
                .height(56)
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
          .margin({ bottom: 12 })
          .height(undefined)
          .width('100%')
          .edgeEffect(EdgeEffect.Spring)

          Blank().height(this.safeBottom)
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .alignItems(HorizontalAlign.Center)
        .padding(new BreakpointType<Padding>({
          sm: { left: 16, right: 16 },
          md: { left: 24, right: 24 },
          lg: { left: 32, right: 32 },
        }).getValue(this.globalInfoModel.widthBreakpoint))
      }
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')
    }
    .titleBar({   content: {
        title: { mainTitle: '关于' }
      },
      style: {
        scrollEffectOpts: { scrollEffectType: ScrollEffectType.GRADIENT_BLUR },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        }
      },
      avoidLayoutSafeArea: true
    })
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

@Builder
export function AboutPageBuilder() {
  AboutPage();
}
