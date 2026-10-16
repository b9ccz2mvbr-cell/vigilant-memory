import SwiftUI

/// 配色与安卓版 / PWA 版保持一致。
///
/// 放在 Shared/ 是因为**主 App 和小组件扩展都要用**——
/// 小组件 target 不包含 Theme.swift，所以调色板必须在这里。
enum AppColor {
    static let bg = Color(hex: 0x0A0E14)
    static let surface = Color(hex: 0x131A24)
    static let card = Color.white.opacity(0.08)
    static let cardHi = Color.white.opacity(0.12)
    static let line = Color.white.opacity(0.10)
    static let ink = Color(hex: 0xEAF0F6)
    static let ink2 = Color(hex: 0x93A2B4)
    static let ink3 = Color(hex: 0x5D6B7C)
    static let brand = Color(hex: 0x4FD1C5)
    static let brandHi = Color(hex: 0x6FE3D6)
    static let brandDark = Color(hex: 0x3EC3B6)
    static let accent2 = Color(hex: 0x7C9CFF)
    static let warn = Color(hex: 0xF5C451)
    static let danger = Color(hex: 0xFF6B6B)
    static let onBrand = Color(hex: 0x04231F)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
