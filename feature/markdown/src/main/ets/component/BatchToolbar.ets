import { AnimUtil } from 'common';

@Component
export struct BatchToolbar {
  selectedCount: number = 0;
  onShare: () => void = () => {};
  onGroup: () => void = () => {};
  onStar: () => void = () => {};
  onDelete: () => void = () => {};

  @Builder
  actionButton(icon: Resource, label: string, color: string | Resource, action: () => void) {
    Column() {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([color])
      Text(label)
        .fontSize(9)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .onClick(() => { action(); })
  }

  build() {
    Row() {
      this.actionButton($r('sys.symbol.share'), '分享', '#3A7BFF', () => { this.onShare(); });
      this.actionButton($r('sys.symbol.folder'), '分组', '#36C972', () => { this.onGroup(); });
      this.actionButton($r('sys.symbol.star'), '收藏', '#FFC83D', () => { this.onStar(); });
      this.actionButton($r('sys.symbol.trash'), '删除', '#FF5A5F', () => { this.onDelete(); });
    }
    .justifyContent(FlexAlign.SpaceAround)
    .width('100%')
    .transition(AnimUtil.slideUpTransition())
  }
}
