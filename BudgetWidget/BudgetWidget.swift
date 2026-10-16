import WidgetKit
import SwiftUI

struct BudgetEntry: TimelineEntry {
    let date: Date
    let snapshot: Snapshot?
    let configured: Bool
}

struct BudgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(date: Date(),
                    snapshot: Snapshot(daily: PoolState(pool: .daily, quota: 50, spent: 18),
                                       other: PoolState(pool: .other, quota: 1450, spent: 578),
                                       monthlyTotal: 3000,
                                       daysInPeriod: 31),
                    configured: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> Void) {
        completion(current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> Void) {
        // 每整点刷一次：跨过凌晨 4:00 日界后数字才会正确翻篇
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [current()], policy: .after(next)))
    }

    private func current() -> BudgetEntry {
        let store = BudgetStore.shared
        return BudgetEntry(date: Date(), snapshot: store.snapshot(), configured: store.configured)
    }
}

// MARK: - 小组件视图

struct BudgetWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BudgetEntry

    var body: some View {
        Group {
            if let snap = entry.snapshot {
                switch family {
                case .systemMedium: medium(snap)
                default: small(snap)
                }
            } else {
                VStack(spacing: 6) {
                    Text("¥")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(AppColor.brand)
                    Text("还没设置额度")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColor.ink3)
                }
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(hex: 0x0F1720), Color(hex: 0x0A0E14)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    /// 2x1：今日日常剩余 + 本月其他剩余
    private func small(_ snap: Snapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("今日日常")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(AppColor.ink3)
            Text(Money.format(snap.daily.remaining))
                .font(.system(size: 26, weight: .heavy))
                .tracking(-0.6)
                .foregroundStyle(snap.daily.overspent ? AppColor.danger : AppColor.brand)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, 4)

            Spacer(minLength: 4)

            HStack(spacing: 5) {
                Circle()
                    .fill(snap.other.overspent ? AppColor.danger : AppColor.accent2)
                    .frame(width: 6, height: 6)
                Text("其他剩 \(Money.format(snap.other.remaining))")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.ink2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    /// 4x1：两个池各一条进度条
    private func medium(_ snap: Snapshot) -> some View {
        HStack(alignment: .top, spacing: 12) {
            bar(title: "日常开支", state: snap.daily, color: snap.daily.overspent ? AppColor.danger : AppColor.brand)
            bar(title: "其他支出", state: snap.other, color: AppColor.accent2)
            VStack(alignment: .trailing, spacing: 0) {
                Text("本月剩")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColor.ink3)
                Text(Money.format(snap.monthlyTotal - snap.daily.spent - snap.other.spent))
                    .font(.system(size: 17, weight: .heavy))
                    .tracking(-0.4)
                    .foregroundStyle(snap.globalOverspent ? AppColor.danger : AppColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func bar(title: String, state: PoolState, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(AppColor.ink3)
            Text(Money.format(state.remaining))
                .font(.system(size: 19, weight: .heavy))
                .tracking(-0.4)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, 2)

            Spacer(minLength: 4)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.10))
                    Capsule().fill(color).frame(width: geo.size.width * state.usedRatio)
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 装配

struct BudgetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BudgetWidget", provider: BudgetProvider()) { entry in
            BudgetWidgetView(entry: entry)
        }
        .configurationDisplayName("预算余额")
        .description("今日日常剩余与本月其他剩余，一眼看到还能花多少。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct BudgetWidgetBundle: WidgetBundle {
    var body: some Widget {
        BudgetWidget()
    }
}
