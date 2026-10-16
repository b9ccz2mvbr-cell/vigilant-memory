import Foundation

/// 预警阈值。集中放一处，改数字只改这里。
///
/// 两类预警：
///  1. **单笔**其他池消费超过 `singleOtherWarn` 元 → 确认一下
///  2. **月度总消费**占到月度总额的 60% / 80% / 100% → 逐级加重
enum Alerts {

    /// 其他池单笔预警线
    static let singleOtherWarn: Double = 200

    /// 月度用量预警线
    static let monthWatchRatio: Double = 0.60
    static let monthWarnRatio: Double = 0.80

    enum Level {
        case none
        case watch   // 60% 起：提个醒
        case warn    // 80% 起：明显警示
        case over    // 100%：超支
    }

    static func monthRatio(spent: Double, monthlyTotal: Double) -> Double {
        monthlyTotal <= 0 ? 0 : spent / monthlyTotal
    }

    static func monthLevel(spent: Double, monthlyTotal: Double) -> Level {
        guard monthlyTotal > 0 else { return .none }
        let r = monthRatio(spent: spent, monthlyTotal: monthlyTotal)
        if r >= 1.0 { return .over }
        if r >= monthWarnRatio { return .warn }
        if r >= monthWatchRatio { return .watch }
        return .none
    }

    static func isSingleOtherAlarming(_ amount: Double) -> Bool {
        amount > singleOtherWarn
    }
}
