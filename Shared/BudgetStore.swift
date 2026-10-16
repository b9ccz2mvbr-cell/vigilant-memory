import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// 数据层：UserDefaults 存 JSON。
///
/// 刻意不引入 SwiftData / Core Data —— 记录量很小（个人记账），JSON 足够，
/// 而且能在 App 与小组件扩展之间直接共享。
///
/// ⚠️ App Group：`group.com.example.budget` 必须在**主 App 和小组件扩展**
/// 两个 target 的 Signing & Capabilities 里都勾上，否则小组件读不到数据。
/// 如果免费 Apple ID 不给 App Groups 权限，会自动退回标准 UserDefaults
/// （App 本身照常工作，只是小组件拿不到数据）。
final class BudgetStore: ObservableObject {

    static let appGroupID = "group.com.example.budget"
    static let shared = BudgetStore()

    @Published private(set) var config: BudgetConfig?
    @Published private(set) var records: [BudgetRecord] = []

    private let defaults: UserDefaults
    private let kConfig = "budget.config"
    private let kRecords = "budget.records"

    /// 是否成功用上了 App Group（决定小组件能不能拿到数据）
    let usingAppGroup: Bool

    init() {
        if let group = UserDefaults(suiteName: Self.appGroupID) {
            defaults = group
            usingAppGroup = true
        } else {
            defaults = .standard
            usingAppGroup = false
        }
        load()
    }

    var configured: Bool { config != nil }

    // MARK: - 读写

    func load() {
        let dec = JSONDecoder()
        if let data = defaults.data(forKey: kConfig) {
            config = try? dec.decode(BudgetConfig.self, from: data)
        }
        if let data = defaults.data(forKey: kRecords) {
            records = (try? dec.decode([BudgetRecord].self, from: data)) ?? []
        }
    }

    private func persist() {
        let enc = JSONEncoder()
        if let config, let data = try? enc.encode(config) {
            defaults.set(data, forKey: kConfig)
        }
        if let data = try? enc.encode(records) {
            defaults.set(data, forKey: kRecords)
        }
        refreshWidgets()
    }

    func saveConfig(_ cfg: BudgetConfig) {
        config = cfg
        persist()
    }

    /// 记一笔。
    ///
    /// `category` / `note` / `imageFile` 只对**其他池**有意义，都是可选的：
    /// 不传图、不写备注完全没问题。
    func addRecord(amount: Double,
                   pool: Pool,
                   status: RecordStatus,
                   at date: Date = Date(),
                   category: String? = nil,
                   note: String? = nil,
                   imageFile: String? = nil) {
        var r = BudgetRecord(amount: amount, pool: pool, status: status, ts: date)
        if pool == .other {
            r.category = category?.isEmpty == true ? nil : category
            r.note = note?.isEmpty == true ? nil : note
            r.imageFile = imageFile
        }
        records.append(r)
        persist()
    }

    func deleteRecord(id: UUID) {
        if let img = records.first(where: { $0.id == id })?.imageFile {
            ImageStore.delete(img)      // 顺手把图删掉，别留孤儿文件
        }
        records.removeAll { $0.id == id }
        persist()
    }

    /// 更新某条记录的分类 / 备注 / 图片
    func updateRecord(id: UUID,
                      category: String? = nil,
                      note: String? = nil,
                      imageFile: String? = nil) {
        guard let i = records.firstIndex(where: { $0.id == id }) else { return }
        records[i].category = category?.isEmpty == true ? nil : category
        records[i].note = note?.isEmpty == true ? nil : note
        records[i].imageFile = imageFile
        persist()
    }

    /// 某个分类在本周期内花了多少（给统计用）
    func spent(inCategory category: String, from: Date, to: Date) -> Double {
        records.reduce(0) { acc, r in
            guard r.pool == .other, r.status == .bought, r.category == category else { return acc }
            guard r.ts >= from, r.ts < to else { return acc }
            return acc + r.amount
        }
    }

