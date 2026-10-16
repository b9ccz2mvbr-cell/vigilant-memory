# 极简预算助手 · iOS 版（SwiftUI + WidgetKit）

这是给 iPhone 用的原生 iOS 版本，功能与安卓版 / PWA 版一致，**外加桌面小组件**。

---

## ⚠️ 先看这一段

**这份代码是在 Windows 上写的，没有经过编译验证。**

写 iOS 应用必须用 macOS 上的 Xcode，我这边没有 Mac，所以：

- 语法和结构我尽量按稳妥的写法组织，但**可能有需要到现场调的小错**
- 出错大概率是这几类：某个 API 在当前 Xcode 版本上改名了、类型推断不明确、
  Info.plist 少个键、App Group 权限没配上
- 报错时把 Xcode 的红字发我，我照着改

**还需要你确认一件事**：免费 Apple ID 能不能用 App Groups 权限。
桌面小组件要靠它和主 App 共享数据。如果不行，小组件会显示"还没设置额度"，
但**主 App 本身照常工作**（记账、日历、调整额度都不受影响）。

---

## 一、目录结构

```
budget-ios/
├── Shared/                      ← 主 App 和小组件都要用（两个 target 都要加）
│   ├── BudgetClock.swift          预算日口径（凌晨 4:00 日界）
│   ├── Models.swift               数据模型 + 金额格式化
│   └── BudgetStore.swift          数据层（UserDefaults + App Group）
│
├── BudgetAssistant/             ← 主 App
│   ├── BudgetAssistantApp.swift   入口
│   ├── Theme.swift                深色玻璃皮肤
│   ├── Info.plist
│   └── Views/
│       ├── SetupView.swift        首次设置三步（规格 5.1）
│       ├── HomeView.swift         入口页两个大按钮（5.3）
│       ├── CalcSheet.swift        快速记账（5.4）
│       ├── CalendarView.swift     日历（5.6）
│       ├── DaySheet.swift         单日两池明细（5.6）
│       └── SettingsView.swift     调整额度（5.10）
│
├── BudgetWidget/                ← 桌面小组件
│   ├── BudgetWidget.swift         2x1 / 4x1 两种尺寸
│   └── Info.plist
│
└── project.yml                  ← XcodeGen 配置（可选）
```

---

## 二、在 Mac 上跑起来

> **没有 Mac 硬件？** 看第七节「云 Mac / GitHub Actions」——不用买也不用借，
> 在云端编译出 .ipa，拿回 Windows 用 AltStore 签名安装。

### 路线 A：用 XcodeGen（一条命令，推荐）

需要联网装一次 XcodeGen：

```bash
# 如果没装 Homebrew，先装（这一步可能要几分钟）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install xcodegen

cd budget-ios
xcodegen generate
open BudgetAssistant.xcodeproj
```

工程文件（含两个 target、App Group 权限、Info.plist 关联）会自动生成好。

### 路线 B：手动建工程（不用装东西，约 10 分钟）

1. Xcode → **File → New → Project → iOS → App**
   - Product Name: `BudgetAssistant`
   - Interface: **SwiftUI** ／ Language: **Swift**
   - 存到解压出来的 `budget-ios/` 目录下

2. 把 `Shared/` 和 `BudgetAssistant/` 里的 `.swift` 文件
   **拖进 Xcode 的项目导航栏**（勾选 Copy items if needed）
   - 注意：`BudgetAssistant/Views/` 里的都加到 **BudgetAssistant** target
   - `Shared/` 里的三个文件要**两个 target 都勾**

3. **File → New → Target → iOS → Widget Extension**
   - Product Name: `BudgetWidget`
   - **不要**勾 "Include Configuration Intent"
   - 建好后把自动生成的 `.swift` 文件删掉（移到废纸篓）
   - 再把 `BudgetWidget/BudgetWidget.swift` 拖进来，只勾 **BudgetWidget** target

4. **两个 target 都要加 App Group**：
   - 选中 target → **Signing & Capabilities** → **+ Capability** → **App Groups**
   - 添加 `group.com.example.budget`（两个 target 填**完全一样**的字符串）

5. **Signing**：两个 target 的 Team 都选你的 Apple ID
   - Xcode → Settings → Accounts → 加你的 Apple ID（免费账号即可）
   - 如果提示 Bundle ID 冲突，把 `com.example.budget` 改成
     `com.你的名字.budget`（两个 target 的前缀要一致）

