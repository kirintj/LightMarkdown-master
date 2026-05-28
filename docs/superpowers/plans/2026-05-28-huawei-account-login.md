# 华为账号登录功能实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 LightMarkdown 应用实现华为账号登录功能，支持登录、登出、持久化、系统状态监听。

**Architecture:** 使用单例 AccountService 管理登录状态，通过 PreferenceManager 持久化，使用 emitter 事件总线解耦 UI 更新，使用 commonEventManager 监听系统账号状态变化。

**Tech Stack:** HarmonyOS ArkTS, @kit.AccountKit, @kit.BasicServicesKit, emitter, PreferenceManager

---

## 文件结构

```
common/src/main/ets/
├── accountservice/
│   ├── AccountService.ets           # 账号服务单例
│   ├── model/
│   │   └── UserAccount.ets          # 用户模型
│   └── constant/
│       └── AccountServiceConstants.ets  # 账号相关常量
├── constant/
│   └── CommonEnums.ets              # 添加账号事件常量
└── util/
    └── PreferenceManager.ets        # 持久化工具类
```

修改文件：
- `entry/src/main/module.json5` - 添加 GET_WIFI_INFO 权限
- `entry/src/main/ets/entryability/EntryAbility.ets` - 初始化 AccountService
- `feature/mine/src/main/ets/page/Mine.ets` - 集成登录功能

---

### Task 1: 创建 UserAccount 模型

**Files:**
- Create: `common/src/main/ets/accountservice/model/UserAccount.ets`

- [ ] **Step 1: 创建 UserAccount 模型文件**

```typescript
// common/src/main/ets/accountservice/model/UserAccount.ets

export class UserAccount {
  public unionId: string = '';
  public nickname: string = '';
  public avatarUrl: string = '';
}
```

- [ ] **Step 2: 验证文件创建**

检查文件是否存在：`ls common/src/main/ets/accountservice/model/UserAccount.ets`

- [ ] **Step 3: 提交**

```bash
git add common/src/main/ets/accountservice/model/UserAccount.ets
git commit -m "feat: 创建 UserAccount 用户模型"
```

---

### Task 2: 创建 AccountServiceConstants 常量

**Files:**
- Create: `common/src/main/ets/accountservice/constant/AccountServiceConstants.ets`

- [ ] **Step 1: 创建常量文件**

```typescript
// common/src/main/ets/accountservice/constant/AccountServiceConstants.ets

export class AccountServiceConstants {
  public static readonly USER_LOGIN: string = 'userLogin';
  public static readonly USER_ACCOUNT: string = 'userAccount';
}
```

- [ ] **Step 2: 验证文件创建**

检查文件是否存在：`ls common/src/main/ets/accountservice/constant/AccountServiceConstants.ets`

- [ ] **Step 3: 提交**

```bash
git add common/src/main/ets/accountservice/constant/AccountServiceConstants.ets
git commit -m "feat: 创建账号服务常量文件"
```

---

### Task 3: 更新 CommonEnums 添加事件常量

**Files:**
- Modify: `common/src/main/ets/constant/CommonEnums.ets`

- [ ] **Step 1: 添加账号事件常量**

在 CommonEnums.ets 文件末尾添加：

```typescript
export enum AccountEvent {
  BIND_LOGOUT_EVENT = 'BindLogoutEvent',
  BIND_MINE_LOGIN_EVENT = 'BindMineLoginEvent',
}
```

- [ ] **Step 2: 验证修改**

读取文件确认常量已添加：`cat common/src/main/ets/constant/CommonEnums.ets`

- [ ] **Step 3: 提交**

```bash
git add common/src/main/ets/constant/CommonEnums.ets
git commit -m "feat: 添加账号事件常量到 CommonEnums"
```

---

### Task 4: 创建 PreferenceManager 工具类

**Files:**
- Create: `common/src/main/ets/util/PreferenceManager.ets`

- [ ] **Step 1: 创建 PreferenceManager 文件**

