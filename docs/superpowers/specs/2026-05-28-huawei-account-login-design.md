# 华为账号登录功能设计

## 概述

为 LightMarkdown 应用实现华为账号登录功能，支持登录、登出、持久化、系统状态监听。

## 文件结构

```
common/src/main/ets/
├── accountservice/
│   ├── AccountService.ets           # 账号服务单例
│   ├── model/
│   │   └── UserAccount.ets          # 用户模型
│   └── constant/
│       └── AccountServiceConstants.ets  # 账号相关常量
└── constant/
    └── CommonEnums.ets              # 添加账号事件常量
```

修改文件：
- `entry/src/main/module.json5` - 添加 GET_WIFI_INFO 权限
- `feature/mine/src/main/ets/page/Mine.ets` - 集成登录功能
- `entry/src/main/ets/entryability/EntryAbility.ets` - 初始化 AccountService

## UserAccount 模型

```typescript
export class UserAccount {
  public unionId: string = '';      // 用户唯一标识
  public nickname: string = '';     // 昵称
  public avatarUrl: string = '';    // 头像 URL
}
```

## AccountService 服务

单例模式，全局共享。

### 属性

- `userLogin: boolean` - 登录状态
- `userAccount: UserAccount` - 用户信息
- `loginCallbacks` / `logoutCallbacks` - 回调列表

### 方法

- `init()` - 从持久化恢复状态，检查华为账号授权，订阅系统状态
- `login(uiContext: UIContext): Promise<UserAccount>` - 发起华为账号授权
- `logoutDirect(): Promise<boolean>` - 清除状态，触发登出事件
- `getUserInfo(): UserAccount | undefined` - 获取用户信息
- `addAppLoginListener(callback)` / `addAppLogoutListener(callback)` - 添加监听器

### 内部方法

- `getAuthCredential(uiContext)` - 创建授权请求，验证 state 防 CSRF
- `subscribeAccountLoginState()` - 监听系统账号登录/登出广播
- `finishLogin()` - 更新持久化，触发回调
- `updatePreference()` - 保存到 PreferenceManager

## Mine.ets 页面集成

### 状态变量

- `@State isLogin: boolean = false`
- `@State avatarUrl: string = ''`
- `@State nickName: string = ''`

### 初始化

在 `aboutToAppear()` 中：
1. 监听 `BIND_MINE_LOGIN_EVENT` 事件
2. 监听 `BIND_LOGOUT_EVENT` 事件
3. 调用 `updateAccountData()` 初始化状态

### 登录逻辑

修改"登录/账号" CardItem 的 onclick：
- 未登录：调用 `AccountService.getInstance().login(uiContext)`
- 已登录：显示用户信息

### UI 更新

`updateAccountData()` 方法：
- 调用 `AccountService.getInstance().getUserInfo()`
- 更新 isLogin、avatarUrl、nickName

## EntryAbility 初始化

在 `onWindowStageCreate()` 中：
1. 初始化 UIContext 并存储到 AppStorage
2. 调用 `AccountService.getInstance().init()`

## 权限配置

在 `entry/src/main/module.json5` 中添加：
```json
{
  "requestPermissions": [
    {
      "name": "ohos.permission.GET_WIFI_INFO"
    }
  ]
}
```

## 事件常量

在 `CommonEnums.ets` 中添加：
```typescript
export enum AccountEvent {
  BIND_LOGOUT_EVENT = 'BindLogoutEvent',
  BIND_MINE_LOGIN_EVENT = 'BindMineLoginEvent',
}
```

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
