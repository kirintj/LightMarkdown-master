# HarmonyOS 华为账号登录技术指南

## 概述

本指南介绍 HarmonyOS 应用中华为账号登录的完整实现方案，包括账号授权、状态监听、持久化存储、UI 交互等。

---

## 架构设计

```
┌─────────────────────────────────────────────────────────────────┐
│  UI 层 (MineView / AccountSheetView)                           │
│  ├─ 登录按钮 → 触发登录                                         │
│  ├─ 登出按钮 → 触发登出                                         │
│  └─ 显示用户头像/昵称                                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  ViewModel 层 (MinePageVM)                                      │
│  ├─ login() - 调用 AccountService.login()                       │
│  ├─ logout() - 调用 AccountService.logout()                     │
│  └─ updateAccountData() - 更新 UI 状态                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Service 层 (AccountService)                                    │
│  ├─ login() - 发起华为账号授权                                   │
│  ├─ logout() - 登出                                              │
│  ├─ init() - 初始化，检查登录状态                                │
│  └─ subscribeAccountLoginState() - 监听账号状态变化              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  系统层 (@kit.AccountKit / @kit.BasicServicesKit)              │
│  ├─ authentication - 华为账号认证                                │
│  ├─ commonEventManager - 公共事件监听                            │
│  └─ emitter - 应用内事件总线                                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 核心模块

### 1. UserAccount 用户模型

```typescript
// common/src/main/ets/accountservice/model/UserAccount.ets

export class UserAccount {
  public unionId: string = '';      // 用户唯一标识
  public nickname: string = '';     // 昵称
  public avatarUrl: string = '';    // 头像 URL
}
```

---

### 2. AccountService 账号服务

```typescript
// common/src/main/ets/accountservice/AccountService.ets

