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
struct RootView: View {
    @EnvironmentObject var store: BudgetStore

    var body: some View {
        ZStack {
            GlowBackground()
            if store.configured {
                HomeView()
                    .transition(.opacity)
            } else {
                SetupView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: store.configured)
    }
}
