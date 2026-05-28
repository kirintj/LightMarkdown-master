import { AnimUtil } from '../util/AnimationUtil';

@Component
export struct EmptyState {
  icon: Resource = $r('sys.symbol.doc_plaintext_fill');
  text: string = '';

  build() {
    Column() {
      SymbolGlyph(this.icon)
        .fontSize(48)
        .fontColor([$r('sys.color.font_tertiary')])
      Text(this.text)
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ top: 80 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .transition(AnimUtil.fadeInTransition())
  }
}
