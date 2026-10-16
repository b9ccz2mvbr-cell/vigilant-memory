import Foundation

/// 读出 App 自己的描述文件（embedded.mobileprovision），列出里面实际带了哪些权限。
///
/// 为什么要这个：实时活动（ActivityKit）需要描述文件里有对应能力。
/// 侧载工具重新签名时用的是它自己申请的临时描述文件 —— 里面有没有这一项，
/// 只有真读了才知道。这个类就是干这个的，免得靠猜。
enum EntitlementInspector {

    struct Result {
        var profileFound: Bool = false
        var teamName: String?
        var appIDName: String?
        var expiration: Date?
        var entitlements: [String] = []
        var hasActivityKit: Bool = false
        var rawKeys: String = ""
    }

    static func inspect() -> Result {
        var r = Result()

        guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
              let data = FileManager.default.contents(atPath: path) else {
            return r
        }
        r.profileFound = true

        // mobileprovision 是 CMS 签名包着的 plist，前后有二进制垃圾，
        // 靠 <?xml ... </plist> 把中间的 plist 抠出来。
        guard let text = String(data: data, encoding: .isoLatin1),
              let start = text.range(of: "<?xml"),
              let end = text.range(of: "</plist>") else {
            return r
        }
        let plistStr = String(text[start.lowerBound..<end.upperBound])
        guard let plistData = plistStr.data(using: .isoLatin1),
              let plist = try? PropertyListSerialization.propertyList(
                  from: plistData, options: [], format: nil) as? [String: Any] else {
            return r
        }

        r.teamName = plist["TeamName"] as? String
        r.appIDName = plist["AppIDName"] as? String
        r.expiration = plist["ExpirationDate"] as? Date

        if let ent = plist["Entitlements"] as? [String: Any] {
            r.entitlements = ent.keys.sorted()
            r.rawKeys = r.entitlements.joined(separator: "\n")

            // 实时活动相关的键，不同 iOS 版本名字略有差异，都查一遍
            let keywords = ["activitykit", "ActivityKit", "liveactivity", "LiveActivity"]
            r.hasActivityKit = r.entitlements.contains { key in
                keywords.contains { key.localizedCaseInsensitiveContains($0) }
            }
        }
        return r
    }
}
