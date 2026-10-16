import SwiftUI

/// 分类占比的环形图。
///
/// 用环形（中间留空）而不是实心饼：视觉上更轻，中间还能放合计金额。
/// 纯 SwiftUI Path 手绘 —— 不引入任何图表库。
struct DonutChart: View {

    struct Slice: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
    }

    let slices: [Slice]
    let centerText: String
    let centerSub: String

    /// 和圆图配色一致的调色板，明细列表的小圆点也用它
    static let palette: [Color] = [
        Color(hex: 0x4FD1C5),   // 品牌青
        Color(hex: 0x7C9CFF),   // 蓝
        Color(hex: 0xF5C451),   // 黄
        Color(hex: 0xFF9A6B),   // 橙
        Color(hex: 0xB48CFF),   // 紫
        Color(hex: 0x5BD1A0),   // 绿
        Color(hex: 0xFF6B8B),   // 粉
        Color(hex: 0x8FA3BF),   // 灰蓝
    ]

    static func color(at index: Int) -> Color {
        palette[index % palette.count]
    }

    private var total: Double { slices.reduce(0) { $0 + $1.value } }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let stroke = size * 0.16
            let radius = (size - stroke) / 2

            ZStack {
                // 底环
                Circle()
                    .stroke(Color(hex: 0x1A2230), lineWidth: stroke)
                    .frame(width: radius * 2, height: radius * 2)

                if total > 0 {
                    ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                        let start = startAngle(upTo: index)
                        let sweep = slice.value / total * 360

                        Circle()
                            .trim(from: start / 360 + gapFraction,
                                  to: (start + sweep) / 360 - gapFraction)
                            .stroke(Self.color(at: index),
                                    style: StrokeStyle(lineWidth: stroke, lineCap: .butt))
                            .rotationEffect(.degrees(-90))
                            .frame(width: radius * 2, height: radius * 2)
                    }

                    VStack(spacing: 2) {
                        Text(centerText)
                            .font(.system(size: size * 0.15, weight: .heavy))
                            .foregroundStyle(AppColor.ink)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        if !centerSub.isEmpty {
                            Text(centerSub)
                                .font(.system(size: size * 0.082))
                                .foregroundStyle(AppColor.ink3)
                        }
                    }
                    .frame(width: radius * 1.5)
                } else {
                    Text("还没有数据")
                        .font(.system(size: size * 0.13, weight: .semibold))
                        .foregroundStyle(AppColor.ink3)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// 扇区之间留一道细缝，边界更清楚
    private var gapFraction: CGFloat {
        slices.count > 1 ? (1.2 / 360) : 0
    }

    private func startAngle(upTo index: Int) -> Double {
        slices.prefix(index).reduce(0) { $0 + $1.value / total * 360 }
    }
}
