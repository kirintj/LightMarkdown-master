import { AnimUtil, SpringCurve, AnimDuration, ScaleValue } from 'common';

@Component
export struct CardItem{
  @Prop icon: Resource;
  @Prop content: string;
  @Prop str1 : string;
  @Prop str2 : string;
  @Prop bgcolor: Resource | string;
  @State animScale: number = 1;
  build() {
    Column(){
      Row(){
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .stroke(this.bgcolor)
            .fill(this.bgcolor)
            .width(24)
            .height(24);
          SymbolGlyph(this.icon)
            .fontSize(16)
            .fontColor([Color.White])
        }
        .padding({right:6})
        Text(this.content)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      Row(){
        Text(this.str1)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Text(this.str2)
          .fontSize(12)
          .fontColor(Color.Grey)

      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      //.alignItems(VerticalAlign.Bottom)
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(HorizontalAlign.Center)
    .padding(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .width('100%')
    .height(90)
    .borderRadius(16)
    .scale({ x: this.animScale, y: this.animScale })
    .animation({ duration: AnimDuration.MEDIUM, curve: SpringCurve.CARD })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        AnimUtil.spring(this.getUIContext(), () => { this.animScale = ScaleValue.CARD_PRESS; });
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        AnimUtil.spring(this.getUIContext(), () => { this.animScale = 1; });
      }
    })
  }
}