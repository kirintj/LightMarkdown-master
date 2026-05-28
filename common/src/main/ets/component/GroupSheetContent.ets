import { AnimUtil, SpringCurve, AnimDuration } from '../util/AnimationUtil';

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

  build() {
    Column() {
      Row() {
        TextInput({ placeholder: '创建新分组', text: this.newGroupName })
          .layoutWeight(1)
          .onChange((value: string) => { this.newGroupName = value; })
          .onSubmit(() => { this.onCreate(this.newGroupName); });
        Button('创建')
          .type(ButtonType.Capsule)
          .backgroundColor($r('sys.color.brand'))
          .fontColor(Color.White)
          .height(40)
          .margin({ left: 8 })
          .enabled(this.newGroupName.trim().length > 0)
          .onClick(() => { this.onCreate(this.newGroupName); });
      }
      .width('100%')
      .margin({ bottom: 12 });

      if (this.groups.length > 0) {
        List({ space: 8 }) {
          ForEach(this.groups, (group: GroupItem) => {
            ListItem() {
              Row() {
                SymbolGlyph($r('sys.symbol.arrow_right_folder_fill'))
                  .fontSize(24)
                  .fontColor([$r('sys.color.brand')]);
                Text(group.name)
                  .fontSize(16)
                  .fontColor($r('sys.color.font_primary'))
                  .margin({ left: 12 })
                  .layoutWeight(1);
                if (this.currentGroupId === group.id) {
                  SymbolGlyph($r('sys.symbol.checkmark_circle'))
                    .fontSize(24)
                    .fontColor([$r('sys.color.brand')]);
                }
              }
              .backgroundColor(this.currentGroupId === group.id
                ? $r('sys.color.comp_emphasize_secondary')
                : $r('sys.color.comp_background_primary'))
              .height(56)
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .borderRadius(16)
              .transition(AnimUtil.slideUpTransition())
              .onClick(() => { this.onAssign(group.id, group.name); });
            }
          }, (group: GroupItem) => group.id.toString());
        }
        .height(undefined)
        .width('100%')
      }

      if (this.currentGroupId !== -1) {
        Row() {
          SymbolGlyph($r('sys.symbol.clean_fill'))
            .fontSize(24)
            .fontColor([$r('sys.color.warning')]);
          Text('移出当前分组')
            .fontColor($r('sys.color.warning'))
            .margin({ left: 12 })
            .layoutWeight(1);
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .height(56)
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .borderRadius(16)
        .margin({ top: 12 })
        .onClick(() => { this.onRemove(); });
      }
    }
    .padding({ right: 16, left: 16 })
    .width('100%')
  }
}
