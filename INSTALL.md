# 安装说明

这个仓库提供两种安装包：

| 文件 | 用途 | 是否需要签名 |
|---|---|---|
| `FatFishCall-1.0-simulator-arm64.zip` | 在 Mac 的 iOS 模拟器里运行 | 不需要，已本地签名 |
| `FatFishCall-1.0-unsigned.ipa` | 安装到 iPhone | **需要**用 Sideloadly / AltStore 等工具签名 |

下载地址：<https://github.com/duhaoze2007/dafeiyu_call_iOS/releases>

当前版本：`1.0 (1)`，最低 iOS 17.0。

SHA-256：

```text
8f3f91a6885b09b93d936a982e6cf8aafabbbdde433642778fb63ba1ed2392d6  FatFishCall-1.0-simulator-arm64.zip
4038630362469e582c7a2dbdca0768194844aed14c131dec83100f08c12db57c  FatFishCall-1.0-unsigned.ipa
```

---

## 方式一：Mac 模拟器（最简单）

需要：

- macOS；
- Xcode 16 或更新版本（本机用 Xcode 27.1 验证）；
- 一个 iOS 17+ 模拟器 runtime。

### 1. 下载并解压

下载 `FatFishCall-1.0-simulator-arm64.zip`，双击解压，得到 `FatFishCall.app`。

### 2. 启动模拟器并安装

在终端执行（把路径换成你解压后的路径）：

```bash
# 启动一个模拟器，名字用 xcrun simctl list devices available 里有的
xcrun simctl boot "iPhone 17 Pro"

# 打开模拟器窗口（Xcode 27 使用 Device Hub）
open /Applications/Xcode.app/Contents/Applications/DeviceHub.app

# 安装
xcrun simctl install booted /你的路径/FatFishCall.app

# 启动
xcrun simctl launch booted com.duhaoze.fatfishcall
```

也可以直接把 `FatFishCall.app` 拖进 Device Hub 的模拟器窗口。

### 3. 首次打开

1. 允许「语音识别」；
2. 允许「麦克风」；
3. 点右上角齿轮，填入 DeepSeek API Key；
4. 点「完成」。

### 4. 更自然的小奶音

模拟器里通常只有标准音色。真机建议：

`设置 > 辅助功能 > 朗读内容 > 声音 > 中文`

下载「婷婷（增强）」或「婷婷（高级）」，再回 App：

`设置 > 声音 > 音色 > 婷婷`

---

## 方式二：iPhone 侧载（unsigned IPA）

`FatFishCall-1.0-unsigned.ipa` **不能直接双击安装**。它没有 Apple 签名，需要用工具用你自己的 Apple ID 重签。

### 推荐工具

- [Sideloadly](https://sideloadly.io/)（Windows / macOS）
- [AltStore](https://altstore.io/) / SideStore
- 或者用 Xcode 打开源码，选自己的 Team 直接 Run 到 iPhone

### 用 Sideloadly 安装

1. 在 Mac/Windows 安装 Sideloadly；
2. iPhone 用数据线连接电脑，解锁并点「信任」；
3. 打开 Sideloadly，选择 `FatFishCall-1.0-unsigned.ipa`；
4. 填入你的 Apple ID；
5. 如果 Bundle ID 冲突，把 `com.duhaoze.fatfishcall` 改成别的，例如 `com.你的名字.fatfishcall`；
6. 点 Start，等待签名和安装完成；
7. iPhone 上打开：
   `设置 > 通用 > VPN 与设备管理` → 信任你的开发者证书；
8. iOS 16 及以上如果提示开发者模式：
   `设置 > 隐私与安全性 > 开发者模式` → 打开 → 重启 iPhone；
9. 回到主屏幕，打开「大肥鱼热线」。

> 免费 Apple ID 签名的 App 通常 7 天后需要重新签名；付费开发者账号可签 1 年。
> App 没有后台服务器，重新签名不会影响 API Key / 设置，但卸载会清除它们。

### 首次打开

1. 允许「语音识别」；
2. 允许「麦克风」；
3. 设置 → 填入 DeepSeek API Key；
4. 点「完成」，大肥鱼会先本地打招呼，然后开始聆听。

---

## 获取 DeepSeek API Key

1. 打开 <https://platform.deepseek.com/api_keys>；
2. 登录并创建一个 API Key；
3. 回到 App 设置页粘贴，点保存。

Key 只存在 iOS Keychain，不会上传到本项目的任何服务器（本项目没有服务器）。

---

## 常见问题

### 模拟器里 Key 保存失败

不要用 `CODE_SIGNING_ALLOWED=NO` 构建模拟器版本。关闭签名后 App 能启动，但 Keychain 写入会失败。默认的 `Sign to Run Locally` 即可。

### 一直“没听清”

- 确认语音识别 / 麦克风权限；
- 模拟器需要在 Device Hub 里允许使用 Mac 麦克风；
- 模拟器上的中文本地识别可能不可用，建议真机测试；
- 说话停顿约 1 秒会结束这一轮，不要停太久。

### 没有声音

- 看主界面右下角是「免提」还是「听筒」；
- 检查系统音量；
- 设置 → 声音 → 试听这个音色；
- 真机下载增强音色后再选一次。

### API 报错

- 401 / 403：Key 不对或没有权限；
- 402：余额不足；
- 429：限流；
- 其他：看主界面提示，或换网络。

### 为什么回复很短

电话场景 + 省 token：默认 Chat 不思考，每轮最多 80 tokens，人设要求 1–2 句、最多 40 个汉字。

---

## 从源码构建

```bash
git clone git@github.com:duhaoze2007/dafeiyu_call_iOS.git
cd dafeiyu_call_iOS
open FatFishCall.xcodeproj
```

在 Xcode 里：

1. 选择 `FatFishCall` target；
2. Signing & Capabilities 选择自己的 Team；
3. 选择模拟器或真机；
4. Run。

命令行构建模拟器版本：

```bash
xcodebuild \
  -project FatFishCall.xcodeproj \
  -scheme FatFishCall \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .build/DerivedData \
  build
```

注意：模拟器构建不要关闭代码签名，否则 Keychain 写入会失败。

---

## 已知限制

1. 挂断按钮按需求使用 `exit(0)` 直接退出 App；App Store 审核通常不接受这种主动退出行为。要上架请把 `AppConfig.exitOnHangup` 改成 `false`。
2. 没有开启后台音频：切到后台 / 锁屏时这一轮会暂停，回到前台点一下大肥鱼继续。
3. 音色来自 Apple 本地 TTS；增强 / 高级音色需要用户自己去系统设置下载。
4. 需要自己准备 DeepSeek API Key；App 不内置 Key。
5. unsigned IPA 必须重签后才能安装到 iPhone。
