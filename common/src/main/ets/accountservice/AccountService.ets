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
          this.userLogin = true;
          this.updatePreference(this.userLogin, this.userAccount);
          emitter.emit(AccountEvent.BIND_MINE_LOGIN_EVENT);
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
      this.userAccount = new UserAccount();
      emitter.emit(AccountEvent.BIND_LOGOUT_EVENT);
      this.finishLogin();
      resolve(true);
    });
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
      .catch((err: BusinessError) => {
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
    if (userAccount) {
      this.preferenceManager.setValue(AccountServiceConstants.USER_ACCOUNT, userAccount);
    }
  }
}
