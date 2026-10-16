import Foundation

// MARK: - 池与状态

/// 消费所属的池。规格 5.5：两池并列、互不占用。
enum Pool: String, Codable {
    case daily = "DAILY"
    case other = "OTHER"

    var label: String { self == .daily ? "日常开支" : "其他支出" }
}

/// 记录状态。规格 5.4：「我买了」扣减，「算了，不买了」计入忍住记录。
enum RecordStatus: String, Codable {
    case bought = "BOUGHT"
    case held = "HELD"

    var label: String { self == .bought ? "买了" : "忍住" }
}

// MARK: - 数据模型

struct BudgetRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var amount: Double
    var pool: Pool
    var status: RecordStatus
    var ts: Date

    // ---- 以下是「其他池」专属的可选信息 ----
    // 三个都是 Optional，所以**旧数据能直接解码**（缺字段 = nil），不用迁移。

    /// 分类：饰品 / 零食 / 日用品 / 宠物用品 / 电子设备 / 家具 / 手动输入…
    /// 列表在设置里可编辑，见 CategoryStore。
    var category: String?

    /// 备注
    var note: String?

    /// 图片文件名（图片本身存在 App Group 容器的 images/ 目录里，不塞进 JSON）
    /// 可选 —— 不存图片完全没问题
    var imageFile: String?
}

struct BudgetConfig: Codable {
    var monthlyTotal: Double
    var dailyBudget: Double
    var monthStartDay: Int = 1
}

// MARK: - 计算快照

struct PoolState {
    let pool: Pool
    let quota: Double
    let spent: Double

    var remaining: Double { quota - spent }
    var overspent: Bool { remaining < 0 }
    var usedRatio: Double { quota <= 0 ? 0 : min(1, max(0, spent / quota)) }
    var label: String { pool.label }
}

struct Snapshot {
    let daily: PoolState
    let other: PoolState
    let monthlyTotal: Double
    let daysInPeriod: Int

    /// 规格 5.5：两池合计超支 → 全局警告
    var globalOverspent: Bool { daily.spent + other.spent > monthlyTotal }
}

// MARK: - 金额格式化

enum Money {

    /// 与规格里的 ¥32 / ¥872 / ¥3000 口径一致
    static func format(_ value: Double) -> String {
        let r = (value * 100).rounded() / 100
        if r == r.rounded() {
            return "¥\(Int(r))"
        }
        var s = String(format: "%.2f", r)
        while s.hasSuffix("0") { s.removeLast() }
        if s.hasSuffix(".") { s.removeLast() }
        return "¥\(s)"
    }

    /// 日历格子里的紧凑金额：32 / 1.2k
    static func short(_ value: Double) -> String {
        let r = (value * 10).rounded() / 10
        if r >= 1000 {
            return String(format: r >= 10000 ? "%.0fk" : "%.1fk", r / 1000)
        }
        return r == r.rounded() ? "\(Int(r))" : String(format: "%.1f", r)
    }

    static func parse(_ raw: String) -> Double? {
        let t = raw.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, let v = Double(t), v >= 0 else { return nil }
        return v
    }
}
