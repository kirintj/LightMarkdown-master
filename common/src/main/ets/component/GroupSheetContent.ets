export interface GroupItem {
  id: number;
  name: string;
}

@Component
export struct GroupSheetContent {
  currentGroupId: number = -1;
  groups: GroupItem[] = [];
  @State newGroupName: string = '';
  onAssign: (id: number, name: string) => void = () => {};
  onRemove: () => void = () => {};
  onCreate: (name: string) => void = () => {};

  @Builder
  groupItem(group: GroupItem) {
    Row() {
      SymbolGlyph($r('sys.symbol.arrow_right_folder_fill'))
        .fontSize(20)
        .fontColor([this.currentGroupId === group.id ? $r('sys.color.brand') : $r('sys.color.icon_secondary')]);
      Text(group.name)
        .fontSize(15)
        .fontWeight(this.currentGroupId === group.id ? FontWeight.Medium : FontWeight.Normal)
        .fontColor($r('sys.color.font_primary'))
        .margin({ left: 12 })
        .layoutWeight(1);
      if (this.currentGroupId === group.id) {
        SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
          .fontSize(20)
          .fontColor([$r('sys.color.brand')]);
      }
    }
    .height(52)
    .width('100%')
    .padding({ left: 16, right: 16 })
    .borderRadius(12)
    .backgroundColor(this.currentGroupId === group.id
      ? $r('sys.color.comp_emphasize_secondary')
      : Color.Transparent)
    .onClick(() => { this.onAssign(group.id, group.name); });
  }

  build() {
    Column() {
      // 创建新分组
      Text('新建分组')
        .fontSize(13)
        .fontColor($r('sys.color.font_secondary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        TextInput({ placeholder: '输入分组名称', text: this.newGroupName })
          .layoutWeight(1)
          .height(40)
          .onChange((value: string) => { this.newGroupName = value; })
          .onSubmit(() => { this.onCreate(this.newGroupName); });
        Button('创建')
          .type(ButtonType.Capsule)
          .backgroundColor($r('sys.color.brand'))
          .fontColor(Color.White)
          .height(40)
          .margin({ left: 8 })
          .enabled(this.newGroupName.trim().length > 0)
          .opacity(this.newGroupName.trim().length > 0 ? 1 : 0.5)
          .onClick(() => { this.onCreate(this.newGroupName); });
      }
      .width('100%')
      .margin({ bottom: 16 });

      // 分隔线
      Divider()
        .color($r('sys.color.comp_divider'))
        .margin({ bottom: 16 });

      // 已有分组
      if (this.groups.length > 0) {
        Text('选择分组')
          .fontSize(13)
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ bottom: 8 })

        List({ space: 2 }) {
          ForEach(this.groups, (group: GroupItem) => {
            ListItem() {
              this.groupItem(group)
            }
          }, (group: GroupItem) => group.id.toString());
        }
        .width('100%')
        .height(undefined)
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.folder'))
            .fontSize(32)
            .fontColor([$r('sys.color.font_tertiary')])
          Text('暂无分组')
            .fontSize(14)
            .fontColor($r('sys.color.font_tertiary'))
            .margin({ top: 8 })
        }
        .width('100%')
        .padding({ top: 24, bottom: 24 })
      }

      // 移出分组
      if (this.currentGroupId !== -1) {
        Divider()
          .color($r('sys.color.comp_divider'))
          .margin({ top: 16, bottom: 16 })

        Row() {
          SymbolGlyph($r('sys.symbol.xmark_circle'))
            .fontSize(20)
            .fontColor([$r('sys.color.warning')]);
          Text('移出当前分组')
            .fontSize(15)
            .fontColor($r('sys.color.warning'))
            .margin({ left: 12 })
            .layoutWeight(1);
        }
        .height(52)
        .width('100%')
        .padding({ left: 16, right: 16 })
        .borderRadius(12)
        .onClick(() => { this.onRemove(); });
      }
    }
    .padding({ left: 20, right: 20, top: 16, bottom: 32 })
    .width('100%')
  }
}
