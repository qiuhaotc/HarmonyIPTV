import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { Channel } from '../models/Channel';
import { StorageUtil } from '../utils/StorageUtil';

interface ChannelEditParams {
  channelId?: string;
  channelName?: string;
  channelUrl?: string;
  channelGroup?: string;
}

@Entry
@Component
struct ChannelEditPage {
  @State name: string = '';
  @State url: string = '';
  @State group: string = '';
  @State isEdit: boolean = false;
  private channelId: string = '';
  private existingChannels: Channel[] = [];

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await StorageUtil.init(context);
    this.existingChannels = await StorageUtil.loadCustomChannels();

    const params = router.getParams() as ChannelEditParams;
    if (params && params.channelId) {
      this.isEdit = true;
      this.channelId = params.channelId;
      this.name = params.channelName || '';
      this.url = params.channelUrl || '';
      this.group = params.channelGroup || '';
    }
  }

  private async save(): Promise<void> {
    const nameVal = this.name.trim();
    const urlVal = this.url.trim();
    if (!nameVal || !urlVal) {
      return;
    }
    if (this.isEdit) {
      const idx = this.existingChannels.findIndex((c) => c.id === this.channelId);
      if (idx >= 0) {
        this.existingChannels[idx].name = nameVal;
        this.existingChannels[idx].url = urlVal;
        this.existingChannels[idx].groupTitle = this.group.trim();
      }
    } else {
      const newChannel = new Channel(
        `custom_${Date.now()}`,
        nameVal,
        urlVal,
        this.group.trim()
      );
      newChannel.isCustom = true;
      this.existingChannels.push(newChannel);
    }
    await StorageUtil.saveCustomChannels(this.existingChannels);
    router.back();
  }

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#4FC3F7')
          .padding({ left: 16, right: 8, top: 12, bottom: 12 })
          .focusable(true)
          .onClick(() => router.back())

        Text(this.isEdit ? '编辑频道' : '添加频道')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')
      .backgroundColor('#1A1A2E')

      // Form
      Column() {
        Column() {
          Text('频道名称')
            .fontSize(13)
            .fontColor('#AAAAAA')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 6 })
          TextInput({ placeholder: '例如: CCTV1', text: this.name })
            .width('100%')
            .height(44)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .placeholderColor('#555566')
            .backgroundColor('#1A1A2E')
            .borderRadius(8)
            .onChange((v) => { this.name = v; })
        }
        .width('100%')
        .margin({ bottom: 16 })

        Column() {
          Text('流媒体地址')
            .fontSize(13)
            .fontColor('#AAAAAA')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 6 })
          TextInput({ placeholder: 'http://...', text: this.url })
            .width('100%')
            .height(44)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .placeholderColor('#555566')
            .backgroundColor('#1A1A2E')
            .borderRadius(8)
            .onChange((v) => { this.url = v; })
        }
        .width('100%')
        .margin({ bottom: 16 })

        Column() {
          Text('频道分组（可选）')
            .fontSize(13)
            .fontColor('#AAAAAA')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 6 })
          TextInput({ placeholder: '例如: 央视', text: this.group })
            .width('100%')
            .height(44)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .placeholderColor('#555566')
            .backgroundColor('#1A1A2E')
            .borderRadius(8)
            .onChange((v) => { this.group = v; })
        }
        .width('100%')
        .margin({ bottom: 32 })

        Button('保存')
          .width('100%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#4FC3F7')
          .fontColor(Color.White)
          .borderRadius(10)
          .onClick(() => this.save())
      }
      .padding(24)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0A0A18')
  }
}
