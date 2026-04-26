import media from '@ohos.multimedia.media';
import { Channel } from '../models/Channel';
import { HttpTsStreamer } from '../utils/HttpTsStreamer';

function isHlsUrl(url: string): boolean {
  const lower = url.toLowerCase();
  return lower.includes('.m3u8') || lower.includes('.m3u');
}

function isFlvUrl(url: string): boolean {
  return url.toLowerCase().includes('.flv');
}

@Component
export struct VideoPlayerComponent {
  @Prop @Watch('onChannelChanged') currentChannel: Channel | null = null;
  @State private isPlaying: boolean = false;
  @State private isLoading: boolean = false;
  @State private errorMsg: string = '';
  @State private showControls: boolean = true;
  @State private volume: number = 100;
  @State private bufferInfo: string = '';
  private avPlayer: media.AVPlayer | null = null;
  private xComponentController: XComponentController = new XComponentController();
  private surfaceId: string = '';
  private controlsTimer: number = -1;
  private isSurfaceReady: boolean = false;
  private tsStreamer: HttpTsStreamer | null = null;
  onFullScreenRequest: () => void = () => {};

  onChannelChanged() {
    if (this.currentChannel && this.isSurfaceReady) {
      this.initPlayer(this.currentChannel.url);
    }
  }

  aboutToDisappear() {
    this.releasePlayer();
    if (this.controlsTimer !== -1) {
      clearTimeout(this.controlsTimer);
    }
  }

  private setupPlayerListeners(player: media.AVPlayer): void {
    player.on('stateChange', async (state: string) => {
      switch (state) {
        case 'initialized':
          if (this.avPlayer && this.surfaceId) {
            this.avPlayer.surfaceId = this.surfaceId;
            await this.avPlayer.prepare();
          }
          break;
        case 'prepared':
          this.isLoading = false;
          this.bufferInfo = '';
          if (this.avPlayer) {
            await this.avPlayer.play();
          }
          break;
        case 'playing':
          this.isPlaying = true;
          this.isLoading = false;
          break;
        case 'paused':
          this.isPlaying = false;
          break;
        case 'stopped':
        case 'idle':
          this.isPlaying = false;
          break;
        case 'error':
          this.isLoading = false;
          this.isPlaying = false;
          this.errorMsg = '播放出错，请检查网络或频道地址';
          break;
        default:
          break;
      }
    });

    player.on('error', (err) => {
      this.isLoading = false;
      this.isPlaying = false;
      const msg = err.message || '';
      if (msg.includes('Unsupported') || msg.includes('unsupport')) {
        this.errorMsg = '格式不支持\n该频道流无法播放\n请尝试使用HLS(m3u8)格式的源';
      } else if (msg.includes('timeout') || msg.includes('connect') || msg.includes('IO')) {
        this.errorMsg = '连接失败\n请检查网络是否在IPTV专网内';
      } else if (msg) {
        this.errorMsg = `播放错误: ${msg.substring(0, 80)}`;
      } else {
        this.errorMsg = '播放失败，请重试';
      }
    });
  }

  private async initPlayer(url: string): Promise<void> {
    await this.releasePlayer();
    this.isLoading = true;
    this.errorMsg = '';
    this.bufferInfo = '';

    try {
      this.avPlayer = await media.createAVPlayer();
      this.setupPlayerListeners(this.avPlayer);

      if (isHlsUrl(url) || isFlvUrl(url)) {
        // HLS / HTTP-FLV: directly supported by AVPlayer
        this.avPlayer.url = url;
      } else {
        // Raw HTTP MPEG-TS stream: use dataSrc + HTTP streaming
        await this.startDataSrcPlayer(url);
      }
    } catch {
      this.isLoading = false;
      this.errorMsg = '播放器初始化失败';
    }
  }

  private async startDataSrcPlayer(url: string): Promise<void> {
    if (!this.avPlayer) {
      return;
    }

    // Start HTTP streaming download
    this.tsStreamer = new HttpTsStreamer();
    this.tsStreamer.start(url);

    // Wait for initial buffer (up to 8 seconds for 512KB)
    this.bufferInfo = '正在缓冲...';
    const waitResult = await this.waitForBuffer(512 * 1024, 8000);

    if (!waitResult || this.tsStreamer.hasError || !this.avPlayer) {
      this.isLoading = false;
      this.errorMsg = '连接失败\n无法获取流数据，请检查网络或地址';
      if (this.tsStreamer) {
        this.tsStreamer.stop();
        this.tsStreamer = null;
      }
      return;
    }

    const streamer = this.tsStreamer;
    const dataSrc: media.AVDataSrcDescriptor = {
      fileSize: -1, // -1 = live stream / unknown size
      callback: (buffer: ArrayBuffer, length: number): number => {
        return streamer.read(buffer, length);
      }
    };

    this.avPlayer.dataSrc = dataSrc;
  }

  private waitForBuffer(targetBytes: number, timeoutMs: number): Promise<boolean> {
    return new Promise((resolve) => {
      const startTime = Date.now();
      const checkBuffer = () => {
        if (!this.tsStreamer) {
          resolve(false);
          return;
        }
        if (this.tsStreamer.hasError) {
          resolve(false);
          return;
        }
        if (this.tsStreamer.buffered() >= targetBytes) {
          resolve(true);
          return;
        }
        if (Date.now() - startTime >= timeoutMs) {
          // Timeout but we have some data - try anyway
          resolve(this.tsStreamer.buffered() > 0);
          return;
        }
        setTimeout(checkBuffer, 200);
      };
      checkBuffer();
    });
  }

  private async releasePlayer(): Promise<void> {
    if (this.tsStreamer) {
      this.tsStreamer.stop();
      this.tsStreamer = null;
    }
    if (this.avPlayer) {
      try {
        await this.avPlayer.release();
      } catch {
        // ignore
      }
      this.avPlayer = null;
    }
    this.isPlaying = false;
    this.isLoading = false;
  }

  async playChannel(channel: Channel): Promise<void> {
    await this.initPlayer(channel.url);
  }

  private togglePlayPause(): void {
    if (!this.avPlayer) {
      return;
    }
    if (this.isPlaying) {
      this.avPlayer.pause();
    } else {
      this.avPlayer.play();
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
      // Video surface
      XComponent({
        id: 'iptv_player',
        type: XComponentType.SURFACE,
        controller: this.xComponentController
      })
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .onLoad(() => {
          this.surfaceId = this.xComponentController.getXComponentSurfaceId();
          this.isSurfaceReady = true;
          if (this.currentChannel) {
            this.initPlayer(this.currentChannel.url);
          }
        })

      // Loading / buffering indicator
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#4FC3F7')
          Text(this.bufferInfo || '加载中...')
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
          Text('⚠️')
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
                this.playChannel(this.currentChannel);
              }
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // No channel placeholder
      if (!this.currentChannel && !this.isLoading && !this.errorMsg) {
        Column() {
          Text('📺')
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
          // Channel info bar (top)
          Row() {
            Text(this.currentChannel.name)
              .fontSize(16)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
            // Full screen button
            Text('⤢')
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

          Blank()
            .layoutWeight(1)

          // Bottom control bar
          Row() {
            // Play/Pause button
            Text(this.isPlaying ? '⏸' : '▶')
              .fontSize(24)
              .fontColor(Color.White)
              .padding(10)
              .focusable(true)
              .onClick(() => this.togglePlayPause())

            Blank().layoutWeight(1)

            // Volume indicator
            Text(`🔊 ${this.volume}%`)
              .fontSize(13)
              .fontColor('#CCCCCC')
              .padding({ left: 8, right: 8 })
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
