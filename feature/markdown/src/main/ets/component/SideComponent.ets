import { hdsMaterial, HdsNavDestination,
  HdsNavDestinationTitleMode,
  HdsSideMenu, HdsSideMenuMainItem, ScrollEffectType } from '@kit.UIDesignKit';
import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';

@Component
export  struct SideComponent {
  @State isShowSidebar: boolean = true;
  @State selectedIndex: number = 1;
  @StorageProp('safeTop') safeTop: number = 0;
  listOptionsDefault?: HdsSideMenuMainItem[] = [
    new HdsSideMenuMainItem({
      symbol: new SymbolGlyphModifier($r('sys.symbol.doc_plaintext')),
      label: '全部备忘',
    }),
    new HdsSideMenuMainItem({
      symbol: new SymbolGlyphModifier($r('sys.symbol.star')),
      label: '收藏',
    }),
    new HdsSideMenuMainItem({
      symbol: new SymbolGlyphModifier($r('sys.symbol.lock')),
      label: '加锁',
    }),
    new HdsSideMenuMainItem({
      symbol: new SymbolGlyphModifier($r('sys.symbol.trash')),
      label: '最近删除',
    }),
    new HdsSideMenuMainItem({
      label: '文件夹',
    }),
  ]
  build() {
    HdsNavDestination(){
      Column() {
        HdsSideMenu({
          items: this.listOptionsDefault,
          selectedIndex: this.selectedIndex,
          $selectedIndex: (selectedIndex: number) => {
            this.selectedIndex = selectedIndex;
          },
        })
      }
      .width('100%')
      .height('100%')
      .padding(16)
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .titleBar({
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(0),
          blurEffectiveEndOffset: LengthMetrics.vp(20)
        },
        scrollEffectStyle: {
          backgroundStyle: { maskExtraHeight: 56.0 }
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        }
      },
      enableComponentSafeArea: true,
      content: {
        title: {
          mainTitle: '分组'
        },
        subIcon: {
          content: {
            label: 'headIcon',
            icon: this.isShowSidebar ? $r('sys.symbol.open_sidebar') : $r('sys.symbol.close_sidebar'),
            action: () =>{
              this.isShowSidebar = !this.isShowSidebar;
            }
          }
        },
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .hideBackButton(true)
    .hideTitleBar(false)
  }
}