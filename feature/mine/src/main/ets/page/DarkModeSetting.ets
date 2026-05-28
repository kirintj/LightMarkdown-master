import { common } from '@kit.AbilityKit';
import { setDarkColorMode, setLightColorMode, setAutoColorMode } from '../utils/ColorModeChangeFunctions';
import { hdsMaterial, HdsNavDestination, ScrollEffectType } from '@kit.UIDesignKit';
import { BreakpointType, GlobalInfoModel, StorageKey, PageContext } from 'common';

@Component
export struct DarkModeSetting {
  @StorageProp('enableDarkMode') enableDarkMode: boolean = false;
  @StorageProp('isFollowSystemSetting') isFollowSystemSetting: boolean = true;
  @StorageProp('currentColorMode') currentColorMode: number = 0;
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private pageContext: PageContext = AppStorage.get<PageContext>(StorageKey.HOME_PAGE_CONTEXT) ?? new PageContext();
  aboutToDisappear(): void {
    AppStorage.setOrCreate('enableDarkMode', this.enableDarkMode);
    AppStorage.setOrCreate('isFollowSystemSetting', this.isFollowSystemSetting);
  }
  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel: GlobalInfoModel =
    AppStorage.get<GlobalInfoModel>(StorageKey.GLOBAL_INFO) ?? new GlobalInfoModel();
  build() {
    HdsNavDestination() {
      Scroll(){
        Column() {
          Blank().width('100%').height(58 + this.safeTop)
          Text($r('app.string.follow_system_settings_switch_mode'))
            .fontColor($r('sys.color.tab_subtab_text_color'))
            .fontSize(14)
            .fontWeight(400)
            .lineHeight(20)
            .margin({ bottom: 16, top: 8 })
            .width('100%')
            .textAlign(TextAlign.Start)
          Row() {
            Text($r('app.string.follow_system_settings'))
              .fontSize(16)
              .fontWeight(500)
              .lineHeight(22)
              .padding({left:$r('sys.float.padding_level4')})
            Toggle({ type: ToggleType.Switch, isOn: this.isFollowSystemSetting })
              .onChange((isOn: boolean) => {
                if (isOn) {
                  this.isFollowSystemSetting = true;
                  this.enableDarkMode = false;
                  setAutoColorMode(this.context);
                } else {
                  this.isFollowSystemSetting = false;
                  if (this.enableDarkMode) {
                    setDarkColorMode(this.context);
                  } else {
                    setLightColorMode(this.context);
                  }
                }
              }).margin({right:$r('sys.float.padding_level4')})
          }
          .width('100%')
          .height(56)
          .margin({ bottom: 12 })
          .justifyContent(FlexAlign.SpaceBetween)
          .borderRadius(12)
          .padding($r('sys.float.padding_level2'))
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius($r('sys.float.corner_radius_level8'))

          Row() {
            Text($r('app.string.dark_mode'))
              .fontSize(16)
              .fontWeight(500)
              .lineHeight(22)
              .padding({left:$r('sys.float.padding_level4')})
            Toggle({ type: ToggleType.Switch, isOn: this.enableDarkMode })
              .onChange((isOn: boolean) => {
                this.enableDarkMode = isOn;
                if (isOn) {
                  this.isFollowSystemSetting = false;
                  setDarkColorMode(this.context);
                } else if (!this.isFollowSystemSetting) {
                  setLightColorMode(this.context);
                }
              })
              .margin({right:$r('sys.float.padding_level4')})
          }
          .width('100%')
          .height(56)
          .justifyContent(FlexAlign.SpaceBetween)
          .borderRadius(12)
          .padding($r('sys.float.padding_level2'))
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius($r('sys.float.corner_radius_level8'))
          Blank().height(this.safeBottom)
        }
        .padding(new BreakpointType<Padding>({
          sm: { left: 16, right: 16 },
          md: { left: 24, right: 24 },
          lg: { left: 32, right: 32 },
        }).getValue(this.globalInfoModel.widthBreakpoint))
        .constraintSize({ minHeight: '100%' })
      }
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')
    }
    
    .titleBar({
      content:{
        title: {
          mainTitle: '深色模式'
        },
      },
      style: {
        scrollEffectOpts: {
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        },
      },
      avoidLayoutSafeArea: true
    }
    )
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

@Builder
export function DarkModeSettingBuilder() {
  DarkModeSetting()
}