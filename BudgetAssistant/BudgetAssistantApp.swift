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

/// ???? / ??? ???
///
/// ?? ????? ZStack ?(ZStack ????????????,
/// ?????????????)?? .background() -- ?????????????
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
    }
}
