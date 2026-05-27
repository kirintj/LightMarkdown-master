import { HdsNavDestination, HdsNavDestinationTitleMode, HdsNavigationTitleMode,
  ScrollEffectType } from "@hms.hds.hdsBaseComponent";
import { hdsMaterial } from "@kit.UIDesignKit";

@Component
export struct BindSheetHDS{
  @Prop title: string = '';
  @Link showSheet: boolean;
  @BuilderParam content: () => void;



  build() {
    HdsNavDestination(){
      this.content
    }
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .hideBackButton(true)
    .backgroundColor($r('sys.color.background_secondary'))
    .hideTitleBar(false)
    .titleBar({
      style: {
        scrollEffectOpts: {
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        },
      },
      enableComponentSafeArea: true,
      content: {
        title: {
          mainTitle: this.title,
        },
        menu: {
          value: [{
            content: {
              icon: $r('sys.symbol.xmark'),
              action: () => {
                this.showSheet = false;
              },
            }
          }]
        },
      },

    })
  }
}