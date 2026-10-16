import SwiftUI

/// 分类支出统计：日度 / 月度 / 年度。
///
/// 上面是环形占比图，往下滑是逐项明细（金额 + 占比 + 进度条）。
/// 数据只统计**其他池**里「已买」且有分类的记录。
struct CategoryStatsView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    @State private var scope: StatScope = .month

    private var totals: [(category: String, total: Double)] {
        let (from, to) = store.range(scope)
        return store.categoryTotals(from: from, to: to)
    }

    private var sum: Double { totals.reduce(0) { $0 + $1.total } }

    var body: some View {
        ZStack {
            GlowBackground().ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    scopeTabs
                    rangeLabel

                    DonutChart(
                        slices: totals.map { DonutChart.Slice(label: $0.category, value: $0.total) },
                        centerText: Money.format(sum),
                        centerSub: "\(scope.label)合计"
                    )
                    .frame(height: 260)
                    .padding(.top, 4)

                    HStack {
                        Text("其他池合计")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColor.ink2)
                        Spacer()
                        Text(Money.format(sum))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppColor.accent2)
                    }

                    Divider().overlay(AppColor.line)

                    Text("逐项明细")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColor.ink)

                    if totals.isEmpty {
                        Text("这个区间还没有带分类的其他消费记录")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColor.ink3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else {
                        detailList
                    }

                    GhostButton(label: "完成") { dismiss() }
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
        }
        .navigationTitle("分类支出")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 组件

    private var header: some View {
        HStack {
            Text("分类支出")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(AppColor.ink)
            Spacer()
        }
    }

    private var scopeTabs: some View {
        HStack(spacing: 6) {
            ForEach(StatScope.allCases) { s in
                let active = s == scope
                Button { scope = s } label: {
                    Text(s.label)
                        .font(.system(size: 14, weight: active ? .bold : .regular))
                        .foregroundStyle(active ? AppColor.onBrand : AppColor.ink2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(
                            Group {
                                if active {
                                    RoundedRectangle(cornerRadius: 13)
                                        .fill(LinearGradient(colors: [AppColor.brandHi, AppColor.brandDark],
                                                             startPoint: .top, endPoint: .bottom))
                                } else {
                                    RoundedRectangle(cornerRadius: 13).fill(AppColor.card)
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(active ? .clear : AppColor.line, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var rangeLabel: some View {
        let (from, to) = store.range(scope)
        let end = Calendar.current.date(byAdding: .day, value: -1, to: to) ?? to
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        switch scope {
        case .day:
            f.dateFormat = "yyyy年M月d日"
            return Text(f.string(from: from))
                .font(.system(size: 12)).foregroundStyle(AppColor.ink3)
        case .month:
            f.dateFormat = "yyyy年M月d日"
            let md = DateFormatter()
            md.locale = Locale(identifier: "zh_CN")
            md.dateFormat = "M月d日"
            return Text("\(f.string(from: from)) — \(md.string(from: end))")
                .font(.system(size: 12)).foregroundStyle(AppColor.ink3)
        case .year:
            let y = Calendar.current.component(.year, from: from)
            let md = DateFormatter()
            md.locale = Locale(identifier: "zh_CN")
            md.dateFormat = "M月d日"
            return Text("\(y) 年 1 月 1 日 — \(md.string(from: end))")
                .font(.system(size: 12)).foregroundStyle(AppColor.ink3)
        }
    }

    private var detailList: some View {
        let maxValue = totals.map(\.total).max() ?? 0
        return VStack(spacing: 7) {
            ForEach(Array(totals.enumerated()), id: \.offset) { index, item in
                let pct = sum > 0 ? item.total / sum * 100 : 0
                let ratio = maxValue > 0 ? item.total / maxValue : 0
                let color = DonutChart.color(at: index)

                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 9) {
                        Circle()
                            .fill(color)
                            .frame(width: 10, height: 10)
                        Text(item.category)
                            .font(.system(size: 15))
                            .foregroundStyle(AppColor.ink)
                        Spacer()
                        Text(Money.format(item.total))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppColor.ink)
                        Text(String(format: "%.0f%%", pct))
                            .font(.system(size: 13))
                            .foregroundStyle(AppColor.ink2)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(AppColor.cardHi)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color)
                                .frame(width: max(4, geo.size.width * ratio))
                        }
                    }
                    .frame(height: 6)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(AppColor.card))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColor.line, lineWidth: 1))
            }
        }
    }
}
