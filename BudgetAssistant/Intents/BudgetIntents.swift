import AppIntents
import Foundation

/// 快捷指令（Shortcuts）支持 —— 让「背部轻点」「Siri」「快捷指令 App」都能调起记账。
///
/// 配置背部轻点：
///   设置 → 辅助功能 → 触控 → 拉到底「轻点背面」→ 轻点两下 → 选「快捷指令」→ 选本 App 的指令
///
/// 说明：iOS 不允许 App 自动把自己加到快捷指令里，所以这一步要用户手动配置一次。
/// App 内「小组件与灵动岛」页面提供了引导。

// MARK: - 记一笔（后台直接完成，不打开 App）

struct RecordSpendingIntent: AppIntent {
    static var title: LocalizedStringResource = "记一笔"
    static var description = IntentDescription(
        "直接记一笔支出，不用打开 App。可指定金额和从哪个池扣。"
    )

    @Parameter(title: "金额", description: "要记录的金额")
    var amount: Double

    @Parameter(title: "从日常池扣", description: "打开则记入日常池，关闭则记入其他池", default: true)
    var fromDaily: Bool

    /// 不打开 App —— 后台静默完成，这就是「零点击」的关键
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let pool: Pool = fromDaily ? .daily : .other
        BudgetStore.shared.addRecord(amount: amount, pool: pool, status: .bought)

        let snap = BudgetStore.shared.snapshot()
        let left = pool == .daily ? (snap?.daily.remaining ?? 0) : (snap?.other.remaining ?? 0)
        return .result(dialog: "已记 \(Money.format(amount))，\(pool.label)还剩 \(Money.format(left))")
    }
}

// MARK: - 打开记账（跳到 App）

struct OpenBudgetIntent: AppIntent {
    static var title: LocalizedStringResource = "打开记账"
    static var description = IntentDescription("打开预算助手。")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

// MARK: - 暴露给 Siri / 快捷指令 / 轻点背面

struct BudgetShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordSpendingIntent(),
            phrases: [
                "用 \(.applicationName) 记一笔",
                "\(.applicationName) 记账",
            ],
            shortTitle: "记一笔",
            systemImageName: "yensign.circle.fill"
        )
        AppShortcut(
            intent: OpenBudgetIntent(),
            phrases: [
                "打开 \(.applicationName)",
                "\(.applicationName) 记账页",
            ],
            shortTitle: "打开记账",
            systemImageName: "square.and.pencil"
        )
    }
}
