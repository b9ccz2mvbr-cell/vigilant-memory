import SwiftUI

// 配色定义在 Shared/AppPalette.swift —— 小组件扩展也要用，
// 而小组件 target 不包含本文件。

/// 深空底 + 三处极光辉光，对应 PWA / 安卓的 bg_glow
///
/// ⚠️ 必须用 GeometryReader 包住。
/// 早期版本直接把 620pt 的圆放进 ZStack，而 **ZStack 会按最大的子视图撑开**，
/// 于是整个界面被撑到 620pt 宽（iPhone 屏幕只有 393pt），内容左右被切掉。
/// GeometryReader 只接受外部给的尺寸、不把子视图尺寸向上传递，所以撑不破布局。
struct GlowBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                AppColor.bg
                glow(AppColor.brand.opacity(0.18), size: 620)
                    .position(x: geo.size.width * 0.12, y: geo.size.height * 0.10)
                glow(AppColor.accent2.opacity(0.15), size: 560)
                    .position(x: geo.size.width * 0.98, y: geo.size.height * 0.06)
                glow(AppColor.warn.opacity(0.08), size: 480)
                    .position(x: geo.size.width * 0.28, y: geo.size.height * 0.92)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }

    private func glow(_ color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(colors: [color, color.opacity(0)],
                                 center: .center,
                                 startRadius: 0,
                                 endRadius: size / 2))
            .frame(width: size, height: size)
            .blur(radius: 20)
            .allowsHitTesting(false)
    }
}

/// 玻璃卡片
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    var radius: CGFloat = 22
    var borderColor: Color? = nil
    var fill: Color? = nil
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill ?? AppColor.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(borderColor ?? AppColor.line, lineWidth: 1)
            )
    }
}

/// 青色渐变主按钮
struct PrimaryButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15.5, weight: .bold))
                .foregroundStyle(AppColor.onBrand)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(LinearGradient(colors: [AppColor.brandHi, AppColor.brandDark],
                                             startPoint: .top, endPoint: .bottom))
                )
        }
        .buttonStyle(.plain)
    }
}

/// 次级按钮
struct GhostButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15.5, weight: .semibold))
                .foregroundStyle(AppColor.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(AppColor.cardHi)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(AppColor.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

/// 小写间距拉开的 kicker
struct Kicker: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .bold))
            .tracking(2.8)
            .foregroundStyle(AppColor.brand)
    }
}
