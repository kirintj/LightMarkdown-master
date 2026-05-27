import { HdsNavDestination, ScrollEffectType, hdsMaterial } from '@kit.UIDesignKit';

@Component
export struct AboutPage {
  @StorageProp('safeTop') safeTop: number = 0;
  @StorageProp('safeBottom') safeBottom: number = 0;

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

          Text('v1.0.2')
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: 8 })

          Text('简洁高效的 Markdown 文件管理器')
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: 12 })

          Divider()
            .margin({ top: 24, bottom: 16 })

          Row() {
            Text('版本号')
              .fontSize(16)
              .fontColor($r('sys.color.font_primary'))
              .layoutWeight(1)
            Text('1.0.2')
              .fontSize(14)
              .fontColor($r('sys.color.font_secondary'))
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 16 })

          Row() {
            Text('检查更新')
              .fontSize(16)
              .fontColor($r('sys.color.font_primary'))
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_forward'))
              .fontSize(14)
              .fontColor([$r('sys.color.font_tertiary')])
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 16 })
          .onClick(() => {})

          Blank().height(this.safeBottom)
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 16, right: 16 })
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
