import SwiftUI
import ActivityKit

/// 「小组件与灵动岛」——App 内的操作与引导页。
///
/// iOS 不允许 App 自动把小组件放上桌面，也不允许 App 自己加进快捷指令，
/// 所以这一页做三件事：
///   1. 灵动岛：一个开关直接启动 / 关闭（这个能真做）
///   2. 小组件：分步图文引导（用户手动加）
///   3. 背部轻点：说明 + 跳转设置（用户手动配）
struct WidgetGuideView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    @State private var liveRunning = false
    @State private var message: String?
    @State private var isError = false
    @State private var refreshTimer: Timer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // ---------- 灵动岛 ----------
                    sectionTitle("灵动岛 / 锁屏实时活动", icon: "capsule.portrait")

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(liveRunning ? "正在显示" : "未启动")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(liveRunning ? AppColor.brand : AppColor.ink)
                                    Text(liveRunning
                                         ? "灵动岛和锁屏上能看到今日剩余"
                                         : "打开后，今日剩余会常驻在灵动岛")
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppColor.ink3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { liveRunning },
                                    set: { newValue in newValue ? startLive() : stopLive() }
                                ))
                                .labelsHidden()
                                .tint(AppColor.brand)
                            }

                            if let message {
                                Text(message)
                                    .font(.system(size: 12))
                                    .foregroundStyle(isError ? AppColor.danger : AppColor.brand)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    note("⚠️ iOS 的限制：实时活动**最长 8 小时**，之后系统会自动移除；"
                         + "我把它做成了「每次打开 App 自动续期」，所以你每天用的时候它都会在。")

                    // ---------- 小组件 ----------
                    sectionTitle("桌面 / 锁屏小组件", icon: "square.grid.2x2")

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            step(1, "回到 iPhone 桌面，**长按空白处**")
                            step(2, "点左上角的 **「+」** 按钮")
                            step(3, "搜索 **「预算余额」**（或「预算助手」）")
                            step(4, "选尺寸 → 点「添加小组件」")
                            Divider().overlay(AppColor.line)
                            Text("锁屏也能加：长按锁屏 → 自定义 → 添加小组件 → 搜「预算余额」")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColor.ink3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    note("iOS 不允许 App 替你把小组件放上桌面——这是系统的安全设计，"
                         + "所有 App 都一样，只能手动加一次。")

                    // ---------- 背部轻点 ----------
                    sectionTitle("背部轻点（零点击记账）", icon: "hand.tap")

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("配置好之后，**敲两下手机背面**就能记一笔，不用打开 App。")
                                .font(.system(size: 13))
                                .foregroundStyle(AppColor.ink2)
                                .fixedSize(horizontal: false, vertical: true)
                            Divider().overlay(AppColor.line)
                            step(1, "打开 **设置 → 辅助功能 → 触控**")
                            step(2, "拉到最底，点 **「轻点背面」**")
                            step(3, "选 **「轻点两下」** → 往下找 **「快捷指令」**")
                            step(4, "选 **「记一笔」** 或 **「打开记账」**")
                        }
                    }

                    Button {
                        openSettings()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.forward.app")
                            Text("打开「设置」App")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.brand)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(RoundedRectangle(cornerRadius: 13).fill(AppColor.card))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppColor.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)

                    note("iOS 也不允许 App 自动把自己加进快捷指令，所以这一步要你手动配一次，"
                         + "配完就永久生效了。")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(GlowBackground().ignoresSafeArea())
            .navigationTitle("小组件与灵动岛")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }.foregroundStyle(AppColor.brand)
                }
            }
        }
        .onAppear {
            refreshLiveState()
            // 页面开着的时候轮询一下，因为实时活动可能被系统自动结束
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                refreshLiveState()
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }

    // MARK: - 行为

    private func refreshLiveState() {
        let running = LiveActivityBridge.isRunning
        if running != liveRunning { liveRunning = running }
    }

    private func startLive() {
        do {
            try LiveActivityBridge.start()
            message = "已启动，去锁屏或灵动岛看看"
            isError = false
        } catch {
            message = error.localizedDescription
            isError = true
        }
        refreshLiveState()
    }

    private func stopLive() {
        LiveActivityBridge.stop()
        message = "已关闭"
        isError = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { refreshLiveState() }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - 小组件

    private func sectionTitle(_ text: String, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.brand)
            Text(text)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColor.ink)
        }
        .padding(.top, 22)
        .padding(.bottom, 10)
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Text("\(n)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColor.onBrand)
                .frame(width: 18, height: 18)
                .background(Circle().fill(AppColor.brand))
            Text(.init(text))
                .font(.system(size: 13))
                .foregroundStyle(AppColor.ink2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func note(_ text: String) -> some View {
        Text(.init(text))
            .font(.system(size: 11.5))
            .foregroundStyle(AppColor.ink3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 12)
    }
}
