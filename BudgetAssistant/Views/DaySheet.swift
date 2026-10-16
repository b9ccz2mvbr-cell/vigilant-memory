import SwiftUI

/// 单日明细：两个板块各占多少 + 当日记录分组
struct DaySheet: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    let dayKey: Date

    private var entry: (daily: Double, other: Double, list: [BudgetRecord]) {
        store.groupByDay()[dayKey] ?? (0, 0, [])
    }

    var body: some View {
        let e = entry
        let budget = store.config?.dailyBudget ?? 0
        let days = BudgetClock.daysInPeriod(Date(), monthStartDay: store.config?.monthStartDay ?? 1)
        let otherQuota = max(0, (store.config?.monthlyTotal ?? 0) - budget * Double(days))
        let overspent = budget > 0 && e.daily > budget

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 0) {
                        Kicker(text: dateTitle)
                        Text(Money.format(e.daily + e.other))
                            .font(.system(size: 32, weight: .heavy))
                            .tracking(-0.5)
                            .foregroundStyle(AppColor.ink)
                            .padding(.top, 8)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Text("✕")
                            .font(.system(size: 17))
                            .foregroundStyle(AppColor.ink2)
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 13).fill(AppColor.cardHi))
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppColor.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                // 两个板块
                HStack(spacing: 10) {
                    poolCard(
                        label: "日常开支",
                        amount: e.daily,
                        sub: "额度 \(Money.format(budget)) · 剩 \(Money.format(budget - e.daily))",
                        ratio: budget > 0 ? min(1, e.daily / budget) : 0,
                        color: overspent ? AppColor.danger : AppColor.brand
                    )
                    poolCard(
                        label: "其他支出",
                        amount: e.other,
                        sub: "占本月其他额度 \(otherQuota > 0 ? Int((e.other / otherQuota * 100).rounded()) : 0)%",
                        ratio: otherQuota > 0 ? min(1, e.other / otherQuota) : 0,
                        color: AppColor.accent2
                    )
                }
                .padding(.top, 16)

                // 记录分组
                let sorted = e.list.sorted { $0.ts < $1.ts }
                let dailyList = sorted.filter { $0.pool == .daily }
                let otherList = sorted.filter { $0.pool == .other }

                if dailyList.isEmpty && otherList.isEmpty {
                    Text("这一天没有记录")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColor.ink3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                } else {
                    if !dailyList.isEmpty {
                        groupTitle("日常开支")
                        ForEach(dailyList) { row($0) }
                    }
                    if !otherList.isEmpty {
                        groupTitle("其他支出")
                        ForEach(otherList) { row($0) }
                    }
                }

                Button("删除当天这条记录…") { }
                    .hidden()
            }
            .padding(20)
        }
        .background(
            LinearGradient(colors: [Color(hex: 0x131A24), Color(hex: 0x0E141C)],
                           startPoint: .top, endPoint: .bottom)
        )
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28,
                                          topTrailingRadius: 28,
                                          style: .continuous))
    }

    private var dateTitle: String {
        let c = Calendar.current.dateComponents([.month, .day, .weekday], from: dayKey)
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        let w = names[max(0, min(6, (c.weekday ?? 1) - 1))]
        return "\(c.month ?? 0) 月 \(c.day ?? 0) 日 · 周\(w)"
    }

    private func poolCard(label: String, amount: Double, sub: String,
                          ratio: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 11.5))
                .foregroundStyle(AppColor.ink3)
            Text(Money.format(amount))
                .font(.system(size: 21, weight: .heavy))
                .foregroundStyle(color)
                .padding(.top, 5)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(sub)
                .font(.system(size: 11))
                .foregroundStyle(AppColor.ink3)
                .padding(.top, 4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule().fill(color).frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 5)
            .padding(.top, 9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(RoundedRectangle(cornerRadius: 16).fill(AppColor.card))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColor.line, lineWidth: 1))
    }

    private func groupTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold))
            .tracking(2.0)
            .foregroundStyle(AppColor.ink3)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }

    private func row(_ r: BudgetRecord) -> some View {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        let held = r.status == .held

        // 分类 / 备注 / 有图 —— 这就是分类归档到日历的落点
        var tags: [String] = []
        if let c = r.category, !c.isEmpty { tags.append(c) }
        if let n = r.note, !n.isEmpty { tags.append(n) }
        if let img = r.imageFile, !img.isEmpty { tags.append("有图") }

        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(f.string(from: r.ts)) · \(r.status.label)")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.ink3)
                if !tags.isEmpty {
                    Text(tags.joined(separator: "  ·  "))
                        .font(.system(size: 12))
                        .foregroundStyle(held ? AppColor.ink3 : AppColor.brand)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Text("\(held ? "忍住 " : "")\(Money.format(r.amount))")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(held ? AppColor.brand : AppColor.ink)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColor.line).frame(height: 1)
        }
    }
}
