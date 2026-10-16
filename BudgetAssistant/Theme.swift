import SwiftUI

// ????? Shared/AppPalette.swift -- ????????,
// ???? target ???????

/// ??? + ??????,?? PWA / ??? bg_glow
///
/// ?? ??? GeometryReader ???
/// ??????? 620pt ???? ZStack,? **ZStack ??????????**,
/// ????????? 620pt ?(iPhone ???? 393pt),????????
/// GeometryReader ?????????????????????,????????
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

/// ????
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

/// ???????
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

/// ????
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

/// ??????? kicker
struct Kicker: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .bold))
            .tracking(2.8)
            .foregroundStyle(AppColor.brand)
    }
}