import { authentication } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { commonEventManager, emitter } from '@kit.BasicServicesKit';
import type { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = '[AccountService]';
const USER_LOGIN = 'userLogin';
const USER_ACCOUNT = 'userAccount';

export class AccountService {
  private static instance: AccountService;
  private preferenceManager: PreferenceManager = PreferenceManager.getInstance();
  private userAccount: UserAccount = new UserAccount();
  private phoneLogin: boolean = false;
  public userLogin: boolean = false;
  private loginCallbacks: ((userAccount: UserAccount) => void)[] = [];
  private logoutCallbacks: ((userAccount: UserAccount) => void)[] = [];

  private constructor() {}

  public static getInstance(): AccountService {
    if (!AccountService.instance) {
      AccountService.instance = new AccountService();
    }
    return AccountService.instance;
  }

  // ========== 初始化 ==========

  public init() {
    // 从持久化存储恢复登录状态
    this.userLogin = this.preferenceManager.getValue(USER_LOGIN) as boolean ?? false;
    this.userAccount = this.preferenceManager.getValue(USER_ACCOUNT) as UserAccount ?? new UserAccount();

    // 检查华为账号授权状态
    const loginStateRequest: authentication.StateRequest = {
      idType: authentication.IdType.UNION_ID,
      idValue: this.userAccount.unionId,
    };

    new authentication.HuaweiIDProvider().getHuaweiIDState(loginStateRequest)
      .then((result: authentication.StateResult) => {
        if (result.state !== authentication.State.AUTHORIZED) {
          this.userLogin = false;
        }
        this.phoneLogin =
          (result.state === authentication.State.AUTHORIZED ||
           result.state === authentication.State.UNAUTHORIZED);
        this.updatePreference(this.userLogin, this.userAccount);
      })
      .catch((error: BusinessError) => {
        Logger.error(TAG, `Get HuaweiID state failed: ${error.code} ${error.message}`);
      });

    // 订阅账号状态变化
    this.subscribeAccountLoginState();
  }

  // ========== 登录 ==========

  public login(uiContext: UIContext): Promise<UserAccount> {
    return new Promise((resolve, reject) => {
      this.getAuthCredential(uiContext)
        .then((authCredential: authentication.AuthorizationWithHuaweiIDCredential) => {
          this.userAccount.avatarUrl = authCredential.avatarUri ?? '';
          this.userAccount.nickname = authCredential.nickName ?? '';
          this.userAccount.unionId = authCredential.unionID ?? '';
          resolve(this.userAccount);
        })
        .catch((error: BusinessError) => {
          Logger.error(TAG, `Login failed: ${error.code} ${error.message}`);
          reject(error);
        });
    });
  }

  private getAuthCredential(uiContext: UIContext): Promise<authentication.AuthorizationWithHuaweiIDCredential> {
    // 创建授权请求
    const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
    authRequest.scopes = ['profile'];                    // 请求用户资料
    authRequest.permissions = ['serviceauthcode'];       // 请求服务授权码
    authRequest.forceAuthorization = true;               // 强制授权（每次弹出授权页）
    authRequest.state = util.generateRandomUUID();       // 防 CSRF 攻击
    authRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256;

    // 创建认证控制器
    const controller = new authentication.AuthenticationController(uiContext.getHostContext());

    return new Promise((resolve, reject) => {
      controller.executeRequest(authRequest)
        .then((result) => {
          const response = result as authentication.AuthorizationWithHuaweiIDResponse;

          // 验证 state 防止 CSRF
          if (response.state !== undefined && authRequest.state !== response.state) {
            reject(new Error('State mismatch, possible CSRF attack'));
            return;
          }

          const credential = response.data;
          if (!credential) {
            reject(new Error('Authorization credential is missing'));
            return;
          }

          resolve(credential);
        })
        .catch((error: BusinessError) => {
          reject(error);
        });
    });
  }

  // ========== 登出 ==========

  public logout(uiContext: UIContext): Promise<boolean> {
    return new Promise((resolve) => {
      resolve(true);
    });
  }

  public logoutDirect(): Promise<boolean> {
    return new Promise((resolve) => {
      this.userLogin = false;
      emitter.emit(CommonConstants.BIND_LOGOUT_EVENT);
      this.finishLogin();
      resolve(true);
    });
  }

  // ========== 确认登录 ==========

  public selectHuaweiAccountToLogin() {
    this.userLogin = true;
    this.updatePreference(this.userLogin, this.userAccount);
    emitter.emit(CommonConstants.BIND_MINE_LOGIN_EVENT);
  }

  // ========== 获取用户信息 ==========

  public getUserInfo(): UserAccount | undefined {
    if (this.userLogin) {
      return this.userAccount;
    }
    return undefined;
  }

  // ========== 事件监听 ==========

  public addAppLoginListener(loginCallback: (userAccount: UserAccount) => void) {
    this.loginCallbacks.push(loginCallback);
  }

  public addAppLogoutListener(logoutCallback: () => void) {
    this.logoutCallbacks.push(logoutCallback);
  }

  // ========== 内部方法 ==========

  private subscribeAccountLoginState() {
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN,
        commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT,
      ],
    };

    commonEventManager.createSubscriber(subscribeInfo)
      .then((subscriber) => {
        commonEventManager.subscribe(subscriber, (error, data) => {
          if (error) {
            Logger.error(TAG, `Subscribe failed: ${error.code} ${error.message}`);
            return;
          }

          if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN) {
            this.phoneLogin = true;
          }

          if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT) {
            this.userLogin = false;
            this.phoneLogin = false;
            this.finishLogin();
            emitter.emit(CommonConstants.BIND_LOGOUT_EVENT);
          }
        });
      })
      .catch((err) => {
        Logger.error(TAG, `Create subscriber failed: ${err.code} ${err.message}`);
      });
  }

  private finishLogin() {
    this.updatePreference(this.userLogin, this.userAccount);
    if (this.userLogin) {
      this.loginCallbacks.forEach(callback => callback(this.userAccount));
    } else {
      this.logoutCallbacks.forEach(callback => callback(this.userAccount));
    }
  }

  private updatePreference(userLogin: boolean, userAccount?: UserAccount) {
    this.preferenceManager.setValue(USER_LOGIN, userLogin);
    this.preferenceManager.setValue(USER_ACCOUNT, userAccount);
  }
}
```

---

### 3. AccountSheetView 登录弹窗 UI

```typescript
// common/src/main/ets/accountservice/component/AccountSheetView.ets

import { AlertDialog } from '@kit.ArkUI';

@Builder
export function LoginSheetViewBuilder(userAccount: UserAccount) {
  AccountSheetView({ userAccount })
}

@Component
struct AccountSheetView {
  @Prop @Require userAccount: UserAccount;
  @StorageProp(StorageKey.GLOBAL_INFO) globalInfoModel?: GlobalInfoModel;

