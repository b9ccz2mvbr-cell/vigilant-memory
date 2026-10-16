import SwiftUI

@main
struct BudgetAssistantApp: App {
    @StateObject private var store = BudgetStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}

/// 首次设置 / 入口页 二选一
///
/// ⚠️ 背景不能用 ZStack 包（ZStack 会被极光背景里的大圆撑宽，
/// 导致内容比屏幕宽、左右被切）。用 .background() —— 它不参与主视图的尺寸计算。
struct RootView: View {
    @EnvironmentObject var store: BudgetStore

    var body: some View {
        Group {
            if store.configured {
                HomeView()
            } else {
                SetupView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GlowBackground().ignoresSafeArea())
        .animation(.easeInOut(duration: 0.35), value: store.configured)
        .onAppear {
            // 灵动岛实时活动最长 8 小时会被系统结束，且重启后不会自动恢复。
            // App 没法在后台自己续期，只能在每次被打开时补上。
            LiveActivityBridge.resumeIfNeeded()
        }
    }
}
