import Foundation
import ActivityKit

/// 灵动岛 / 锁屏实时活动的控制器。
///
/// 放在 Shared/ 是因为 `BudgetStore` 存完记录后要顺手刷新它。
/// 主 App 的「小组件与灵动岛」页面用它来启动 / 关闭。
///
/// ⚠️ iOS 的硬限制：
///  - 实时活动最长存活 8 小时，之后系统自动移除
///  - 必须由 App 主动启动；关机重启后不会自己恢复
///  - 灵动岛固定在屏幕顶部，不能浮在其他 App 上（安卓那种悬浮球做不到）
enum LiveActivityBridge {

    /// 系统是否允许实时活动（用户在设置里可以全局关闭）
    static var isEnabledBySystem: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// 当前有没有在跑
    static var isRunning: Bool {
        !Activity<BudgetActivityAttributes>.activities.isEmpty
    }

    /// 启动。返回是否成功；失败时抛出可读的错误。
    @discardableResult
    static func start() throws -> Bool {
        guard isEnabledBySystem else {
            throw LiveActivityError.disabledInSettings
        }
        guard let snap = BudgetStore.shared.snapshot() else {
            throw LiveActivityError.notConfigured
        }
        // 已经有一个就不重复开
        guard !isRunning else {
            update()
            return true
        }

        let attributes = BudgetActivityAttributes(startDate: Date())
        let state = BudgetActivityAttributes.ContentState(
            dailyRemaining: snap.daily.remaining,
            dailyQuota: snap.daily.quota,
            otherRemaining: snap.other.remaining,
            updatedAt: Date()
        )
        _ = try Activity.request(
            attributes: attributes,
            contentState: state,
            pushType: nil          // 本地更新，不需要推送（免费账号也能用）
        )
        isPreferred = true
        return true
    }

    /// 用最新数据刷新（记完一笔后调用）
    static func update() {
        guard isRunning, let snap = BudgetStore.shared.snapshot() else { return }
        let state = BudgetActivityAttributes.ContentState(
            dailyRemaining: snap.daily.remaining,
            dailyQuota: snap.daily.quota,
            otherRemaining: snap.other.remaining,
            updatedAt: Date()
        )
        Task {
            for activity in Activity<BudgetActivityAttributes>.activities {
                await activity.update(using: state)
            }
        }
    }

    /// 结束并立即从灵动岛移除
    static func stop() {
        isPreferred = false
        Task {
            for activity in Activity<BudgetActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: - 「每次打开 App 自动续期」

    private static let prefKey = "budget.liveActivityPreferred"

    /// 用户是否希望常驻（记在 App Group 里，重启 App 也能记住）
    static var isPreferred: Bool {
        get { UserDefaults(suiteName: BudgetStore.appGroupID)?.bool(forKey: prefKey) ?? false }
        set { UserDefaults(suiteName: BudgetStore.appGroupID)?.set(newValue, forKey: prefKey) }
    }

    /// App 启动时调用：如果用户之前开着、且系统没被禁、且当前没在跑，就重新拉起来。
    ///
    /// 为什么需要这个：iOS 的实时活动**最长 8 小时**就会被系统结束，
    /// 且重启手机后不会自动恢复。App 没法在后台自己续，只能在每次被打开时补上。
    static func resumeIfNeeded() {
        guard isPreferred, isEnabledBySystem, !isRunning else { return }
        try? start()
    }
}

enum LiveActivityError: LocalizedError {
    case disabledInSettings
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .disabledInSettings:
            return "系统里关闭了「实时活动」。去 设置 → 预算助手 → 实时活动 打开后再试。"
        case .notConfigured:
            return "还没完成首次设置，先设置额度再启动。"
        }
    }
}
