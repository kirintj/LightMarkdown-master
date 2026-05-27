import { LengthMetrics, Prompt, SymbolGlyphModifier } from '@kit.ArkUI';

// 排序菜单
@Builder
export function SortMenu() {
  Menu(){
    MenuItem({
      symbolEndIcon: new SymbolGlyphModifier($r('sys.symbol.timer')),
      content: "按创建时间排序"
    })
    MenuItem({
      symbolEndIcon: new SymbolGlyphModifier($r('sys.symbol.rename')),
      content: "按文件名称排序"
    })
    MenuItem({
      symbolEndIcon: new SymbolGlyphModifier($r('sys.symbol.paperplane')),
      content: "按文件大小排序"
    })
  }.width(200).menuItemDivider({
    strokeWidth: LengthMetrics.px(1),
    color: $r('sys.color.comp_divider')
  })
}

// 顶部更多菜单
@Builder
export function CommonMenu() {
  Menu() {
    MenuItem({
      content: "回收站",
      symbolEndIcon: new SymbolGlyphModifier($r('sys.symbol.trash')),
    }).onClick(() => {
      Prompt.showToast({ message: '点击回收站' })
    })
    MenuItem({
      content: "多选",
      symbolEndIcon: new SymbolGlyphModifier($r('sys.symbol.checkmark_circle')),
    })
    MenuItem({
      content: "排序方式",
      symbolEndIcon: new SymbolGlyphModifier($r('sys.symbol.sort')),
    })
  }
  .width(200).menuItemDivider({
    strokeWidth: LengthMetrics.px(1),
    color: $r('sys.color.comp_divider')
  })
}