import { AnimUtil, SpringCurve, AnimDuration, ScaleValue } from '../util/AnimationUtil';

@Component
export struct FileListCard {
  name: string = '';
  subtitle: string = '';
  isStar: boolean = false;
  groupId: number = -1;
  groupName: string = '';
  onTap: () => void = () => {};
  onStar: () => void = () => {};
  @State animScale: number = 1;

  build() {
    Row() {
      SymbolGlyph($r('sys.symbol.doc_plaintext_fill'))
        .fontSize($r('sys.float.Title_M'))
        .fontColor(['#FFC83D']);
      Column() {
        Text(this.name)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
        if (this.subtitle) {
          Text(this.subtitle)
            .fontSize($r('sys.float.Caption_S'))
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: 2 });
        }
        if (this.groupName) {
          Text(this.groupName)
            .fontSize($r('sys.float.Caption_S'))
            .fontColor($r('sys.color.confirm'))
            .margin({ top: 2 });
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: $r('sys.float.padding_level6') })
      .layoutWeight(1);
      Blank();
      SymbolGlyph(this.isStar ? $r('sys.symbol.star_fill') : $r('sys.symbol.star'))
        .fontSize(24)
        .fontColor([this.isStar ? '#FFC83D' : $r('sys.color.font_tertiary')])
        .onClick(() => { this.onStar(); });
    }
    .width('100%')
    .scale({ x: this.animScale, y: this.animScale })
    .animation({ duration: AnimDuration.MEDIUM, curve: SpringCurve.CARD })
    .onClick(() => { this.onTap(); })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        AnimUtil.spring(this.getUIContext(), () => { this.animScale = ScaleValue.CARD_PRESS; });
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        AnimUtil.spring(this.getUIContext(), () => { this.animScale = 1; });
      }
    });
  }
}