```typescript
// common/src/main/ets/util/PreferenceManager.ets

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const TAG: string = '[PreferenceManager]';
const PREFERENCES_NAME: string = 'lightmd_preferences';

export class PreferenceManager {
  private static instance: PreferenceManager;
  private dataPreferences: preferences.Preferences | null = null;

  private constructor() {}

  public static getInstance(): PreferenceManager {
    if (!PreferenceManager.instance) {
      PreferenceManager.instance = new PreferenceManager();
    }
    return PreferenceManager.instance;
  }

  public async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(context, PREFERENCES_NAME);
    } catch (err) {
      console.error(TAG, `Init failed: ${JSON.stringify(err)}`);
    }
  }

  public getValue(key: string): preferences.ValueType | undefined {
    if (!this.dataPreferences) {
      return undefined;
    }
    try {
      return this.dataPreferences.getSync(key);
    } catch (err) {
      console.error(TAG, `Get value failed for key ${key}: ${JSON.stringify(err)}`);
      return undefined;
    }
  }

  public async setValue(key: string, value: preferences.ValueType): Promise<void> {
    if (!this.dataPreferences) {
      return;
    }
    try {
      await this.dataPreferences.put(key, value);
      await this.dataPreferences.flush();
    } catch (err) {
      console.error(TAG, `Set value failed for key ${key}: ${JSON.stringify(err)}`);
    }
  }
}
```

- [ ] **Step 2: 验证文件创建**

检查文件是否存在：`ls common/src/main/ets/util/PreferenceManager.ets`

- [ ] **Step 3: 提交**

```bash
git add common/src/main/ets/util/PreferenceManager.ets
git commit -m "feat: 创建 PreferenceManager 持久化工具类"
```

---

### Task 5: 创建 AccountService 服务

**Files:**
- Create: `common/src/main/ets/accountservice/AccountService.ets`

- [ ] **Step 1: 创建 AccountService 文件**

```typescript
// common/src/main/ets/accountservice/AccountService.ets

import { authentication } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { commonEventManager, emitter } from '@kit.BasicServicesKit';
import type { BusinessError } from '@kit.BasicServicesKit';
import { UserAccount } from './model/UserAccount';
import { AccountServiceConstants } from './constant/AccountServiceConstants';
import { AccountEvent } from '../constant/CommonEnums';
import { PreferenceManager } from '../util/PreferenceManager';

const TAG: string = '[AccountService]';

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

  public init(): void {
    this.userLogin = this.preferenceManager.getValue(AccountServiceConstants.USER_LOGIN) as boolean ?? false;
    this.userAccount = this.preferenceManager.getValue(AccountServiceConstants.USER_ACCOUNT) as UserAccount ?? new UserAccount();

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
        console.error(TAG, `Get HuaweiID state failed: ${error.code} ${error.message}`);
      });

    this.subscribeAccountLoginState();
  }

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
          console.error(TAG, `Login failed: ${error.code} ${error.message}`);
          reject(error);
        });
    });
  }

  private getAuthCredential(uiContext: UIContext): Promise<authentication.AuthorizationWithHuaweiIDCredential> {
    const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
    authRequest.scopes = ['profile'];
    authRequest.permissions = ['serviceauthcode'];
    authRequest.forceAuthorization = true;
    authRequest.state = util.generateRandomUUID();
    authRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256;

    const controller = new authentication.AuthenticationController(uiContext.getHostContext());

    return new Promise((resolve, reject) => {
      controller.executeRequest(authRequest)
        .then((result) => {
          const response = result as authentication.AuthorizationWithHuaweiIDResponse;

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

  public logoutDirect(): Promise<boolean> {
    return new Promise((resolve) => {
      this.userLogin = false;
      emitter.emit(AccountEvent.BIND_LOGOUT_EVENT);
      this.finishLogin();
      resolve(true);
    });
  }

  public selectHuaweiAccountToLogin() {
    this.userLogin = true;
    this.updatePreference(this.userLogin, this.userAccount);
    emitter.emit(AccountEvent.BIND_MINE_LOGIN_EVENT);
  }

  public getUserInfo(): UserAccount | undefined {
    if (this.userLogin) {
      return this.userAccount;
    }
    return undefined;
  }

  public addAppLoginListener(loginCallback: (userAccount: UserAccount) => void) {
    this.loginCallbacks.push(loginCallback);
  }

  public addAppLogoutListener(logoutCallback: () => void) {
    this.logoutCallbacks.push(logoutCallback);
  }

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
            console.error(TAG, `Subscribe failed: ${error.code} ${error.message}`);
            return;
          }

          if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN) {
            this.phoneLogin = true;
          }

          if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT) {
            this.userLogin = false;
            this.phoneLogin = false;
            this.finishLogin();
            emitter.emit(AccountEvent.BIND_LOGOUT_EVENT);
          }
        });
      })
      .catch((err) => {
        console.error(TAG, `Create subscriber failed: ${err.code} ${err.message}`);
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
    this.preferenceManager.setValue(AccountServiceConstants.USER_LOGIN, userLogin);
    this.preferenceManager.setValue(AccountServiceConstants.USER_ACCOUNT, userAccount);
  }
}
```