### 然后

6. iPhone 用数据线连上 Mac
7. iPhone 上：**设置 → 隐私与安全 → 开发者模式 → 打开**，然后重启手机
   （iOS 16 起必须开，否则装好的 App 点开就闪退）
8. Xcode 顶部选中你的 iPhone → 点 ▶️ Run
9. iPhone 上：**设置 → 通用 → VPN与设备管理 → 信任你的 Apple ID**

---

## 三、加上桌面小组件

App 跑起来并设置好额度后：

1. 回 iPhone 桌面，**长按空白处 → 左上角「+」**
2. 搜索「预算余额」（或「预算助手」）
3. 选 **小号（2x1）** 或 **中号（4x1）**，拖到桌面

小组件显示：

| 尺寸 | 内容 |
|---|---|
| 小号 2x1 | 今日日常剩余（大字）+ 其他池剩余 |
| 中号 4x1 | 两个池各一条进度条 + 本月剩余 |

> 如果小组件一直显示「还没设置额度」，说明 App Group 没生效——
> 检查第 4 步两个 target 的字符串是否完全一致，或免费账号确实不给这个权限。

---

## 四、免费 Apple ID 的代价

| 限制 | 说明 |
|---|---|
| **7 天过期** | 装好后第 7 天 App 会打不开，必须重新连电脑编译一次 |
| 最多 3 个 App | 同时用免费账号签名的应用数量 |
| 无法上架 | 只能自己用，进不了 App Store |
| 小组件可能受限 | App Groups 是免费账号的不确定项 |

### 不想每 7 天连电脑？

用 **AltStore**（Windows 也能装，需要 iTunes）：

