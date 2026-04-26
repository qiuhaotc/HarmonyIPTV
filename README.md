# HarmonyIPTV

[English](README.en.md) | 中文

一款基于 HarmonyOS 开发的 IPTV 播放器，支持加载和播放 M3U/M3U8 格式的直播频道列表。

## 功能特性

- **订阅管理**：支持添加远程 M3U/M3U8 播放列表 URL，自动拉取并刷新频道列表
- **本地导入**：支持从本地文件系统导入 M3U/M3U8 播放列表
- **频道分组**：自动按分组解析并展示频道列表，方便浏览
- **视频播放**：内置流媒体播放器，支持 IPTV 直播流播放
- **播放控制**：支持暂停/继续、音量调节、亮度调节及全屏播放
- **频道编辑**：支持手动添加、编辑和删除自定义频道
- **多设备支持**：适配手机、平板、2in1 及电视设备，支持遥控器操作
- **深色模式**：支持系统深色/浅色主题切换

## 技术栈

- **语言**：ArkTS
- **UI 框架**：HarmonyOS 声明式 UI
- **播放器**：[@ohos/ijkplayer](https://ohpm.openharmony.cn/#/cn/detail/@ohos%2Fijkplayer)
- **网络**：ohos.net.http
- **存储**：ohos.data.preferences
- **最低 API**：HarmonyOS NEXT

## 项目结构

```
IPTV/src/main/ets/
├── components/
│   ├── ChannelListComponent.ets   # 频道列表组件
│   └── VideoPlayerComponent.ets   # 视频播放器组件
├── models/
│   ├── Channel.ets                # 频道数据模型
│   ├── ChannelGroup.ets           # 频道分组数据模型
│   └── Subscription.ets           # 订阅数据模型
├── pages/
│   ├── Index.ets                  # 主页（频道列表 + 播放器）
│   ├── PlayerPage.ets             # 全屏播放页
│   ├── SubscriptionPage.ets       # 订阅管理页
│   └── ChannelEditPage.ets        # 频道编辑页
└── utils/
    ├── M3uParser.ets              # M3U/M3U8 解析器
    ├── HttpUtil.ets               # HTTP 请求工具
    ├── HttpTsStreamer.ets          # TS 流处理工具
    └── StorageUtil.ets            # 本地持久化工具
```

## 快速开始

### 环境要求

- [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) NEXT 或更高版本
- HarmonyOS SDK API 12+

### 构建运行

1. 使用 DevEco Studio 打开项目根目录
2. 等待依赖同步完成（`oh-package.json5`）
3. 连接 HarmonyOS 设备或启动模拟器
4. 点击 **Run** 运行应用

### 编译命令（命令行）

```powershell
& "C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" `
  "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" `
  clean --mode module -p product=default -p buildMode=release assembleHap `
  --analyze=normal --parallel --incremental --daemon
```

## 使用说明

1. 启动应用后，点击右上角菜单进入**订阅管理**页
2. 添加 M3U/M3U8 播放列表的远程 URL 或从本地文件导入
3. 返回主页，应用将自动加载并展示频道分组列表
4. 点击频道即可开始播放，支持全屏切换

## 许可证

[MIT License](LICENSE)
