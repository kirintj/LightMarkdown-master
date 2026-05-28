import { PageEnum } from '../model/PageEnum';

export interface RouterParam {
  routerName: PageEnum;
  param?: object;
}

export class PageContext {
  private readonly pathStack: NavPathStack;

  constructor() {
    this.pathStack = new NavPathStack();
  }

  public get navPathStack(): NavPathStack {
    return this.pathStack;
  }

  public openPage(data: RouterParam, animated: boolean = true): void {
    this.pathStack.pushPath({
      name: data.routerName,
      param: data.param,
    }, animated);
  }

  public replacePage(data: RouterParam, animated: boolean = true): void {
    this.pathStack.replacePath({
      name: data.routerName,
      param: data.param,
    }, animated);
  }

  public popPage(animated: boolean = true): void {
    this.pathStack.pop(animated);
  }

  public popToRoot(animated: boolean = true): void {
    this.pathStack.popToIndex(0, animated);
  }

  public clear(animated: boolean = true): void {
    this.pathStack.clear(animated);
  }
}
