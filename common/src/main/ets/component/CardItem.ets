@Component
export struct CardItem {
  @Prop isShow: boolean;
  textContent?: string;
  symbolSrc?: Resource;
  onclick: Function = () => {
  };

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
    .onClick(() => {
      this.onclick();
    })
  }
}