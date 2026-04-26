import router from '@ohos.router';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import common from '@ohos.app.ability.common';
import { Channel } from '../models/Channel';
import { ChannelGroup } from '../models/ChannelGroup';
import { Subscription } from '../models/Subscription';
import { M3uParser } from '../utils/M3uParser';
import { HttpUtil } from '../utils/HttpUtil';
import { StorageUtil } from '../utils/StorageUtil';
import { ChannelListComponent } from '../components/ChannelListComponent';
import { VideoPlayerComponent } from '../components/VideoPlayerComponent';

@Entry
@Component
struct Index {
  @State groups: ChannelGroup[] = [];
  @State currentChannel: Channel | null = null;
  @State isLoading: boolean = false;
  @State loadingMsg: string = '';
  @State showAddDialog: boolean = false;
  @State dialogMode: string = 'url';
  @State inputUrl: string = '';
  @State errorMsg: string = '';
  private subscriptions: Subscription[] = [];
  private customChannels: Channel[] = [];

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await StorageUtil.init(context);
    await this.loadData();
  }

  private async loadData(): Promise<void> {
    this.subscriptions = await StorageUtil.loadSubscriptions();
    this.customChannels = await StorageUtil.loadCustomChannels();
    await this.refreshAllChannels();
  }

  private async refreshAllChannels(): Promise<void> {
    this.isLoading = true;
    this.loadingMsg = '刷新频道列表...';
    this.errorMsg = '';
    const allGroups = new Map<string, ChannelGroup>();
    const failedSubs: string[] = [];

    for (const sub of this.subscriptions) {
      if (!sub.enabled) {
        continue;
      }
      try {
        this.loadingMsg = `加载订阅: ${sub.name}`;
        const content = await HttpUtil.fetchText(sub.url);
        const parsed = M3uParser.parse(content);
        for (const g of parsed) {
          if (!allGroups.has(g.name)) {
            allGroups.set(g.name, new ChannelGroup(g.name));
          }
          allGroups.get(g.name)!.channels.push(...g.channels);
        }
        sub.lastUpdated = Date.now();
      } catch (e) {
        failedSubs.push(sub.name);
      }
    }

    if (this.customChannels.length > 0) {
      const customGroup = new ChannelGroup('我的频道');
      customGroup.channels = [...this.customChannels];
      allGroups.set('我的频道', customGroup);
    }

    const result: ChannelGroup[] = [];
    allGroups.forEach((g) => result.push(g));
    this.groups = result;
    this.isLoading = false;
    this.loadingMsg = '';
    if (failedSubs.length > 0 && result.length === 0) {
      this.errorMsg = `加载失败: ${failedSubs.join(', ')}\n请检查网络连接或地址是否正确`;
    } else if (failedSubs.length > 0) {
      this.errorMsg = `部分订阅加载失败: ${failedSubs.join(', ')}`;
    }
    await StorageUtil.saveSubscriptions(this.subscriptions);
  }

  private async loadFromUrl(url: string): Promise<void> {
    if (!url.trim()) {
      return;
    }
    this.isLoading = true;
    this.loadingMsg = '加载播放列表...';
    this.errorMsg = '';
    try {
      const content = await HttpUtil.fetchText(url.trim());
      M3uParser.parse(content);
      let subName = url.trim().substring(url.lastIndexOf('/') + 1) || '新订阅';
      if (subName.length > 40) {
        subName = subName.substring(0, 40);
      }
      const newSub = new Subscription(`sub_${Date.now()}`, subName, url.trim());
      this.subscriptions.push(newSub);
      await StorageUtil.saveSubscriptions(this.subscriptions);
      await this.refreshAllChannels();
    } catch (e) {
      this.isLoading = false;
      this.loadingMsg = '';
      this.errorMsg = `加载失败，请检查网络和地址是否正确`;
    }
  }

  private async loadFromLocalFile(): Promise<void> {
    try {
      const docPicker = new picker.DocumentViewPicker();
      const result = await docPicker.select({
        maxSelectNumber: 1
      });
      if (!result || result.length === 0) {
        return;
      }
      const uri = result[0];
      this.isLoading = true;
      this.loadingMsg = '读取文件...';
      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(file.fd);
      const buf = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buf);
      fs.closeSync(file);
      const decoder = util.TextDecoder.create('utf-8');
      const content = decoder.decodeWithStream(new Uint8Array(buf));
      const newSub = new Subscription(`sub_local_${Date.now()}`, '本地文件', uri);
      newSub.lastUpdated = Date.now();
      this.subscriptions.push(newSub);
      await StorageUtil.saveSubscriptions(this.subscriptions);
      M3uParser.parse(content);
      await this.refreshAllChannels();
    } catch {
      this.isLoading = false;
      this.loadingMsg = '';
    }
  }

  private onChannelSelected(channel: Channel): void {
    this.currentChannel = channel;
  }

  private goFullScreen(): void {
    if (this.currentChannel) {
      router.pushUrl({
        url: 'pages/PlayerPage',
        params: {
          channelName: this.currentChannel.name,
          channelUrl: this.currentChannel.url
        }
      });
    }
  }

  build() {
    Stack() {
      Row() {
        // Left panel: channel list (30%)
        ChannelListComponent({
          selectedChannelId: this.currentChannel?.id ?? '',
          groups: this.groups,
          onChannelSelect: (ch: Channel) => this.onChannelSelected(ch),
          onManageSubscriptions: () => {
            router.pushUrl({ url: 'pages/SubscriptionPage' });
          },
          onAddChannel: () => {
            this.showAddDialog = true;
          }
        })
          .width('30%')
          .height('100%')

        // Divider
        Divider()
          .vertical(true)
          .strokeWidth(1)
          .color('#222233')
          .height('100%')

        // Right panel: video player
        VideoPlayerComponent({
          currentChannel: this.currentChannel,
          onFullScreenRequest: () => this.goFullScreen()
        })
          .layoutWeight(1)
          .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#050510')

      // Loading overlay
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#4FC3F7')
          Text(this.loadingMsg)
            .fontSize(14)
            .fontColor('#CCCCCC')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#88000000')
      }

      // Error banner
      if (this.errorMsg) {
        Row() {
          Text(this.errorMsg)
            .fontSize(13)
            .fontColor('#FFEEAA')
            .layoutWeight(1)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('✕')
            .fontSize(16)
            .fontColor('#FFEEAA')
            .padding({ left: 12, right: 8 })
            .onClick(() => { this.errorMsg = ''; })
        }
        .width('100%')
        .padding({ left: 14, right: 8, top: 10, bottom: 10 })
        .backgroundColor('#AA332200')
        .position({ x: 0, y: 0 })
      }

      // Add dialog
      if (this.showAddDialog) {
        Column() {
          Column() {
            Text('添加播放列表')
              .fontSize(18)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 16 })

            Row() {
              Text('远程URL')
                .fontSize(14)
                .fontColor(this.dialogMode === 'url' ? '#4FC3F7' : '#AAAAAA')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(4)
                .backgroundColor(this.dialogMode === 'url' ? '#1A3A4A' : Color.Transparent)
                .onClick(() => { this.dialogMode = 'url'; })
              Text('本地文件')
                .fontSize(14)
                .fontColor(this.dialogMode === 'file' ? '#4FC3F7' : '#AAAAAA')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(4)
                .backgroundColor(this.dialogMode === 'file' ? '#1A3A4A' : Color.Transparent)
                .onClick(() => { this.dialogMode = 'file'; })
            }
            .margin({ bottom: 16 })

            if (this.dialogMode === 'url') {
              TextInput({ placeholder: '输入 M3U/M3U8 地址', text: this.inputUrl })
                .width('100%')
                .height(44)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .placeholderColor('#666666')
                .backgroundColor('#1A1A2E')
                .borderRadius(8)
                .onChange((v) => { this.inputUrl = v; })
                .margin({ bottom: 16 })
            }

            Row() {
              Button('取消')
                .layoutWeight(1)
                .height(40)
                .backgroundColor('#333344')
                .fontColor('#AAAAAA')
                .margin({ right: 8 })
                .onClick(() => {
                  this.showAddDialog = false;
                  this.inputUrl = '';
                })

              Button(this.dialogMode === 'url' ? '加载' : '选择文件')
                .layoutWeight(1)
                .height(40)
                .backgroundColor('#4FC3F7')
                .fontColor(Color.White)
                .onClick(() => {
                  this.showAddDialog = false;
                  if (this.dialogMode === 'url') {
                    this.loadFromUrl(this.inputUrl);
                    this.inputUrl = '';
                  } else {
                    this.loadFromLocalFile();
                  }
                })
            }
            .width('100%')
          }
          .width('85%')
          .padding(24)
          .backgroundColor('#1E1E30')
          .borderRadius(12)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#88000000')
        .onClick(() => { this.showAddDialog = false; })
      }
    }
    .width('100%')
    .height('100%')
  }
}