import { Channel } from '../models/Channel';
import { ChannelGroup } from '../models/ChannelGroup';

@Component
export struct ChannelListComponent {
  @Prop selectedChannelId: string = '';
  @Prop @Watch('onGroupsChanged') groups: ChannelGroup[] = [];
  @State private expandedGroups: boolean[] = [];
  onChannelSelect: (channel: Channel) => void = () => {};
  onManageSubscriptions: () => void = () => {};
  onAddChannel: () => void = () => {};

  aboutToAppear() {
    this.expandedGroups = this.groups.map(() => true);
  }

  onGroupsChanged() {
    this.expandedGroups = this.groups.map((_, i) => {
      return i < this.expandedGroups.length ? this.expandedGroups[i] : true;
    });
  }

  build() {
    Column() {
      // Header toolbar
      Row() {
        Text('频道列表')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        Image($r('app.media.startIcon'))
          .width(20)
          .height(20)
          .fillColor('#AAAAAA')
          .margin({ right: 8 })
          .onClick(() => this.onAddChannel())
          .focusable(true)

        Image($r('app.media.startIcon'))
          .width(20)
          .height(20)
          .fillColor('#AAAAAA')
          .onClick(() => this.onManageSubscriptions())
          .focusable(true)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor('#1A1A2E')

      if (this.groups.length === 0) {
        Column() {
          Text('暂无频道')
            .fontSize(14)
            .fontColor('#888888')
            .margin({ top: 20 })
          Text('请添加订阅或手动添加频道')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 0 }) {
          ForEach(this.groups, (group: ChannelGroup, gIndex: number) => {
            ListItemGroup({
              header: this.buildGroupHeader(group, gIndex)
            }) {
              if (this.expandedGroups[gIndex] !== false) {
                ForEach(group.channels, (channel: Channel) => {
                  ListItem() {
                    this.buildChannelItem(channel)
                  }
                }, (channel: Channel) => channel.id)
              }
            }
          }, (group: ChannelGroup) => group.name)
        }
        .layoutWeight(1)
        .backgroundColor('#0F0F1E')
        .divider({ strokeWidth: 0.5, color: '#333344', startMargin: 12, endMargin: 0 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0F0F1E')
  }

  @Builder
  buildGroupHeader(group: ChannelGroup, index: number) {
    Row() {
      Text(this.expandedGroups[index] !== false ? '▾' : '▸')
        .fontSize(12)
        .fontColor('#8888AA')
        .margin({ right: 6 })
      Text(group.name)
        .fontSize(13)
        .fontColor('#CCCCDD')
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Text(`${group.channels.length}`)
        .fontSize(11)
        .fontColor('#666677')
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#161628')
    .focusable(true)
    .onClick(() => {
      const newState = [...this.expandedGroups];
      newState[index] = !newState[index];
      this.expandedGroups = newState;
    })
  }

  @Builder
  buildChannelItem(channel: Channel) {
    Row() {
      Column() {
        if (channel.tvgLogo) {
          Image(channel.tvgLogo)
            .width(32)
            .height(32)
            .borderRadius(4)
            .objectFit(ImageFit.Contain)
            .backgroundColor('#222233')
        } else {
          Text(channel.name.charAt(0))
            .width(32)
            .height(32)
            .fontSize(14)
            .fontColor('#AAAACC')
            .textAlign(TextAlign.Center)
            .backgroundColor('#222233')
            .borderRadius(4)
        }
      }
      .margin({ right: 10 })

      Text(channel.name)
        .fontSize(14)
        .fontColor(channel.id === this.selectedChannelId ? '#4FC3F7' : '#CCCCDD')
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 10, bottom: 10 })
    .backgroundColor(channel.id === this.selectedChannelId ? '#1A2A3A' : Color.Transparent)
    .focusable(true)
    .onClick(() => this.onChannelSelect(channel))
  }
}