1. Windows 装 [AltServer](https://altstore.io/)，iPhone 装 AltStore
2. AltStore 用你的 Apple ID 登录后，会**自动帮你续签**
3. 手机和电脑在同一个 Wi-Fi 下，它会自己刷新，不用插线

不过 AltStore 只是省掉插线，**7 天这个限制消不掉**——那是苹果对免费账号的硬规定。

想彻底没有 7 天限制，只有两条路：
- 买 Apple Developer 账号（$99/年）→ 证书 1 年有效
- 不用原生 App，用 PWA（已经交付的那版，永久有效）

---

## 五、已知的、需要现场验证的点

我已经在 Windows 上做过一轮静态自检（括号平衡、跨 target 的类型可见性），
并主动修掉了三个会直接报错的 API 兼容问题。但**编译验证做不了**，仍可能有小错。

已处理：
- ✅ 小组件原来引用了只属于主 App 的 `AppColor` → 已提到 `Shared/AppPalette.swift`
- ✅ `.clipShape(.rect(...))`（iOS 17+）→ 换成 `UnevenRoundedRectangle`（iOS 16+）
- ✅ 小组件背景 `containerBackground` 是 iOS 17+ API → 小组件 target 部署目标设为 17.0

**版本要求**：
| Target | 最低 iOS |
|---|---|
| 主 App | 16.4（用了 `presentationBackground`） |
| 小组件 | 17.0（用了 `containerBackground`） |

iPhone 14 支持到 iOS 18，正常都在这个版本之上。

仍可能踩到的坑，按可能性排序：

1. **Xcode 版本差异** —— 老版本 Xcode 对某些 SwiftUI 简写会报错，按红字提示改即可。
2. **App Group 权限** —— 免费账号可能给不了（见第三节末）。症状是小组件一直显示
   「还没设置额度」，但主 App 一切正常。真不行就先把小组件 target 删掉。
3. **iPhone 停在 iOS 16** —— 小组件装不上。要么升级系统，要么把小组件的
   `containerBackground` 换回 `.background(...)`。
4. **Info.plist** —— 如果 Xcode 抱怨缺场景配置相关键，
   把 target 的 `GENERATE_INFOPLIST_FILE` 改成 `YES`，让 Xcode 自己生成。
5. **小组件刷新时机** —— 现在设的是每小时刷一次。跨过凌晨 4:00 日界后
   数字要等下一次刷新才对，可以接受；嫌慢可以改成 15 分钟。

---

## 六、与其它版本的功能对照

| 功能 | 安卓版 | PWA | iOS 版 |
|---|---|---|---|
| 双池计算（凌晨 4:00 日界） | 有 | 有 | 有 |
| 首次设置三步 | 有 | 有 | 有 |
| 入口页两个大按钮 | 有 | 有 | 有 |
| 快速记账（自绘键盘） | 有 | 有 | 有 |
| 日历 + 单日两池明细 | 有 | 有 | 有 |
| 调整额度 | 有 | 有 | 有 |
| **桌面小组件** | 有 | 做不到 | **有** |
| 悬浮球（切到别的应用也能记） | 有 | 做不到 | **做不到** |
| 常驻通知 | 有 | 做不到 | 做不到 |

> 悬浮球在 iOS 上**无解**——系统不允许第三方应用画在其他应用之上。
> 这是 iOS 的设计限制，不是实现问题。iOS 上的替代品是小组件 + 快捷指令。

---

## 七、云 Mac / GitHub Actions（不用买也不用借 Mac）

### 关键：云 Mac 接不到你的 iPhone

Xcode 要把 App 装进手机，需要**通过 USB 看见设备**——免费 Apple ID 的自动签名
更是要靠设备连着才能注册 UDID、生成描述文件。云 Mac 在机房里，USB 过不去。

所以云 Mac **不能**直接 Run 到你的手机。它的正确用法是**只负责编译**：

```
① 云 Mac：xcodebuild 编译出【未签名】的 .ipa      ← 不需要连手机
        ↓  下载 .ipa
② Windows + AltStore + 数据线连 iPhone：签名 + 安装  ← 这一步本地做
```

第 ② 步之所以能在 Windows 做，是因为 **AltStore / Sideloadly 自己会调苹果的接口**
完成签名和设备注册，不需要 Xcode。

### 路线 1：GitHub Actions（免费，推荐）

公开仓库的 **macOS 运行器不要钱**。工作流我已经写好了：
`.github/workflows/build-ipa.yml`

```bash
# 1. 在 GitHub 建一个仓库，把这个目录推上去
cd budget-ios
git remote add origin https://github.com/你的用户名/budget-ios.git
git push -u origin master

# 2. 浏览器打开仓库 → Actions 标签页
#    → 左侧选 "Build unsigned IPA" → 右侧 Run workflow

# 3. 等 3~5 分钟，页面底部 Artifacts 下载
#    BudgetAssistant-unsigned-ipa.zip
```

如果编译报错，日志会直接显示在 Actions 页面里——**把红字发我，我改**。

### 路线 2：租一台云 Mac（要图形界面时）

按小时计费的云 Mac（MacinCloud、MacStadium、AWS EC2 Mac 等，几美元/小时）。
连上去之后：

```bash
cd budget-ios
bash scripts/build-unsigned-ipa.sh
```

这个脚本也是我写好的，会：检查 Xcode → 用 XcodeGen 生成工程 → 编译（不签名）
→ 打包成 `dist/BudgetAssistant-unsigned.ipa`。

> 云 Mac 上装 Xcode 比较慢（几个 GB），租之前先确认机器上已经装好。
> 如果只是要编译，GitHub Actions 更快也更省事。

### 回到 Windows 装进 iPhone

1. 下载 [AltServer](https://altstore.io/)（Windows 版），iPhone 上装 AltStore
2. iPhone 用数据线连上电脑
3. AltStore 里用你的 **免费 Apple ID** 登录
4. 把下载来的 `.ipa` 拖进 AltStore → 它会自动签名并安装
5. iPhone 上：**设置 → 通用 → VPN与设备管理 → 信任**

装好后 7 天要重签一次（AltStore 会提醒，同一个 Wi-Fi 下能自动续）。

### ⚠️ 这条链子上还没被验证的两点

1. **AltStore 能否接受完全未签名的 ipa** —— 它的本职就是重签名，理论上可以，
   但没实测过。**不行的话换 Sideloadly 试**（同为免费的 Windows 侧载工具）。
2. **小组件可能装不上** —— 组件要靠 App Groups 与主 App 共享数据，
   免费 Apple ID 给不给这个权限不确定。
   **建议第一次先只编译主 App**（把 project.yml 里 BudgetWidget 的
   `dependencies` 和 target 注释掉），成功之后再试着加回小组件。

---

## 八、这个版本没有的东西

- 悬浮球 / 常驻通知（iOS 系统限制，见上）
- 快捷指令（Shortcuts）集成 —— 可以后续加，能实现「嘿 Siri，记一笔」
- iCloud 同步 —— 需要付费开发者账号
- 数据导入导出

需要的话告诉我，接着加。
