import router from '@ohos.router';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import { KeyCode } from '@ohos.multimodalInput.keyCode';
import { IjkMediaPlayer } from "@ohos/ijkplayer";
import type { OnPreparedListener } from "@ohos/ijkplayer";
import type { OnErrorListener } from "@ohos/ijkplayer";
import type { OnInfoListener } from "@ohos/ijkplayer";

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
  private mContext: object | undefined = undefined;
  private mIjkMediaPlayer: IjkMediaPlayer = new IjkMediaPlayer();
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
    this.mIjkMediaPlayer.release();
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

  private startPlay(url: string): void {
    this.isLoading = true;
    this.isPlaying = false;
    this.errorMsg = '';

    try {
      this.mIjkMediaPlayer.reset();
    } catch {
      // ignore
    }

    this.mIjkMediaPlayer.setContext(this.mContext!, 'fullscreen_player');
    this.mIjkMediaPlayer.native_setup();

    // IPTVֱ�����ӳ�����
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
          this.errorMsg = '����ʧ��\n���������Ƶ����ַ';
        } else if (extra === -1007 || extra === -1010) {
          this.errorMsg = '��ʽ��֧��\n���������Դ';
        } else {
          this.errorMsg = `����ʧ�� (${what}/${extra})\n���������Ƶ����ַ`;
        }
      }
    };
    this.mIjkMediaPlayer.setOnErrorListener(onError);

    this.mIjkMediaPlayer.setMessageListener();
    this.mIjkMediaPlayer.setDataSource(url);
    this.mIjkMediaPlayer.prepareAsync();
    this.mIjkMediaPlayer.start();
  }

  private togglePlayPause(): void {
    if (this.isPlaying) {
      this.mIjkMediaPlayer.pause();
      this.isPlaying = false;
    } else {
      this.mIjkMediaPlayer.start();
      this.isPlaying = true;
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
      // ijkplayer XComponent surface
      XComponent({
        id: 'fullscreen_player',
        type: XComponentType.SURFACE,
        libraryname: 'ijkplayer_napi'
      })
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .onLoad((context) => {
          this.mContext = context;
          if (this.channelUrl) {
            this.startPlay(this.channelUrl);
          }
        })
        .onDestroy(() => {
          this.mIjkMediaPlayer.release();
        })

      // Loading
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(60)
            .height(60)
            .color('#4FC3F7')
          Text('������...')
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
          Text('??')
            .fontSize(56)
          Text(this.errorMsg)
            .fontSize(16)
            .fontColor('#FF6666')
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)
            .padding({ left: 24, right: 24 })
          Row() {
            Button('����')
              .height(40)
              .backgroundColor('#4FC3F7')
              .fontColor(Color.White)
              .margin({ right: 12 })
              .onClick(() => this.startPlay(this.channelUrl))
            Button('����')
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
          Row() {
            Text('��')
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

          Row() {
            Text(this.isPlaying ? '?' : '?')
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
            break;
        }
      }
    })
  }
}
