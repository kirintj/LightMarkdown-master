import { HdsNavigation } from '@kit.UIDesignKit';
import { DarkModeSetting, AboutPage, GuidePage, FeedbackPage } from 'mine';
import { MarkdownViewerPage, MarkdownFile, FileGroup, MultiSelectPage } from 'markdown';
import { StarredPage, GroupDetailPage, GroupListPage, RecentPage } from 'star';
import { PageContext, PageEnum, StorageKey } from 'common';
import { MainPage } from './MainPage';

@Entry
@Component
struct SplashPage {
  @StorageLink(StorageKey.HOME_PAGE_CONTEXT) pageContext: PageContext = new PageContext();

  aboutToAppear(): void {
    this.pageContext.replacePage({ routerName: PageEnum.MAIN_PAGE });
  }

  build() {
    HdsNavigation(this.pageContext.navPathStack) {
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.PageMap)
  }

  @Builder
  PageMap(name: string, param: object) {
    if (name === PageEnum.MAIN_PAGE) {
      MainPage()
    } else if (name === PageEnum.MARKDOWN_VIEWER) {
      MarkdownViewerPage({ fileData: param as MarkdownFile })
    } else if (name === PageEnum.STARRED_PAGE) {
      StarredPage()
    } else if (name === PageEnum.GROUP_DETAIL_PAGE) {
      GroupDetailPage({ groupData: param as FileGroup })
    } else if (name === PageEnum.GROUP_LIST_PAGE) {
      GroupListPage()
    } else if (name === PageEnum.RECENT_PAGE) {
      RecentPage()
    } else if (name === PageEnum.MULTI_SELECT_PAGE) {
      MultiSelectPage()
    } else if (name === PageEnum.DARK_MODE_SETTING) {
      DarkModeSetting()
    } else if (name === PageEnum.ABOUT_PAGE) {
      AboutPage()
    } else if (name === PageEnum.GUIDE_PAGE) {
      GuidePage()
    } else if (name === PageEnum.FEEDBACK_PAGE) {
      FeedbackPage()
    }
  }
}