  // 登出确认弹窗
  dialogControllerConfirm: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.exit_dialog_title'),
      content: $r('app.string.exit_dialog_content'),
      primaryButton: {
        value: $r('app.string.exit_dialog_cancel'),
        action: () => {
          this.dialogControllerConfirm.close();
        },
      },
      secondaryButton: {
        value: $r('app.string.exit_dialog_exit'),
        role: ButtonRole.ERROR,
        action: () => {
          AccountService.getInstance().logoutDirect();
        },
      },
    }),
  });

  build() {
    Row() {
      Column() {
        Column() {
          // 用户图标
          SymbolGlyph($r('sys.symbol.person_crop_circle_fill_1'))
            .fontSize($r('sys.float.Display_L'))
            .fontColor([$r('sys.color.icon_emphasize')])
            .aspectRatio(1)

          // 标题
          Text(!AccountService.getInstance().userLogin
            ? $r('app.string.select_account_title')
            : $r('app.string.current_account'))
            .fontSize($r('sys.float.Title_M'))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))

          // 头像
          if (this.userAccount.avatarUrl !== '') {
            Image(this.userAccount.avatarUrl)
              .draggable(false)
              .width(64)
              .aspectRatio(1)
              .borderRadius(32)
          } else {
            // 昵称首字作为头像
            Text(this.userAccount.nickname.slice(-1))
              .width(64)
              .aspectRatio(1)
              .borderRadius(32)
              .backgroundColor($r('sys.color.ohos_id_color_tertiary'))
              .linearGradient({
                colors: [
                  [$r('sys.color.ohos_id_color_tertiary'), 0.0],
                  [$r('sys.color.ohos_id_color_foreground_contrary'), 1.0],
                ],
              })
              .fontColor($r('sys.color.font_on_primary'))
              .fontSize($r('sys.float.Title_M'))
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
          }

          // 昵称
          Text(this.userAccount.nickname)
            .fontSize($r('sys.float.Body_L'))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
        }

        Blank();

        // 登录/登出按钮
        Button(!AccountService.getInstance().userLogin
          ? $r('app.string.select_account_to_log_in')
          : $r('app.string.log_out'))
          .type(ButtonType.Capsule)
          .fontSize($r('sys.float.Body_L'))
          .role(!AccountService.getInstance().userLogin ? ButtonRole.NORMAL : ButtonRole.ERROR)
          .buttonStyle(!AccountService.getInstance().userLogin
            ? ButtonStyleMode.EMPHASIZED
            : ButtonStyleMode.NORMAL)
          .width('100%')
          .onClick(() => {
            if (!AccountService.getInstance().userLogin) {
              AccountService.getInstance().selectHuaweiAccountToLogin();
            } else {
              this.dialogControllerConfirm.open();
            }
          })
      }
      .padding(16)
      .width('100%')
      .height('100%')
    }
  }
}
```

---

### 4. 事件常量定义

```typescript
// common/src/main/ets/constant/CommonConstants.ets

export class CommonConstants {
  // 账号相关事件
  public static readonly BIND_LOGOUT_EVENT: string = 'BindLogoutEvent';
  public static readonly BIND_MINE_LOGIN_EVENT: string = 'BindMineLoginEvent';
  public static readonly BIND_SHEET_CLOSE_EVENT: string = 'BindSheetCloseEvent';
}
```

---

## 集成步骤

### 步骤 1: 创建核心文件

```
common/src/main/ets/
├── accountservice/
│   ├── AccountService.ets           # 账号服务
│   ├── model/
│   │   └── UserAccount.ets          # 用户模型
│   ├── component/
│   │   └── AccountSheetView.ets     # 登录弹窗 UI
│   └── constant/
│       └── AccountServiceConstants.ets
└── constant/
    └── CommonConstants.ets          # 事件常量
```

### 步骤 2: 配置 module.json5

```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_WIFI_INFO"
      }
    ]
  }
}
```

### 步骤 3: 初始化 (EntryAbility)

```typescript
export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 初始化 UIContext
    const uiContext = windowStage.getMainWindowSync().getUIContext();
    AppStorage.setOrCreate<UIContext>(StorageKey.UI_CONTEXT, uiContext);

    // 初始化账号服务
    AccountService.getInstance().init();
  }
}
```

### 步骤 4: 在页面中使用

```typescript
@Component
struct MineView {
  @State isLogin: boolean = false;
  @State avatarUrl: string = '';
  @State nickName: string = '';

  aboutToAppear() {
    // 监听登录事件
    emitter.on(CommonConstants.BIND_MINE_LOGIN_EVENT, () => {
      this.updateAccountData();
    });

    // 监听登出事件
    emitter.on(CommonConstants.BIND_LOGOUT_EVENT, () => {
      this.updateAccountData();
    });

    // 初始化账号状态
    this.updateAccountData();
  }

