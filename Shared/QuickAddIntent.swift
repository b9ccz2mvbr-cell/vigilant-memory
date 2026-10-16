import AppIntents
import Foundation

/// 灵动岛展开面板里的快捷按钮。
///
/// 放在 Shared/ 是因为**必须编译进小组件扩展**——
/// 灵动岛和锁屏的实时活动界面属于扩展进程，按钮的 intent 要在那儿执行。
///
/// 用法：`Button(intent: QuickAddIntent(amount: 20)) { ... }`
/// 前提：iOS 17+ 的 `Button(intent:)`（我们的小组件 target 就是 17.0）。
struct QuickAddIntent: AppIntent {
    static var title: LocalizedStringResource = "快速记一笔"
    static var description = IntentDescription("从日常池扣掉一笔钱，不用打开 App。")

    /// 不打开 App —— 在扩展进程里静默完成
    static var openAppWhenRun: Bool = false

    @Parameter(title: "金额")
    var amount: Double

    init() {}

    init(amount: Double) {
        self.amount = amount
    }

    func perform() async throws -> some IntentResult {
        BudgetStore.shared.addRecord(amount: amount, pool: .daily, status: .bought)
        // addRecord 内部会调 LiveActivityBridge.update()，面板上的数字随即刷新
        return .result()
    }
}

/// 展开面板里的「打开记账」按钮
struct OpenBudgetIntent: AppIntent {
    static var title: LocalizedStringResource = "打开记账"
    static var description = IntentDescription("打开预算助手。")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
