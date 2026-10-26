# 大肥鱼热线 v1.0.0

一个可以和 DeepSeek 大肥鱼打电话聊天的 iOS App。

- 版本：`1.0 (1)`
- 最低系统：iOS 17.0
- 构建环境：Xcode 27.1 / iOS 26.3.1 模拟器
- 挂断按钮会直接退出 App（按要求实现）

![通话界面](https://raw.githubusercontent.com/duhaoze2007/dafeiyu_call_iOS/main/Docs/simulator-call.png)

## 本次发布

第一版，包含：

- SwiftUI 全屏通话界面 + 手绘大肥鱼
- Apple Speech 本地优先语音识别
- 本地 `AVSpeechSynthesizer` 小奶音（可调音色 / 音调 / 语速）
- DeepSeek SSE 流式回复，首句一到就开口
- `deepseek-chat` 默认不思考，Chat 每轮最多 80 tokens
- 最近 6 条 / 560 字符上下文，旧对话自动截断
- 本地问候、错误提示、短促回应，不消耗 token
- 设置页：API Key、模型、音色、奶音、语速、试听、关于、隐私政策
- API Key 存 Keychain；无账号、无服务器、无统计 SDK
- 轻点大肥鱼插话；静音 / 免提 / 挂断

## 安装包

| 文件 | 用途 | 说明 |
|---|---|---|
| `FatFishCall-1.0-simulator-arm64.zip` | Mac 模拟器 | 解压后得到 `FatFishCall.app`，用 `xcrun simctl install` 或拖进 Device Hub |
| `FatFishCall-1.0-unsigned.ipa` | iPhone | 未签名，必须用 Sideloadly / AltStore 等用自己的 Apple ID 重签 |

SHA-256：

```text
8f3f91a6885b09b93d936a982e6cf8aafabbbdde433642778fb63ba1ed2392d6  FatFishCall-1.0-simulator-arm64.zip
4038630362469e582c7a2dbdca0768194844aed14c131dec83100f08c12db57c  FatFishCall-1.0-unsigned.ipa
```

详细图文说明见仓库：[INSTALL.md](https://github.com/duhaoze2007/dafeiyu_call_iOS/blob/main/INSTALL.md)

## 模拟器安装（最快）

要求：macOS + Xcode 16 以上 + iOS 17 以上模拟器。

```bash
# 1. 下载并解压 FatFishCall-1.0-simulator-arm64.zip
# 2. 启动模拟器
xcrun simctl boot "iPhone 17 Pro"

# 3. 打开 Xcode 27 的 Device Hub
open /Applications/Xcode.app/Contents/Applications/DeviceHub.app

# 4. 安装并启动（把路径换成你的）
xcrun simctl install booted /你的路径/FatFishCall.app
xcrun simctl launch booted com.duhaoze.fatfishcall
```

也可以把 `FatFishCall.app` 直接拖进 Device Hub 的模拟器窗口。

> 模拟器构建不要加 `CODE_SIGNING_ALLOWED=NO`，否则 Keychain 写入会失败。默认 `Sign to Run Locally` 正常。

## iPhone 安装（unsigned IPA）

`FatFishCall-1.0-unsigned.ipa` 不能直接双击安装，需要重签：

1. 下载 [Sideloadly](https://sideloadly.io/) 或 AltStore；
2. iPhone 连接电脑，解锁并“信任”；
3. 选择 IPA，填入你的 Apple ID；
4. Bundle ID 冲突时改成 `com.你的名字.fatfishcall`；
5. Start，等待安装；
6. iPhone：`设置 > 通用 > VPN 与设备管理` 信任开发者；
7. iOS 16+ 如提示：`设置 > 隐私与安全性 > 开发者模式` 打开并重启；
8. 打开 App。

免费 Apple ID 签名通常 7 天有效，到期需重签；付费开发者账号可 1 年。

## 首次使用

1. 允许“语音识别”；
2. 允许“麦克风”；
3. 点右上角齿轮；
4. 填入 DeepSeek API Key（<https://platform.deepseek.com/api_keys>）；
5. 点“完成”。

大肥鱼会先本地打招呼，然后开始聆听。说话停顿约 1 秒算一轮结束；它说话时轻点它可插话；红色按钮挂断并退出 App。

## 更自然的小奶音

App 使用 Apple 本地 TTS。真机建议先下载增强音质：

`设置 > 辅助功能 > 朗读内容 > 声音 > 中文` → 下载“婷婷（增强）”或“婷婷（高级）”

再回 App：`设置 > 声音 > 音色 > 婷婷`。

模拟器通常只有标准音色，真机效果会更好。

## 已知限制

- 需要你自己的 DeepSeek API Key，App 不内置 Key；
- 本次没有用真实 Key 测试 DeepSeek 回复链路，只用占位 Key 验证了本地流程；
- 真机麦克风/扬声器和增强音色仍建议实际试一遍；
- 挂断使用 `exit(0)`，App Store 审核通常不接受；上架请把 `AppConfig.exitOnHangup` 改成 `false`；
- 没有开启后台音频，切后台/锁屏会暂停这一轮；
- unsigned IPA 必须重签，不能直接安装。

## 源码

<https://github.com/duhaoze2007/dafeiyu_call_iOS>

MIT License.