  updateAccountData() {
    const userInfo = AccountService.getInstance().getUserInfo();
    if (userInfo) {
      this.isLogin = true;
      this.avatarUrl = userInfo.avatarUrl;
      this.nickName = userInfo.nickname;
    } else {
      this.isLogin = false;
      this.avatarUrl = '';
      this.nickName = '';
    }
  }

  handleLogin() {
    const uiContext = AppStorage.get<UIContext>(StorageKey.UI_CONTEXT);
    if (!uiContext) return;

    AccountService.getInstance().login(uiContext)
      .then((userAccount) => {
        this.avatarUrl = userAccount.avatarUrl;
        this.nickName = userAccount.nickname;
        // 显示账号确认弹窗
        this.showAccountSheet = true;
      })
      .catch((error) => {
        Toast.showToast('登录失败');
      });
  }

  handleLogout() {
    AccountService.getInstance().logoutDirect();
  }

  build() {
    Column() {
      // 用户头像区域
      Row() {
        if (this.isLogin) {
          if (this.avatarUrl) {
            Image(this.avatarUrl)
              .width(48)
              .height(48)
              .borderRadius(24)
          } else {
            Text(this.nickName.slice(-1))
              .width(48)
              .height(48)
              .borderRadius(24)
              .backgroundColor('#1890ff')
              .fontColor(Color.White)
              .fontSize(20)
              .textAlign(TextAlign.Center)
          }
          Text(this.nickName)
            .fontSize(16)
            .margin({ left: 12 })
        } else {
          SymbolGlyph($r('sys.symbol.person_crop_circle_fill_1'))
            .fontSize(48)
            .fontColor([$r('sys.color.icon_fourth')])
          Text('未登录')
            .fontSize(16)
            .margin({ left: 12 })
        }
      }
      .onClick(() => {
        if (!this.isLogin) {
          this.handleLogin();
        } else {
          this.showAccountSheet = true;
        }
      })
    }
  }
}
```

---

## 登录流程

```
1. 用户点击登录按钮
      ↓
2. 调用 AccountService.login(uiContext)
      ↓
3. 创建 AuthorizationWithHuaweiIDRequest
   - scopes: ['profile']         // 请求用户资料
   - permissions: ['serviceauthcode']  // 请求服务授权码
   - forceAuthorization: true    // 强制弹出授权页
   - state: UUID                 // 防 CSRF
      ↓
4. 调用 AuthenticationController.executeRequest()
      ↓
5. 系统弹出华为账号授权页面
      ↓
6. 用户点击"允许"授权
      ↓
7. 返回 AuthorizationWithHuaweiIDCredential
   - avatarUri (头像)
   - nickName (昵称)
   - unionID (用户唯一标识)
      ↓
8. 保存到 UserAccount 模型
      ↓
9. 持久化到 PreferenceManager
      ↓
10. 触发 loginCallbacks，更新 UI
```

---

## 状态监听

### 系统账号状态监听

```typescript
// 监听华为账号登录/登出广播
subscribeAccountLoginState() {
  const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: [
      commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN,
      commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT,
    ],
  };

  commonEventManager.createSubscriber(subscribeInfo)
    .then((subscriber) => {
      commonEventManager.subscribe(subscriber, (error, data) => {
        if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN) {
          // 手机端华为账号登录
          this.phoneLogin = true;
        }
        if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT) {
          // 手机端华为账号登出
          this.userLogin = false;
          this.phoneLogin = false;
          emitter.emit(CommonConstants.BIND_LOGOUT_EVENT);
        }
      });
    });
}
```

### 应用内事件监听

```typescript
// 监听登录事件
emitter.on(CommonConstants.BIND_MINE_LOGIN_EVENT, () => {
  this.updateAccountData();
});

// 监听登出事件
emitter.on(CommonConstants.BIND_LOGOUT_EVENT, () => {
  this.updateAccountData();
});
```

---

## API 参考

### @kit.AccountKit

| API | 说明 |
|-----|------|
| `authentication.HuaweiIDProvider()` | 创建华为账号 Provider |
| `createAuthorizationWithHuaweiIDRequest()` | 创建授权请求 |
| `getHuaweiIDState()` | 查询账号授权状态 |
| `AuthenticationController(uiContext)` | 创建认证控制器 |
| `controller.executeRequest()` | 执行授权请求 |

### authentication.State

| 状态 | 说明 |
|------|------|
| `AUTHORIZED` | 已授权 |
| `UNAUTHORIZED` | 未授权（已登录华为账号） |
| `NOT_EXIST` | 未登录华为账号 |

### AuthorizationWithHuaweiIDCredential

| 字段 | 类型 | 说明 |
|------|------|------|
| `avatarUri` | `string` | 用户头像 URL |
| `nickName` | `string` | 用户昵称 |
| `unionID` | `string` | 用户唯一标识 |
| `idToken` | `string` | ID Token (JWT) |
| `authorizationCode` | `string` | 服务授权码 |

---

## 常见问题

### Q1: 如何判断用户是否已登录？

```typescript
const isLoggedIn = AccountService.getInstance().userLogin;