- [ ] **Step 2: 验证文件创建**

检查文件是否存在：`ls common/src/main/ets/accountservice/AccountService.ets`

- [ ] **Step 3: 提交**

```bash
git add common/src/main/ets/accountservice/AccountService.ets
git commit -m "feat: 创建 AccountService 账号服务"
```

---

### Task 6: 更新 common 模块导出

**Files:**
- Modify: `common/Index.ets`

- [ ] **Step 1: 添加导出**

在 common/Index.ets 文件中添加：

```typescript
export { AccountService } from './src/main/ets/accountservice/AccountService';
export { UserAccount } from './src/main/ets/accountservice/model/UserAccount';
export { AccountEvent } from './src/main/ets/constant/CommonEnums';
```

- [ ] **Step 2: 验证修改**

读取文件确认导出已添加：`cat common/Index.ets`

- [ ] **Step 3: 提交**

```bash
git add common/Index.ets
git commit -m "feat: 导出 AccountService 和相关类型"
```

---

### Task 7: 添加权限配置

**Files:**
- Modify: `entry/src/main/module.json5`

- [ ] **Step 1: 添加 GET_WIFI_INFO 权限**

在 entry/src/main/module.json5 的 requestPermissions 数组中添加：

```json
{
  "name": "ohos.permission.GET_WIFI_INFO"
}
```

- [ ] **Step 2: 验证修改**

读取文件确认权限已添加：`cat entry/src/main/module.json5`

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/module.json5
git commit -m "feat: 添加 GET_WIFI_INFO 权限配置"
```

---

### Task 8: 更新 EntryAbility 初始化

**Files:**
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`

- [ ] **Step 1: 添加导入**

在文件顶部添加导入：

```typescript
import { AccountService } from 'common';
import { PreferenceManager } from 'common/src/main/ets/util/PreferenceManager';
```

- [ ] **Step 2: 添加初始化逻辑**

在 onWindowStageCreate 方法中，在 `WindowUtil.initialize(windowStage);` 之前添加：

```typescript
// 初始化 PreferenceManager
PreferenceManager.getInstance().init(this.context).then(() => {
  // 初始化账号服务
  AccountService.getInstance().init();
});
```

- [ ] **Step 3: 验证修改**

读取文件确认初始化已添加：`cat entry/src/main/ets/entryability/EntryAbility.ets`

- [ ] **Step 4: 提交**

```bash
git add entry/src/main/ets/entryability/EntryAbility.ets
git commit -m "feat: 在 EntryAbility 中初始化 AccountService"
```

---

### Task 9: 更新 Mine.ets 页面集成登录

**Files:**
- Modify: `feature/mine/src/main/ets/page/Mine.ets`

- [ ] **Step 1: 添加导入**

在文件顶部添加导入：

```typescript
import { AccountService, UserAccount, AccountEvent } from 'common';
import { emitter } from '@kit.BasicServicesKit';
```

- [ ] **Step 2: 添加状态变量**

在 Mine 组件中添加状态变量：

```typescript
@State isLogin: boolean = false;
@State avatarUrl: string = '';
@State nickName: string = '';
```

