import Foundation
import ActivityKit

/// 灵动岛 / 锁屏实时活动（Live Activity）的数据结构。
///
/// 放在 Shared/ 是因为**主 App 和小组件扩展都要用**：
/// App 负责启动 / 更新 / 结束，扩展负责渲染。
struct BudgetActivityAttributes: ActivityAttributes {

    /// 会随时间变化的部分
    public struct ContentState: Codable, Hashable {
        /// 今日日常池剩余
        var dailyRemaining: Double
        /// 今日日常池额度
        var dailyQuota: Double
        /// 本周期其他池剩余
        var otherRemaining: Double
        /// 上次更新时间（用于显示"刚刚更新"）
        var updatedAt: Date

        var dailyUsedRatio: Double {
            dailyQuota <= 0 ? 0 : min(1, max(0, (dailyQuota - dailyRemaining) / dailyQuota))
        }
        var dailyOverspent: Bool { dailyRemaining < 0 }
    }

    /// 活动开始时间（不变的部分）
    var startDate: Date
}
