import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { Subscription } from '../models/Subscription';
import { Channel } from '../models/Channel';

const STORE_NAME = 'iptv_store';
const KEY_SUBSCRIPTIONS = 'subscriptions';
const KEY_CUSTOM_CHANNELS = 'custom_channels';

export class StorageUtil {
  private static store: preferences.Preferences | null = null;

  static async init(context: common.UIAbilityContext): Promise<void> {
    StorageUtil.store = await preferences.getPreferences(context, STORE_NAME);
  }

  private static ensureStore(): preferences.Preferences {
    if (!StorageUtil.store) {
      throw new Error('StorageUtil not initialized. Call init() first.');
    }
    return StorageUtil.store;
  }

  static async saveSubscriptions(subs: Subscription[]): Promise<void> {
    const store = StorageUtil.ensureStore();
    await store.put(KEY_SUBSCRIPTIONS, JSON.stringify(subs));
    await store.flush();
  }

  static async loadSubscriptions(): Promise<Subscription[]> {
    const store = StorageUtil.ensureStore();
    const raw = await store.get(KEY_SUBSCRIPTIONS, '[]') as string;
    try {
      const arr = JSON.parse(raw) as object[];
      return arr.map((item: object) => {
        const o = item as Record<string, string | number | boolean>;
        const sub = new Subscription(
          o['id'] as string,
          o['name'] as string,
          o['url'] as string
        );
        sub.lastUpdated = o['lastUpdated'] as number || 0;
        sub.enabled = o['enabled'] !== false;
        return sub;
      });
    } catch {
      return [];
    }
  }

  static async saveCustomChannels(channels: Channel[]): Promise<void> {
    const store = StorageUtil.ensureStore();
    await store.put(KEY_CUSTOM_CHANNELS, JSON.stringify(channels));
    await store.flush();
  }

  static async loadCustomChannels(): Promise<Channel[]> {
    const store = StorageUtil.ensureStore();
    const raw = await store.get(KEY_CUSTOM_CHANNELS, '[]') as string;
    try {
      const arr = JSON.parse(raw) as object[];
      return arr.map((item: object) => {
        const o = item as Record<string, string | boolean>;
        const ch = new Channel(
          o['id'] as string,
          o['name'] as string,
          o['url'] as string,
          o['groupTitle'] as string || '',
          o['tvgLogo'] as string || '',
          o['tvgId'] as string || ''
        );
        ch.isCustom = true;
        return ch;
      });
    } catch {
      return [];
    }
  }
}
