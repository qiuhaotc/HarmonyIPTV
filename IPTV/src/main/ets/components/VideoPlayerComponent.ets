import { IjkMediaPlayer } from "@ohos/ijkplayer";
import type { OnPreparedListener } from "@ohos/ijkplayer";
import type { OnVideoSizeChangedListener } from "@ohos/ijkplayer";
import type { OnErrorListener } from "@ohos/ijkplayer";
import type { OnInfoListener } from "@ohos/ijkplayer";
import { Channel } from '../models/Channel';

@Component
export struct VideoPlayerComponent {
  @Prop @Watch('onChannelChanged') currentChannel: Channel | null = null;
  @State private isPlaying: boolean = false;
  @State private isLoading: boolean = false;
  @State private errorMsg: string = '';
  @State private showControls: boolean = true;
  private mContext: object | undefined = undefined;
  private mIjkMediaPlayer: IjkMediaPlayer = new IjkMediaPlayer();
  private controlsTimer: number = -1;
  private isSurfaceReady: boolean = false;
  onFullScreenRequest: () => void = () => {};

  onChannelChanged() {
    if (this.currentChannel && this.isSurfaceReady) {
      this.startPlay(this.currentChannel.url);
    }
  }

  aboutToDisappear() {
    if (this.controlsTimer !== -1) {
      clearTimeout(this.controlsTimer);
    }
    this.mIjkMediaPlayer.release();
  }

  private startPlay(url: string): void {
    this.isLoading = true;
    this.isPlaying = false;
    this.errorMsg = '';

    try {
      this.mIjkMediaPlayer.reset();
    } catch {
      // ignore if not yet initialized
    }

    this.mIjkMediaPlayer.setContext(this.mContext!, 'iptv_player');
    this.mIjkMediaPlayer.native_setup();

    // IPTV直播低延迟配置
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "start-on-prepared", "1");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "packet-buffering", "0");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "framedrop", "5");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "max_cached_duration", "3000");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "infbuf", "1");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "min-frames", "100");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "timeout", "10000000");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "connect_timeout", "10000000");

    const onPrepared: OnPreparedListener = {
      onPrepared: () => {
        this.isLoading = false;
      }
    };
    this.mIjkMediaPlayer.setOnPreparedListener(onPrepared);

    const onVideoSizeChanged: OnVideoSizeChangedListener = {
      onVideoSizeChanged: (width: number, height: number, sar_num: number, sar_den: number) => {
        this.isLoading = false;
      }
    };
    this.mIjkMediaPlayer.setOnVideoSizeChangedListener(onVideoSizeChanged);

    const onInfo: OnInfoListener = {
      onInfo: (what: number, extra: number) => {
        if (what === 3) { // MEDIA_INFO_VIDEO_RENDERING_START
          this.isLoading = false;
          this.isPlaying = true;
        }
      }
    };
    this.mIjkMediaPlayer.setOnInfoListener(onInfo);

    const onError: OnErrorListener = {
      onError: (what: number, extra: number) => {
        this.isLoading = false;
        this.isPlaying = false;
        if (extra === -10000 || what === -1004) {
          this.errorMsg = '连接失败\n请检查网络或频道地址是否正确';
        } else if (extra === -1007 || extra === -1010) {
          this.errorMsg = '格式不支持\n请更换播放源';
        } else {
          this.errorMsg = `播放失败 (${what}/${extra})\n请检查网络连接和频道地址`;
        }
      }
    };
    this.mIjkMediaPlayer.setOnErrorListener(onError);

    this.mIjkMediaPlayer.setMessageListener();
    this.mIjkMediaPlayer.setDataSource(url);
    this.mIjkMediaPlayer.prepareAsync();
    this.mIjkMediaPlayer.start();
  }

  async playChannel(channel: Channel): Promise<void> {
    this.startPlay(channel.url);
  }

  private togglePlayPause(): void {
    if (this.isPlaying) {
      this.mIjkMediaPlayer.pause();
      this.isPlaying = false;
    } else {
      this.mIjkMediaPlayer.start();
      this.isPlaying = true;
    }
  }

  private showControlsTemporarily(): void {
    this.showControls = true;
    if (this.controlsTimer !== -1) {
      clearTimeout(this.controlsTimer);
    }
    this.controlsTimer = setTimeout(() => {
      this.showControls = false;
      this.controlsTimer = -1;
    }, 3000);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // ijkplayer XComponent surface
      XComponent({
        id: 'iptv_player',
        type: XComponentType.SURFACE,
        libraryname: 'ijkplayer_napi'
      })
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .onLoad((context) => {
          this.mContext = context;
          this.isSurfaceReady = true;
          if (this.currentChannel) {
            this.startPlay(this.currentChannel.url);
          }
        })
        .onDestroy(() => {
          this.mIjkMediaPlayer.release();
        })

      // Loading indicator
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#4FC3F7')
          Text('加载中...')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // Error message
      if (this.errorMsg) {
        Column() {
          Text('??')
            .fontSize(48)
          Text(this.errorMsg)
            .fontSize(14)
            .fontColor('#FF6666')
            .margin({ top: 10 })
            .textAlign(TextAlign.Center)
            .padding({ left: 20, right: 20 })
          Button('重试')
            .margin({ top: 16 })
            .backgroundColor('#4FC3F7')
            .fontColor(Color.White)
            .height(36)
            .onClick(() => {
              if (this.currentChannel) {
                this.startPlay(this.currentChannel.url);
              }
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // No channel selected placeholder
      if (!this.currentChannel && !this.isLoading && !this.errorMsg) {
        Column() {
          Text('??')
            .fontSize(64)
          Text('请选择频道')
            .fontSize(16)
            .fontColor('#888888')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#050510')
      }

      // Controls overlay
      if (this.showControls && this.currentChannel) {
        Column() {
          Row() {
            Text(this.currentChannel.name)
              .fontSize(16)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
            Text('?')
              .fontSize(22)
              .fontColor(Color.White)
              .padding(8)
              .focusable(true)
              .onClick(() => this.onFullScreenRequest())
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .linearGradient({
            angle: 180,
            colors: [['#AA000000', 0.0], ['#00000000', 1.0]]
          })

          Blank().layoutWeight(1)

          Row() {
            Text(this.isPlaying ? '?' : '?')
              .fontSize(24)
              .fontColor(Color.White)
              .padding(10)
              .focusable(true)
              .onClick(() => this.togglePlayPause())
            Blank().layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 8, right: 8, bottom: 8 })
          .linearGradient({
            angle: 0,
            colors: [['#00000000', 0.0], ['#AA000000', 1.0]]
          })
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .onClick(() => this.showControlsTemporarily())
  }
}
