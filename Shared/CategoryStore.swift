import Foundation

/// 「其他池」的分类列表 —— 可在设置里增删改。
///
/// 默认七项，顺序就是用户要求的顺序（从上到下）：
///   饰品 / 零食 / 日用品 / 宠物用品 / 电子设备 / 家具 / 手动输入
enum CategoryStore {

    static let defaultCategories: [String] = [
        "饰品", "零食", "日用品", "宠物用品", "电子设备", "家具", "手动输入",
    ]

    private static let key = "budget.categories"
    private static let orderKey = "budget.otherOrder"   // 预留

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: BudgetStore.appGroupID)
    }

    /// 当前生效的分类列表；没设置过就用默认的
    static var categories: [String] {
        get {
            guard let arr = defaults?.stringArray(forKey: key), !arr.isEmpty else {
                return defaultCategories
            }
            return arr
        }
        set {
            let cleaned = sanitize(newValue)
            defaults?.set(cleaned, forKey: key)
        }
    }

    /// 恢复默认
    static func reset() {
        defaults?.removeObject(forKey: key)
    }

    /// 去掉空项、去重，但**保留用户排的顺序**
    static func sanitize(_ list: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for raw in list {
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !seen.contains(name) else { continue }
            seen.insert(name)
            out.append(name)
        }
        return out.isEmpty ? defaultCategories : out
    }

    /// 「手动输入」这一项是用户自己打字用的，不是一个真正的分类标签
    static let manualEntryTitle = "手动输入"

    static func isManualEntry(_ name: String) -> Bool {
        name == manualEntryTitle
    }
}