// 或者获取用户信息
const userInfo = AccountService.getInstance().getUserInfo();
if (userInfo) {
  // 已登录
} else {
  // 未登录
}
```

### Q2: 如何获取用户信息？

```typescript
const userInfo = AccountService.getInstance().getUserInfo();
if (userInfo) {
  console.info(`昵称: ${userInfo.nickname}`);
  console.info(`头像: ${userInfo.avatarUrl}`);
  console.info(`UnionID: ${userInfo.unionId}`);
}
```

### Q3: 如何监听登录状态变化？

```typescript
// 方式 1: 回调方式
AccountService.getInstance().addAppLoginListener((userAccount) => {
  console.info(`用户登录: ${userAccount.nickname}`);
});

AccountService.getInstance().addAppLogoutListener(() => {
  console.info('用户登出');
});

// 方式 2: 事件总线方式
emitter.on(CommonConstants.BIND_MINE_LOGIN_EVENT, () => {
  // 登录处理
});

emitter.on(CommonConstants.BIND_LOGOUT_EVENT, () => {
  // 登出处理
});
```

### Q4: 如何持久化登录状态？

登录状态会自动持久化到 PreferenceManager，下次启动时通过 `init()` 恢复。

```typescript
// 自动保存
this.preferenceManager.setValue(USER_LOGIN, userLogin);
this.preferenceManager.setValue(USER_ACCOUNT, userAccount);

// 自动恢复
this.userLogin = this.preferenceManager.getValue(USER_LOGIN) as boolean ?? false;
this.userAccount = this.preferenceManager.getValue(USER_ACCOUNT) as UserAccount ?? new UserAccount();
```

### Q5: 如何处理授权失败？

```typescript
AccountService.getInstance().login(uiContext)
  .then((userAccount) => {
    // 登录成功
  })
  .catch((error: BusinessError) => {
    if (error.code === 1001500001) {
      // 用户取消授权
      Toast.showToast('用户取消登录');
    } else if (error.code === 1001500002) {
      // 网络错误
      Toast.showToast('网络连接失败');
    } else {
      // 其他错误
      Toast.showToast('登录失败，请重试');
    }
  });
```

### Q6: 如何实现"确认登录"流程？

```typescript
// 1. 用户点击登录
login(uiContext).then((userAccount) => {
  // 2. 显示确认弹窗，展示用户信息
  this.showAccountSheet = true;
  this.tempUserAccount = userAccount;
});

// 3. 用户点击"确认登录"
confirmLogin() {
  AccountService.getInstance().selectHuaweiAccountToLogin();
  this.showAccountSheet = false;
}

// 4. 用户点击"取消"
cancelLogin() {
  this.showAccountSheet = false;
}
```

---

## 最佳实践

### 1. 单例模式

```typescript
// AccountService 使用单例模式，全局共享
AccountService.getInstance().login(uiContext);
AccountService.getInstance().getUserInfo();
```

### 2. 事件驱动

```typescript
// 使用事件总线解耦登录状态变化和 UI 更新
emitter.emit(CommonConstants.BIND_LOGOUT_EVENT);

// 监听事件
emitter.on(CommonConstants.BIND_LOGOUT_EVENT, () => {
  this.updateUI();
});
```

### 3. 防 CSRF 攻击

```typescript
// 生成随机 state
authRequest.state = util.generateRandomUUID();

// 验证 state
if (response.state !== authRequest.state) {
  reject(new Error('State mismatch'));
}
```

### 4. 错误处理

```typescript
AccountService.getInstance().login(uiContext)
  .then((userAccount) => {
    // 成功
  })
  .catch((error: BusinessError) => {
    Logger.error(TAG, `Login failed: ${error.code} ${error.message}`);
    Toast.showToast('登录失败');
  });
```

---

## 参考资源

- [HarmonyOS Account Kit 文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/)
- [华为账号登录开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/)
- [CommonEventManager API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/)
