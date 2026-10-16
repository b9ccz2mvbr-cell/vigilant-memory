import ActivityKit
import WidgetKit
import SwiftUI

/// 灵动岛 / 锁屏实时活动。
///
/// iOS 的限制（写在最前面，免得误解）：
///  - 最长存活 **8 小时**，之后系统自动移除
///  - 必须由 App 主动启动，关机重启后不会自己回来
///  - 灵动岛固定在顶部，**不能浮在其他 App 之上**（安卓那种悬浮球做不到）
struct BudgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BudgetActivityAttributes.self) { context in
            lockScreen(context)
                .activityBackgroundTint(Color(hex: 0x0A0E14))
                .activitySystemActionForegroundColor(AppColor.brand)
        } dynamicIsland: { context in
            DynamicIsland {
                // ---- 展开态 ----
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("日常")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColor.ink3)
                        Text(Money.format(context.state.dailyRemaining))
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(context.state.dailyOverspent ? AppColor.danger : AppColor.brand)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("其他")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColor.ink3)
                        Text(Money.format(context.state.otherRemaining))
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(AppColor.accent2)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 7) {
                        bar(ratio: context.state.dailyUsedRatio,
                            color: context.state.dailyOverspent ? AppColor.danger : AppColor.brand)

                        // 快捷按钮 —— 在这里直接记账，不用打开 App
                        // （iOS 17+ 的 Button(intent:)，intent 定义在 Shared/QuickAddIntent.swift）
                        HStack(spacing: 6) {
                            quickButton(10)
                            quickButton(20)
                            quickButton(50)
                            Spacer(minLength: 4)
                            Button(intent: OpenBudgetIntent()) {
                                Text("记账")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppColor.onBrand)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(AppColor.brand))
                            }
                            .buttonStyle(.plain)
                        }

                        HStack(spacing: 4) {
                            Text("长按可展开 · 点数字记一笔")
                                .font(.system(size: 10))
                                .foregroundStyle(AppColor.ink3)
                            Spacer()
                            Text("额度 \(Money.format(context.state.dailyQuota))")
                                .font(.system(size: 10))
                                .foregroundStyle(AppColor.ink3)
                        }
                    }
                }
            } compactLeading: {
                Text("¥")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(context.state.dailyOverspent ? AppColor.danger : AppColor.brand)
            } compactTrailing: {
                Text(Money.short(max(0, context.state.dailyRemaining)))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(context.state.dailyOverspent ? AppColor.danger : AppColor.brand)
            } minimal: {
                Text("¥")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(context.state.dailyOverspent ? AppColor.danger : AppColor.brand)
            }
            .keylineTint(AppColor.brand)
        }
    }

    // MARK: - 锁屏 / 通知横幅上的样式

    @ViewBuilder
    private func lockScreen(_ context: ActivityViewContext<BudgetActivityAttributes>) -> some View {
        VStack(spacing: 11) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("今日日常")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColor.ink3)
                    Text(Money.format(context.state.dailyRemaining))
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(context.state.dailyOverspent ? AppColor.danger : AppColor.brand)
                    bar(ratio: context.state.dailyUsedRatio,
                        color: context.state.dailyOverspent ? AppColor.danger : AppColor.brand)
                        .frame(width: 120)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("其他")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColor.ink3)
                    Text(Money.format(context.state.otherRemaining))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.accent2)
                }
            }

            // 锁屏上也能直接记账
            HStack(spacing: 6) {
                quickButton(10)
                quickButton(20)
                quickButton(50)
                Spacer(minLength: 4)
                Button(intent: OpenBudgetIntent()) {
                    Text("打开记账")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColor.onBrand)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(AppColor.brand))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
    }

    private func bar(ratio: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule().fill(color).frame(width: geo.size.width * ratio)
            }
        }
        .frame(height: 5)
    }

    /// 展开面板里的「+¥n」快捷按钮
    private func quickButton(_ amount: Double) -> some View {
        Button(intent: QuickAddIntent(amount: amount)) {
            Text("+\(Int(amount))")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColor.brand)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Capsule().fill(AppColor.brand.opacity(0.16)))
                .overlay(Capsule().stroke(AppColor.brand.opacity(0.4), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}
