/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

@Observed
export class GlobalInfoModel {
  // 断点信息
  public widthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  public heightBreakpoint: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM;

  // 窗口尺寸 (vp)
  public deviceWidth: number = 0;
  public deviceHeight: number = 0;

  // 宽高比
  public aspectRatio: number = 0;

  // 系统安全区域
  public statusBarHeight: number = 0;    // 状态栏高度
  public naviIndicatorHeight: number = 0; // 导航栏高度
  public decorHeight: number = 0;         // 窗口装饰高度

  // 动态标题栏隐藏标志
  public needDynamicHideBar: boolean = false;

  // 折叠屏展开状态
  public foldExpanded: boolean = false;
}

// AppStorage 存储键
interface StorageKeyInterface {
  GLOBAL_INFO: string;
  UI_CONTEXT: string;
}

export const StorageKey: StorageKeyInterface = {
  GLOBAL_INFO: 'hmos_world_GlobalInfoModel',
  UI_CONTEXT: 'hmos_world_UIContext',
};
