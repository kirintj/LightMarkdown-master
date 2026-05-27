import { picker } from "@kit.CoreFileKit"
import { FileDataSource, MarkdownFile } from "../class/MarkdownFile";
import { common } from "@kit.AbilityKit";
import { fileIo as fs } from '@kit.CoreFileKit';
import { MdDbService } from '../service/MdDbService'


@Component
export struct EmptyView {
  @Consume('dataSource') dataSource: FileDataSource;
  @Consume('dataVersion') dataVersion: number;
  @StorageProp('safeBottom') safeBottom: number = 0;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  build() {
    Scroll() {
      Column(){
        Image($r('app.media.celi'))
          .width(50)
          .height(50)
          .margin({ bottom: 16})
        Text('欢迎使用轻Markdown')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Button('点击  [ \u002B ]  导入')
          .type(ButtonType.Capsule)
          .margin({ top: 16 })
          .backgroundColor(Color.Transparent)
          .fontColor('#0A59F7')
          .onClick(() => this.readPickerFile())
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')
      .padding({ bottom: 56 + this.safeBottom })
    }
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')

  }

  async readPickerFile() {
    try {
      let pickerOpt = new picker.DocumentSelectOptions();
      pickerOpt.maxSelectNumber = 50;
      pickerOpt.fileSuffixFilters = ['.md', 'application/markdown', 'text/markdown', 'text/x-markdown'];
      const documentViewPicker = new picker.DocumentViewPicker();
      const uris = await documentViewPicker.select(pickerOpt);
      if (!uris || uris.length === 0) return;
      const targetDir = this.context.filesDir + "/md_docs";
      if (!fs.accessSync(targetDir)) fs.mkdirSync(targetDir);
      const dbService = MdDbService.getInstance(this.context);
      const newFiles: MarkdownFile[] = [];
      for (let sourceUri of uris) {
        try {
          let srcFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY);
          if (!srcFile || !srcFile.name) {
            fs.closeSync(srcFile);
            continue;
          }
          const targetPath = `${targetDir}/${srcFile.name}`;
          let destFile = fs.openSync(targetPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
          fs.copyFileSync(srcFile.fd, destFile.fd);
          const stats = fs.statSync(targetPath);
          const mdFile = new MarkdownFile(srcFile.name, sourceUri, targetPath, stats.size, false, undefined, -1, '', 0, Date.now());
          this.dataSource.pushItem(mdFile);
          newFiles.push(mdFile);
          fs.closeSync(srcFile);
          fs.closeSync(destFile);
        } catch (err) {
          console.error("单个文件处理失败:", JSON.stringify(err));
        }
      }
      await dbService.insertFiles(newFiles);
      this.dataVersion++;
    } catch (err) {
      console.error("批量导入失败: " + JSON.stringify(err));
    }
  }
}