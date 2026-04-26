import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { Subscription } from '../models/Subscription';
import { StorageUtil } from '../utils/StorageUtil';

@Entry
@Component
struct SubscriptionPage {
  @State subscriptions: Subscription[] = [];
  @State showAddDialog: boolean = false;
  @State inputName: string = '';
  @State inputUrl: string = '';
  @State isLoading: boolean = false;

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await StorageUtil.init(context);
    this.subscriptions = await StorageUtil.loadSubscriptions();
  }

  private formatDate(ts: number): string {
    if (!ts) {
      return '从未更新';
    }
    const d = new Date(ts);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }

  private async addSubscription(): Promise<void> {
    const url = this.inputUrl.trim();
    const name = this.inputName.trim() || url.substring(url.lastIndexOf('/') + 1) || '新订阅';
    if (!url) {
      return;
    }
    const sub = new Subscription(`sub_${Date.now()}`, name, url);
    this.subscriptions.push(sub);
    await StorageUtil.saveSubscriptions(this.subscriptions);
    this.inputName = '';
    this.inputUrl = '';
    this.showAddDialog = false;
  }

  private async deleteSubscription(index: number): Promise<void> {
    this.subscriptions.splice(index, 1);
    await StorageUtil.saveSubscriptions(this.subscriptions);
  }

  private async toggleSubscription(index: number): Promise<void> {
    this.subscriptions[index].enabled = !this.subscriptions[index].enabled;
    await StorageUtil.saveSubscriptions(this.subscriptions);
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

        Text('订阅管理')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        Text('+ 添加')
          .fontSize(14)
          .fontColor('#4FC3F7')
          .padding({ left: 12, right: 16, top: 12, bottom: 12 })
          .focusable(true)
          .onClick(() => { this.showAddDialog = true; })
      }
      .width('100%')
      .backgroundColor('#1A1A2E')

      if (this.subscriptions.length === 0) {
        Column() {
          Text('暂无订阅')
            .fontSize(16)
            .fontColor('#888888')
            .margin({ top: 48 })
          Text('点击右上角"+ 添加"来添加 M3U/M3U8 订阅地址')
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 8 })
            .textAlign(TextAlign.Center)
            .padding({ left: 32, right: 32 })
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 0 }) {
          ForEach(this.subscriptions, (sub: Subscription, index: number) => {
            ListItem() {
              Row() {
                Column() {
                  Text(sub.name)
                    .fontSize(15)
                    .fontColor('#FFFFFF')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(sub.url)
                    .fontSize(11)
                    .fontColor('#888888')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 2 })
                  Text(`上次更新: ${this.formatDate(sub.lastUpdated)}`)
                    .fontSize(11)
                    .fontColor('#666666')
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                // Enable/Disable toggle
                Toggle({ type: ToggleType.Switch, isOn: sub.enabled })
                  .width(44)
                  .height(24)
                  .selectedColor('#4FC3F7')
                  .margin({ right: 12 })
                  .onChange((isOn: boolean) => {
                    this.subscriptions[index].enabled = isOn;
                    StorageUtil.saveSubscriptions(this.subscriptions);
                  })

                // Delete button
                Text('🗑')
                  .fontSize(18)
                  .padding(8)
                  .focusable(true)
                  .onClick(() => this.deleteSubscription(index))
              }
              .width('100%')
              .padding({ left: 16, right: 12, top: 14, bottom: 14 })
              .backgroundColor('#0F0F1E')
            }
          }, (sub: Subscription) => sub.id)
        }
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: '#222233' })
      }

      // Add dialog
      if (this.showAddDialog) {
        Stack() {
          Column() {
            Column() {
              Text('添加订阅')
                .fontSize(17)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 20 })

              TextInput({ placeholder: '订阅名称（可选）', text: this.inputName })
                .width('100%')
                .height(44)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .placeholderColor('#666666')
                .backgroundColor('#1A1A2E')
                .borderRadius(8)
                .onChange((v) => { this.inputName = v; })
                .margin({ bottom: 12 })

              TextInput({ placeholder: 'M3U/M3U8 地址（必填）', text: this.inputUrl })
                .width('100%')
                .height(44)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .placeholderColor('#666666')
                .backgroundColor('#1A1A2E')
                .borderRadius(8)
                .onChange((v) => { this.inputUrl = v; })
                .margin({ bottom: 20 })

              Row() {
                Button('取消')
                  .layoutWeight(1)
                  .height(40)
                  .backgroundColor('#333344')
                  .fontColor('#AAAAAA')
                  .margin({ right: 8 })
                  .onClick(() => {
                    this.showAddDialog = false;
                    this.inputName = '';
                    this.inputUrl = '';
                  })
                Button('添加')
                  .layoutWeight(1)
                  .height(40)
                  .backgroundColor('#4FC3F7')
                  .fontColor(Color.White)
                  .onClick(() => this.addSubscription())
              }
              .width('100%')
            }
            .width('90%')
            .padding(24)
            .backgroundColor('#1E1E30')
            .borderRadius(12)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#88000000')
        .position({ x: 0, y: 0 })
        .onClick(() => { this.showAddDialog = false; })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0A0A18')
  }
}