- [ ] **Step 3: 添加事件监听**

在 aboutToAppear 方法中添加事件监听：

```typescript
// 监听登录事件
emitter.on(AccountEvent.BIND_MINE_LOGIN_EVENT, () => {
  this.updateAccountData();
});

// 监听登出事件
emitter.on(AccountEvent.BIND_LOGOUT_EVENT, () => {
  this.updateAccountData();
});

// 初始化账号状态
this.updateAccountData();
```

- [ ] **Step 4: 添加 updateAccountData 方法**

在 Mine 组件中添加方法：

```typescript
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
```

- [ ] **Step 5: 添加 handleLogin 方法**

在 Mine 组件中添加方法：

```typescript
handleLogin() {
  const uiContext = this.getUIContext();
  AccountService.getInstance().login(uiContext)
    .then((userAccount) => {
      this.avatarUrl = userAccount.avatarUrl;
      this.nickName = userAccount.nickname;
      AccountService.getInstance().selectHuaweiAccountToLogin();
    })
    .catch((error) => {
      console.error('[Mine] Login failed:', JSON.stringify(error));
    });
}
```

- [ ] **Step 6: 修改"登录/账号" CardItem**

找到"登录/账号"的 CardItem，修改 onclick 逻辑：

```typescript
ListItem({ style: ListItemStyle.CARD }) {
  if (this.isLogin) {
    Row() {
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
    }
    .padding({ left: 16 })
  } else {
    CardItem({
      isShow: true,
      textContent: '登录 / 账号',
      symbolSrc: $r('sys.symbol.person'),
      onclick: () => {
        this.handleLogin();
      },
    })
  }
}
.height(undefined)
.width('100%')
```

- [ ] **Step 7: 验证修改**

读取文件确认登录功能已集成：`cat feature/mine/src/main/ets/page/Mine.ets`

- [ ] **Step 8: 提交**

```bash
git add feature/mine/src/main/ets/page/Mine.ets
git commit -m "feat: 在 Mine 页面集成华为账号登录功能"
```

---

### Task 10: 最终验证

- [ ] **Step 1: 检查所有文件**

```bash
# 检查创建的文件
ls common/src/main/ets/accountservice/model/UserAccount.ets
ls common/src/main/ets/accountservice/constant/AccountServiceConstants.ets
ls common/src/main/ets/accountservice/AccountService.ets
ls common/src/main/ets/util/PreferenceManager.ets

# 检查修改的文件
cat common/src/main/ets/constant/CommonEnums.ets
cat entry/src/main/module.json5
cat entry/src/main/ets/entryability/EntryAbility.ets
cat feature/mine/src/main/ets/page/Mine.ets
```

- [ ] **Step 2: 提交所有更改**

```bash
git add .
git commit -m "feat: 完成华为账号登录功能实现"
```

---

## 登录流程

```
1. 用户点击"登录/账号"
      ↓
2. 调用 AccountService.login(uiContext)
      ↓
3. 创建 AuthorizationWithHuaweiIDRequest
   - scopes: ['profile']
   - permissions: ['serviceauthcode']
   - forceAuthorization: true
   - state: UUID (防 CSRF)
      ↓
4. 系统弹出华为账号授权页面
      ↓
5. 用户点击"允许"授权
      ↓
6. 返回 AuthorizationWithHuaweiIDCredential
      ↓
7. 保存到 UserAccount 模型
      ↓
8. 持久化到 PreferenceManager
      ↓
9. 触发 loginCallbacks，更新 UI
```

## 状态监听

### 系统账号状态

使用 commonEventManager 订阅：
- `COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN`
- `COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT`

### 应用内事件

使用 emitter 总线：
- `BIND_MINE_LOGIN_EVENT` - 登录事件
- `BIND_LOGOUT_EVENT` - 登出事件

## 错误处理

- 用户取消授权 (code: 1001500001) - 提示"用户取消登录"
- 网络错误 (code: 1001500002) - 提示"网络连接失败"
- 其他错误 - 提示"登录失败，请重试"
