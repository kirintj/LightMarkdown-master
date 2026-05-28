import { AnimUtil, SpringCurve, AnimDuration, ScaleValue } from '../util/AnimationUtil';

@Component
export struct CardItem {
  @Prop isShow: boolean;
  textContent?: string;
  symbolSrc?: Resource;
  onclick: Function = () => {
  };
  @State animScale: number = 1;

  build() {
    Row() {
      SymbolGlyph(this.symbolSrc)
        .fontSize($r('sys.float.Title_M'))
        .fontColor([$r('sys.color.icon_secondary')])
      Text(this.textContent)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .margin({ left: $r('sys.float.padding_level8') })
      Blank()
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize($r('sys.float.Title_M'))
        .fontColor([$r('sys.color.icon_fourth')])
    }
    .width('100%')
    .height(56)
    .scale({ x: this.animScale, y: this.animScale })
    .animation({ duration: AnimDuration.MEDIUM, curve: SpringCurve.CARD })
    .onClick(() => {
      this.onclick();
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        AnimUtil.spring(this.getUIContext(), () => { this.animScale = ScaleValue.CARD_PRESS; });
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        AnimUtil.spring(this.getUIContext(), () => { this.animScale = 1; });
      }
    })
  }
}