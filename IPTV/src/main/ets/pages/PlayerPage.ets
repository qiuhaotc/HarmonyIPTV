import router from '@ohos.router';
import media from '@ohos.multimedia.media';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import { KeyCode } from '@ohos.multimodalInput.keyCode';

interface PlayerRouterParams {
  channelName: string;
  channelUrl: string;
}

@Entry
@Component
struct PlayerPage {
  @State channelName: string = '';
  @State channelUrl: string = '';
  @State isPlaying: boolean = false;
  @State isLoading: boolean = true;
  @State errorMsg: string = '';
  @State showControls: boolean = true;
  private avPlayer: media.AVPlayer | null = null;
  private xComponentController: XComponentController = new XComponentController();
  private surfaceId: string = '';
  private controlsTimer: number = -1;
  private windowObj: window.Window | null = null;

  async aboutToAppear() {
    const params = router.getParams() as PlayerRouterParams;
    if (params) {
      this.channelName = params.channelName || '';
      this.channelUrl = params.channelUrl || '';
    }
    await this.enterFullScreen();
    this.scheduleHideControls();
  }

  async aboutToDisappear() {
    this.clearControlsTimer();
    await this.releasePlayer();
    await this.exitFullScreen();
  }

  private async enterFullScreen(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.windowObj = await window.getLastWindow(context);
      await this.windowObj.setWindowSystemBarEnable([]);
      await this.windowObj.setWindowLayoutFullScreen(true);
    } catch {
      // ignore
    }
  }

  private async exitFullScreen(): Promise<void> {
    try {
      if (this.windowObj) {
        await this.windowObj.setWindowSystemBarEnable(['status', 'navigation']);
        await this.windowObj.setWindowLayoutFullScreen(false);
      }
    } catch {
      // ignore
    }
  }

  private async initPlayer(url: string): Promise<void> {
    await this.releasePlayer();
    this.isLoading = true;
    this.errorMsg = '';
    try {
      this.avPlayer = await media.createAVPlayer();
      this.avPlayer.on('stateChange', async (state: string) => {
        switch (state) {
          case 'initialized':
            if (this.avPlayer && this.surfaceId) {
              this.avPlayer.surfaceId = this.surfaceId;
              await this.avPlayer.prepare();
            }
            break;
          case 'prepared':
            this.isLoading = false;
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
          case 'error':
            this.isLoading = false;
            this.isPlaying = false;
            this.errorMsg = '播放出错，请检查频道地址';
            break;
          default:
            break;
        }
      });
      this.avPlayer.on('error', (err) => {
        this.isLoading = false;
        this.isPlaying = false;
        const msg = err.message || '';
        if (msg.includes('Unsupported') || msg.includes('unsupport')) {
          this.errorMsg = '格式不支持：该频道可能是专网IPTV或私有协议\n需在运营商IPTV网络内才能收看';
        } else if (msg.includes('timeout') || msg.includes('connect')) {
          this.errorMsg = '连接超时：请检查是否在IPTV专网内';
        } else {
          this.errorMsg = `播放错误: ${msg}`;
        }
      });
      this.avPlayer.url = url;
    } catch {
      this.isLoading = false;
      this.errorMsg = '播放器初始化失败';
    }
  }

  private async releasePlayer(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.release();
      } catch {
        // ignore
      }
      this.avPlayer = null;
    }
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
    this.showControlsTemporarily();
  }

  private scheduleHideControls(): void {
    this.controlsTimer = setTimeout(() => {
      this.showControls = false;
      this.controlsTimer = -1;
    }, 4000);
  }

  private showControlsTemporarily(): void {
    this.showControls = true;
    this.clearControlsTimer();
    this.scheduleHideControls();
  }

  private clearControlsTimer(): void {
    if (this.controlsTimer !== -1) {
      clearTimeout(this.controlsTimer);
      this.controlsTimer = -1;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // Video surface
      XComponent({
        id: 'fullscreen_player',
        type: XComponentType.SURFACE,
        controller: this.xComponentController
      })
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .onLoad(() => {
          this.surfaceId = this.xComponentController.getXComponentSurfaceId();
          if (this.channelUrl) {
            this.initPlayer(this.channelUrl);
          }
        })

      // Loading
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(60)
            .height(60)
            .color('#4FC3F7')
          Text('加载中...')
            .fontSize(16)
            .fontColor('#CCCCCC')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // Error
      if (this.errorMsg) {
        Column() {
          Text('⚠️')
            .fontSize(56)
          Text(this.errorMsg)
            .fontSize(16)
            .fontColor('#FF6666')
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)
            .padding({ left: 24, right: 24 })
          Row() {
            Button('重试')
              .height(40)
              .backgroundColor('#4FC3F7')
              .fontColor(Color.White)
              .margin({ right: 12 })
              .onClick(() => this.initPlayer(this.channelUrl))
            Button('返回')
              .height(40)
              .backgroundColor('#444455')
              .fontColor('#CCCCCC')
              .onClick(() => router.back())
          }
          .margin({ top: 20 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // Controls overlay
      if (this.showControls) {
        Column() {
          // Top bar
          Row() {
            Text('←')
              .fontSize(24)
              .fontColor(Color.White)
              .padding({ left: 16, right: 12, top: 12, bottom: 12 })
              .focusable(true)
              .onClick(() => router.back())

            Text(this.channelName)
              .fontSize(18)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
          }
          .width('100%')
          .linearGradient({
            angle: 180,
            colors: [['#CC000000', 0.0], ['#00000000', 1.0]]
          })

          Blank().layoutWeight(1)

          // Bottom bar
          Row() {
            Text(this.isPlaying ? '⏸' : '▶')
              .fontSize(28)
              .fontColor(Color.White)
              .padding(12)
              .focusable(true)
              .onClick(() => this.togglePlayPause())
            Blank().layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 8, right: 8, bottom: 16 })
          .linearGradient({
            angle: 0,
            colors: [['#00000000', 0.0], ['#CC000000', 1.0]]
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
    .onKeyEvent((event: KeyEvent) => {
      if (event.type === KeyType.Down) {
        switch (event.keyCode) {
          case KeyCode.KEYCODE_BACK:
          case KeyCode.KEYCODE_ESCAPE:
            router.back();
            break;
          case KeyCode.KEYCODE_SPACE:
          case KeyCode.KEYCODE_MEDIA_PLAY_PAUSE:
            this.togglePlayPause();
            break;
          case KeyCode.KEYCODE_DPAD_CENTER:
            if (this.showControls) {
              this.togglePlayPause();
            } else {
              this.showControlsTemporarily();
            }
            break;
          default:
            this.showControlsTemporarily();
            break;
        }
      }
    })
  }
}
