import { MarkdownFile } from '../class/MarkdownFile';
import { formatRelativeTime } from 'common';
import { hdsEffect } from '@kit.UIDesignKit';

@Component
export struct FileGridCard {
  file: MarkdownFile = new MarkdownFile('', '', '', 0);
  onTap: () => void = () => {};
  onStar: () => void = () => {};
  controller: hdsEffect.ShaderEffectController = new hdsEffect.ShaderEffectController();

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.doc_plaintext_fill'))
            .fontSize(20)
            .fontColor(this.file.isStar ? ['#FFC83D'] : [$r('sys.color.white')]);
          Text(this.file.groupName ? this.file.groupName : '')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.white'))
            .backgroundColor($r('sys.color.confirm'))
            .borderRadius(8)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .visibility(this.file.groupName ? Visibility.Visible : Visibility.Hidden);
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)

        Text(this.file.name)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.white'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.LEFT)
          .lineHeight(24)
          .margin({ top: 8 })

        Row() {
          Text(this.file.size)
            .fontSize(11)
            .fontColor('rgba(255,255,255,0.7)')
          if (formatRelativeTime(this.file.lastViewedAt)) {
            Text(' · ')
              .fontSize(11)
              .fontColor('rgba(255,255,255,0.5)')
            Text(formatRelativeTime(this.file.lastViewedAt))
              .fontSize(11)
              .fontColor('rgba(255,255,255,0.7)')
          }
        }
        .margin({ top: 4 })

        Row() {
          Blank()
          if (this.file.isStar) {
            SymbolGlyph($r('sys.symbol.star_fill'))
              .fontSize(14)
              .fontColor(['#FFC83D'])
              .onClick(() => { this.onStar(); });
          }
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .width('100%')
      .height(undefined)
      .padding({ left: 12, right: 12, top: 14, bottom: 12 })
      .alignItems(HorizontalAlign.Center)
    }
    .visualEffect(new hdsEffect.HdsEffectBuilder()
      .shaderEffect({
        effectType: hdsEffect.EffectType.UV_BACKGROUND_FLOW_LIGHT,
        animation: {
          duration: 10000,
          iterations: -1,
          autoPlay: true,
          curve: Curve.FastOutSlowIn,
          onFinish: () => {
            console.info('Succeeded in finishing');
          }
        },
        controller: this.controller
      })
      .buildEffect())
    .borderRadius(16)
    .width('100%')
    .onClick(() => { this.onTap(); })
  }
}
