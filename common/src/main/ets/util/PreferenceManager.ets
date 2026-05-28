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
      return this.dataPreferences.getSync(key, undefined);
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
