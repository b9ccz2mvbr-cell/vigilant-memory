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
                case .accessoryCircular: accessoryCircular(snap)
                case .accessoryRectangular: accessoryRectangular(snap)
                case .accessoryInline: accessoryInline(snap)
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
            // 锁屏小组件由系统提供背景，这里必须留空，
            // 否则锁屏上会出现一块突兀的深色方块。
            if family == .systemSmall || family == .systemMedium {
                LinearGradient(colors: [Color(hex: 0x0F1720), Color(hex: 0x0A0E14)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                Color.clear
            }
        }
    }

    // MARK: - 锁屏小组件（iOS 16+）—— 替代安卓的悬浮球

    /// 圆形：今日日常剩余
    private func accessoryCircular(_ snap: Snapshot) -> some View {
        Gauge(value: snap.daily.usedRatio) {
            Text("日常")
        } currentValueLabel: {
            Text(Money.short(max(0, snap.daily.remaining)))
                .font(.system(size: 13, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(snap.daily.overspent ? AppColor.danger : AppColor.brand)
    }

    /// 长方形：两个池各一行
    private func accessoryRectangular(_ snap: Snapshot) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Text("日常")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Text(Money.format(snap.daily.remaining))
                    .font(.system(size: 13, weight: .bold))
                    .widgetAccentable()
            }
            HStack(spacing: 4) {
                Text("其他")
                    .font(.system(size: 11))
                Spacer()
                Text(Money.format(snap.other.remaining))
                    .font(.system(size: 11))
            }
            .foregroundStyle(.secondary)
        }
    }

    /// 单行文字：锁屏时间下方直接显示
    private func accessoryInline(_ snap: Snapshot) -> some View {
        Text("日常剩 \(Money.format(snap.daily.remaining))")
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
        .description("桌面与锁屏都能看到今日日常剩余和本月其他剩余。")
        .supportedFamilies([
            .systemSmall, .systemMedium,              // 桌面
            .accessoryCircular, .accessoryRectangular, .accessoryInline,  // 锁屏
        ])
    }
}

@main
struct BudgetWidgetBundle: WidgetBundle {
    var body: some Widget {
        BudgetWidget()
    }
}
