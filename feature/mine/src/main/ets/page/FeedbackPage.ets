import { HdsNavDestination, ScrollEffectType, hdsMaterial } from '@kit.UIDesignKit';
import { common, Want } from '@kit.AbilityKit';
import { BreakpointType, GlobalInfoModel, StorageKey } from 'common';

@Component
export struct FeedbackPage {
  @StorageProp('safeTop') safeTop: number = 0;
  @StorageProp('safeBottom') safeBottom: number = 0;
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  private async openEmail(): Promise<void> {
    try {
      const want: Want = {
        action: 'ohos.want.action.SENDTO',
        uri: 'mailto:feedback@example.com',
      };
      await this.context.startAbility(want);
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: '未找到邮件应用' });
    }
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column() {
          Blank().width('100%').height(58 + this.safeTop)

          Image($r('app.media.celi'))
            .width(64)
            .height(64)
            .margin({ top: 24, bottom: 16 })

          Text('感谢你的反馈')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))

          Text('你的意见将帮助我们持续改进')
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: 8, bottom: 32 })

          // 邮件反馈
          Column() {
            Row() {
              SymbolGlyph($r('sys.symbol.envelope_fill'))
                .fontSize(24)
                .fontColor([$r('sys.color.brand')])
              Text('邮件反馈')
                .fontSize($r('sys.float.Subtitle_M'))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_primary'))
                .margin({ left: $r('sys.float.padding_level8') })
              Blank()
              Text('2896651097@qq.com')
                .fontSize($r('sys.float.Title_S'))
                .fontColor($r('sys.color.icon_fourth'))
            }
            .width('100%')
            .height(64)
            .padding({ left: 16, right: 16 })
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius(16)
          }
          .width('100%')
          .margin({ bottom: 12 })

          // 常见问题
          Column() {
            Row() {
              SymbolGlyph($r('sys.symbol.questionmark_circle_fill'))
                .fontSize(24)
                .fontColor([$r('sys.color.confirm')])
              Text('常见问题')
                .fontSize($r('sys.float.Subtitle_M'))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_primary'))
                .margin({ left: $r('sys.float.padding_level8') })
            }
            .width('100%')
            .height(64)
            .padding({ left: 16, right: 16 })
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius(16)
            .onClick(() => {
              this.getUIContext().getPromptAction().showToast({ message: '敬请期待' });
            })
          }
          .width('100%')
          .margin({ bottom: 12 })
        }
        .width('100%')
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
    .titleBar({
      content: {
        title: { mainTitle: '意见反馈' }
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
export function FeedbackPageBuilder() {
  FeedbackPage()
}
