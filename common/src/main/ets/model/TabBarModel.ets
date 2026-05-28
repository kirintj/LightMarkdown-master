export enum TabBarType {
  HOME = 0,
  STAR = 1,
  MINE = 2,
}

export interface TabBarData {
  id: TabBarType;
  title: ResourceStr;
  icon: Resource;
}

export const TABS_LIST: TabBarData[] = [
  { id: TabBarType.HOME, icon: $r('sys.symbol.house_fill'), title: '首页' },
  { id: TabBarType.STAR, icon: $r('sys.symbol.discover_fill'), title: '速览' },
  { id: TabBarType.MINE, icon: $r('sys.symbol.person_crop_circle_fill_1'), title: '我的' },
];
