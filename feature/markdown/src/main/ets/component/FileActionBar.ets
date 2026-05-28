@Component
export struct FileActionBar {
  @Prop isStar: boolean = false;
  @Prop groupId: number = -1;
  @Prop groupName: string = '';
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
        this.groupId !== -1 ? this.groupName : '分组',
        this.groupId !== -1 ? $r('sys.color.confirm') : $r('sys.color.icon_primary'),
        () => { this.onGroup(); }
      )
      this.actionButton(
        $r('sys.symbol.star_fill'),
        this.isStar ? '取消收藏' : '收藏',
        this.isStar ? '#FFC83D' : $r('sys.color.icon_primary'),
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
