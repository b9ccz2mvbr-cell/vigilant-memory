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

    // MARK: - 年度口径（统计页的「年度」用）

    /// 该时刻所属「预算年」的起点：当年 1 月 1 日的 4:00
    static func yearStart(_ date: Date) -> Date {
        let c = cal
        let boundary = dayStart(date)
        var comps = c.dateComponents([.year], from: boundary)
        comps.month = 1
        comps.day = 1
        comps.hour = dayStartHour
        comps.minute = 0
        comps.second = 0
        return c.date(from: comps) ?? boundary
    }

    /// 年度终点（次年 1 月 1 日 4:00），左闭右开
    static func yearEnd(_ date: Date) -> Date {
        cal.date(byAdding: .year, value: 1, to: yearStart(date)) ?? date
    }
}

/// 统计页的时间范围。日度用 4:00 日界，月度按配置的每月起始日，年度按自然年。
///
/// 三者都走 BudgetClock —— **同一笔钱在哪儿都归同一天**。
enum StatScope: String, CaseIterable, Identifiable {
    case day = "日度"
    case month = "月度"
    case year = "年度"

    var id: String { rawValue }
    var label: String { rawValue }
}
