import { HdsNavDestination, ScrollEffectType, hdsMaterial } from '@kit.UIDesignKit';
import { BreakpointType, GlobalInfoModel, StorageKey } from 'common';

@Component
export struct GuidePage {
  @StorageProp('safeTop') safeTop: number = 0;
  @StorageProp('safeBottom') safeBottom: number = 0;
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
  @Builder
  section(title: string, content: string) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .margin({ bottom: 8 })
      Text(content)
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
        .lineHeight(22)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .margin({bottom:8})
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column() {
          Blank().width('100%').height(58 + this.safeTop)

          this.section(
            '导入文件',
            '点击首页底部的「+」按钮，选择一个或多个 .md 文件导入。支持批量导入，最多 50 个文件。导入后文件会保存在应用沙箱内。'
          )

          this.section(
            '查看文件',
            '在首页列表中点击文件即可查看 Markdown 渲染效果。底部操作栏支持：加入分组、收藏/取消收藏、删除。'
          )

          this.section(
            '文件分组',
            '在文件详情页底部点击「分组」图标，可将文件归入已有分组或创建新分组。分组有助于整理大量文件。'
          )

          this.section(
            '收藏文件',
            '在文件详情页底部点击「收藏」图标，文件会被标记为收藏。在「速览」tab 可以快速查看所有收藏文件。'
          )

          this.section(
            '重命名',
            '在文件详情页标题栏菜单中点击「重命名」，输入新文件名后确认。文件名必须以 .md 结尾。'
          )

          this.section(
            '分享文件',
            '在文件详情页标题栏菜单中点击「分享」，可通过系统分享面板发送文件。支持碰一碰和隔空传送。'
          )

          this.section(
            '视图切换',
            '首页支持列表和网格两种视图模式。在「我的」tab 中可设置默认视图模式。'
          )

          this.section(
            '排序方式',
            '文件支持按名称、时间、分组排序。在「我的」tab 中可设置默认排序方式。'
          )

          Blank().height(this.safeBottom + 16)
        }
        .width('100%')
        .padding(new BreakpointType<Padding>({
          sm: { left: 16, right: 16 },
          md: { left: 24, right: 24 },
          lg: { left: 32, right: 32 },
        }).getValue(this.globalInfoModel.widthBreakpoint))
      }
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')
    }
    .titleBar({
      content: {
        title: { mainTitle: '使用指南' }
      },
      style: {
        scrollEffectOpts: { scrollEffectType: ScrollEffectType.GRADIENT_BLUR },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        }
      },
      avoidLayoutSafeArea: true
    })
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

@Builder
export function GuidePageBuilder() {
  GuidePage()
}
