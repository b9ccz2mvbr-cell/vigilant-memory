import Foundation

/// 预算时间口径。
///
/// 规格 5.5：日界为凌晨 4:00（4:00 之前的消费算前一天），日预算不累积。
/// 与安卓版 BudgetClock.kt、PWA 版 dayStart()、Flutter 版保持同一套口径。
enum BudgetClock {

    static let dayStartHour = 4

    private static var cal: Calendar { Calendar.current }

    /// 该时刻所属「预算日」的起点（当天 4:00）
    static func dayStart(_ date: Date) -> Date {
        let c = cal
        var comps = c.dateComponents([.year, .month, .day, .hour], from: date)
        let hour = comps.hour ?? 0
        comps.hour = dayStartHour
        comps.minute = 0
        comps.second = 0
        comps.nanosecond = 0
        var base = c.date(from: comps) ?? date
        if hour < dayStartHour {
            base = c.date(byAdding: .day, value: -1, to: base) ?? base
        }
        return base
    }

    /// 预算日终点（次日 4:00），左闭右开
    static func dayEnd(_ date: Date) -> Date {
        cal.date(byAdding: .day, value: 1, to: dayStart(date)) ?? date
    }

    /// 该时刻所属「预算周期」的起点，按 monthStartDay 起算
    static func periodStart(_ date: Date, monthStartDay: Int) -> Date {
        let c = cal
        let base = dayStart(date)
        let anchor = min(max(monthStartDay, 1), 28)

        var comps = c.dateComponents([.year, .month, .day], from: base)
        let day = comps.day ?? 1

        if day >= anchor {
            comps.day = anchor
        } else {
            let prev = c.date(byAdding: .month, value: -1, to: base) ?? base
            var pc = c.dateComponents([.year, .month], from: prev)
            pc.day = anchor
            comps = pc
        }
        comps.hour = dayStartHour
        comps.minute = 0
        comps.second = 0
        comps.nanosecond = 0
        return c.date(from: comps) ?? base
    }

    /// 周期终点（下个周期起点）
    static func periodEnd(_ date: Date, monthStartDay: Int) -> Date {
        let s = periodStart(date, monthStartDay: monthStartDay)
        return cal.date(byAdding: .month, value: 1, to: s) ?? s
    }

    /// 周期内的自然日数
    static func daysInPeriod(_ date: Date, monthStartDay: Int) -> Int {
        let c = cal
        let from = periodStart(date, monthStartDay: monthStartDay)
        let to = periodEnd(date, monthStartDay: monthStartDay)
        let days = c.dateComponents([.day], from: from, to: to).day ?? 1
        return max(1, days)
    }
}
