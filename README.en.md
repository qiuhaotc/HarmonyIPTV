# HarmonyIPTV

English | [中文](README.md)

An IPTV player for HarmonyOS that supports loading and playing live channel lists in M3U/M3U8 format.

## Features

- **Subscription Management**: Add remote M3U/M3U8 playlist URLs and auto-refresh channel lists
- **Local Import**: Import M3U/M3U8 playlists from the local file system
- **Channel Groups**: Automatically parses and displays channels by group for easy browsing
- **Video Playback**: Built-in streaming player supporting IPTV live streams
- **Playback Controls**: Pause/resume, volume adjustment, brightness control, and fullscreen mode
- **Channel Editing**: Manually add, edit, and delete custom channels
- **Multi-device Support**: Adapts to phones, tablets, 2-in-1 devices, and TVs; supports remote controller input
- **Dark Mode**: Follows system light/dark theme

## Tech Stack

- **Language**: ArkTS
- **UI Framework**: HarmonyOS Declarative UI
- **Player**: [@ohos/ijkplayer](https://ohpm.openharmony.cn/#/cn/detail/@ohos%2Fijkplayer)
- **Network**: ohos.net.http
- **Storage**: ohos.data.preferences
- **Minimum API**: HarmonyOS NEXT

## Project Structure

```
IPTV/src/main/ets/
├── components/
│   ├── ChannelListComponent.ets   # Channel list component
│   └── VideoPlayerComponent.ets   # Video player component
├── models/
│   ├── Channel.ets                # Channel data model
│   ├── ChannelGroup.ets           # Channel group data model
│   └── Subscription.ets           # Subscription data model
├── pages/
│   ├── Index.ets                  # Main page (channel list + player)
│   ├── PlayerPage.ets             # Fullscreen player page
│   ├── SubscriptionPage.ets       # Subscription management page
│   └── ChannelEditPage.ets        # Channel editing page
└── utils/
    ├── M3uParser.ets              # M3U/M3U8 parser
    ├── HttpUtil.ets               # HTTP request utility
    ├── HttpTsStreamer.ets          # TS stream handler
    └── StorageUtil.ets            # Local persistence utility
```

## Getting Started

### Requirements

- [DevEco Studio](https://developer.huawei.com/consumer/en/deveco-studio/) NEXT or later
- HarmonyOS SDK API 12+

### Build & Run

1. Open the project root directory in DevEco Studio
2. Wait for dependency sync to complete (`oh-package.json5`)
3. Connect a HarmonyOS device or start an emulator
4. Click **Run** to launch the app

### Build via Command Line

```powershell
& "C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" `
  "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" `
  clean --mode module -p product=default -p buildMode=release assembleHap `
  --analyze=normal --parallel --incremental --daemon
```

## Usage

1. Launch the app and tap the menu icon in the top-right to open **Subscription Management**
2. Add a remote M3U/M3U8 playlist URL or import from a local file
3. Return to the main page — the app will load and display channel groups automatically
4. Tap a channel to start playback; fullscreen toggle is supported

## License

This project is licensed under the [Apache License 2.0](LICENSE).
