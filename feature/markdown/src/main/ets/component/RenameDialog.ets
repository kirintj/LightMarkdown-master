import { AnimUtil } from 'common';

@CustomDialog
@Component
export struct RenameDialog {
  initialName: string = '';
  @State inputText: string = '';
  controller: CustomDialogController = new CustomDialogController({builder: () => {}});
  onConfirm: (name: string) => void = () => {};

  aboutToAppear(): void {
    this.inputText = this.initialName;
  }

  build() {
    Column() {
      Text('重命名')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })
      TextInput({ text: this.inputText })
        .onChange((value: string) => { this.inputText = value; })
        .width('100%')
        .margin({ bottom: 16 })
      Row() {
        Button('取消')
          .type(ButtonType.Capsule)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
          .margin({ right: 8 })
          .onClick(() => { this.controller.close(); })
        Button('确认')
          .type(ButtonType.Capsule)
          .backgroundColor($r('sys.color.brand'))
          .fontColor(Color.White)
          .layoutWeight(1)
          .onClick(() => {
            this.onConfirm(this.inputText);
            this.controller.close();
          })
      }
      .width('100%')
    }
    .padding(16)
    .width('100%')
    .transition(AnimUtil.scaleFadeTransition())
  }
}
