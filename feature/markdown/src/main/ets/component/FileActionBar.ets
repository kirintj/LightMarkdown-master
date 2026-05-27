import { MarkdownFile } from '../class/MarkdownFile';

@Component
export struct FileActionBar {
  file: MarkdownFile = new MarkdownFile('', '', '', 0);
  onGroup: () => void = () => {};
  onStar: () => void = () => {};
  onDelete: () => void = () => {};

  @Builder
  actionButton(icon: Resource, label: string, color: ResourceColor, action: () => void) {
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
      this.actionButton(
        $r('sys.symbol.folder_fill'),
        this.file.groupId !== -1 ? this.file.groupName : '分组',
        this.file.groupId !== -1 ? $r('sys.color.confirm') : $r('sys.color.icon_primary'),
        () => { this.onGroup(); }
      )
      this.actionButton(
        $r('sys.symbol.star_fill'),
        this.file.isStar ? '取消收藏' : '收藏',
        this.file.isStar ? '#FFC83D' : $r('sys.color.icon_primary'),
        () => { this.onStar(); }
      )
      this.actionButton(
        $r('sys.symbol.trash_fill'),
        '删除',
        $r('sys.color.icon_primary'),
        () => { this.onDelete(); }
      )
    }
    .justifyContent(FlexAlign.Center)
    .width(180)
  }
}