    /// 按分类聚合（从多到少），给统计页的环形图和明细列表用。
    /// 只算**其他池 + 已买 + 有分类**的记录 —— 和记账时的口径一致。
    func categoryTotals(from: Date, to: Date) -> [(category: String, total: Double)] {
        var acc: [String: Double] = [:]
        for r in records {
            guard r.pool == .other, r.status == .bought else { continue }
            guard let c = r.category, !c.isEmpty else { continue }
            guard r.ts >= from, r.ts < to else { continue }
            acc[c, default: 0] += r.amount
        }
        return acc.map { (category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    /// 统计页的时间范围
    func range(_ scope: StatScope, at date: Date = Date()) -> (from: Date, to: Date) {
        let anchor = config?.monthStartDay ?? 1
        switch scope {
        case .day:
            return (BudgetClock.dayStart(date), BudgetClock.dayEnd(date))
        case .month:
            return (BudgetClock.periodStart(date, monthStartDay: anchor),
                    BudgetClock.periodEnd(date, monthStartDay: anchor))
        case .year:
            return (BudgetClock.yearStart(date), BudgetClock.yearEnd(date))
        }
    }

    func clearAll() {
        // 先删图片再清数据
        for name in records.compactMap({ $0.imageFile }) {
            ImageStore.delete(name)
        }
        config = nil
        records = []
        defaults.removeObject(forKey: kConfig)
        defaults.removeObject(forKey: kRecords)
        refreshWidgets()
    }

    private func refreshWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        // 记完一笔顺手刷新灵动岛 / 锁屏实时活动
        LiveActivityBridge.update()
    }

    // MARK: - 双池计算

    /// 规格 5.4 智能预选：< ¥60 归日常，≥ ¥60 归其他
    static func suggestPool(for amount: Double) -> Pool {
        amount < 60 ? .daily : .other
    }

    func spent(in pool: Pool, from: Date, to: Date) -> Double {
        records.reduce(0) { acc, r in
            guard r.pool == pool, r.status == .bought else { return acc }
            guard r.ts >= from, r.ts < to else { return acc }
            return acc + r.amount
        }
    }

    func snapshot(at date: Date = Date()) -> Snapshot? {
        guard let cfg = config else { return nil }

        let days = BudgetClock.daysInPeriod(date, monthStartDay: cfg.monthStartDay)
        let dFrom = BudgetClock.dayStart(date)
        let dTo = BudgetClock.dayEnd(date)
        let pFrom = BudgetClock.periodStart(date, monthStartDay: cfg.monthStartDay)
        let pTo = BudgetClock.periodEnd(date, monthStartDay: cfg.monthStartDay)

        // 其他池额度 = 月度总额 − 单日预算 × 天数（两池合计恒等于月度总额）
        let otherQuota = max(0, cfg.monthlyTotal - cfg.dailyBudget * Double(days))

        return Snapshot(
            daily: PoolState(pool: .daily,
                             quota: cfg.dailyBudget,
                             spent: spent(in: .daily, from: dFrom, to: dTo)),
            other: PoolState(pool: .other,
                             quota: otherQuota,
                             spent: spent(in: .other, from: pFrom, to: pTo)),
            monthlyTotal: cfg.monthlyTotal,
            daysInPeriod: days
        )
    }

    /// 本月忍住统计
    func heldStats(at date: Date = Date()) -> (count: Int, total: Double) {
        let anchor = config?.monthStartDay ?? 1
        let from = BudgetClock.periodStart(date, monthStartDay: anchor)
        let to = BudgetClock.periodEnd(date, monthStartDay: anchor)
        var count = 0
        var total = 0.0
        for r in records where r.status == .held && r.ts >= from && r.ts < to {
            count += 1
            total += r.amount
        }
        return (count, total)
    }

    /// 日历用：按预算日归组
    func groupByDay() -> [Date: (daily: Double, other: Double, list: [BudgetRecord])] {
        var map: [Date: (daily: Double, other: Double, list: [BudgetRecord])] = [:]
        for r in records {
            let k = BudgetClock.dayStart(r.ts)
            var entry = map[k] ?? (0, 0, [])
            if r.status == .bought {
                if r.pool == .daily { entry.daily += r.amount } else { entry.other += r.amount }
            }
            entry.list.append(r)
            map[k] = entry
        }
        return map
    }
}
