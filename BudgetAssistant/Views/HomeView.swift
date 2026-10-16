import SwiftUI

/// 规格 5.3 入口页：两个大按钮并排，各自显示余额，用户第一下即完成选择。
struct HomeView: View {
    @EnvironmentObject var store: BudgetStore

    @State private var calcPool: Pool?
    @State private var showCalendar = false
    @State private var showStats = false
    @State private var showSettings = false
    @State private var showGuide = false
    @State private var confirmClear = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Kicker(text: "Budget")
                    .padding(.top, 26)

                Text("极简预算助手")
                    .font(.system(size: 30, weight: .heavy))
                    .tracking(-0.8)
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Color(hex: 0xA9BBCE)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .padding(.top, 10)

                if let snap = store.snapshot() {
                    Text("本周期共 \(snap.daysInPeriod) 天 · 月度总额 \(Money.format(snap.monthlyTotal))")
                        .font(.system(size: 13.5))
                        .foregroundStyle(AppColor.ink2)
                        .padding(.top, 8)

                    HStack(spacing: 12) {
                        poolCard(snap.daily)
                        poolCard(snap.other)
                    }
                    .padding(.top, 20)

                    // 月度总消费预警：60% 提醒、80% 警示、100% 超支
                    if let banner = monthBanner(snap) {
                        Text(banner.text)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(banner.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(banner.color.opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(banner.color.opacity(0.35), lineWidth: 1)
                            )
                            .padding(.top, 14)
                    }
                }

                let held = store.heldStats()
                Text("本月忍住 \(held.count) 次 · 共 \(Money.format(held.total))")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColor.ink2)
                    .padding(.top, 22)

                Text("点一下，看看买完还剩多少")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.ink3)
                    .padding(.top, 6)

                entryRow(title: "日历", hint: "看每天花了多少 ›") { showCalendar = true }
                    .padding(.top, 22)

                entryRow(title: "其他支出分类", hint: "日度 / 月度 / 年度占比 ›") { showStats = true }
                    .padding(.top, 10)

                entryRow(title: "调整额度", hint: "改月度总额 / 单日预算 ›") { showSettings = true }
                    .padding(.top, 10)

                entryRow(title: "小组件与灵动岛", hint: "灵动岛开关 · 添加引导 ›") { showGuide = true }
                    .padding(.top, 10)

                recentRecords
                    .padding(.top, 24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color.clear)
        .sheet(item: $calcPool) { pool in
            CalcSheet(initialPool: pool)
                .environmentObject(store)
                .presentationDetents([.height(600)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $showCalendar) {
            CalendarView().environmentObject(store)
        }
        .sheet(isPresented: $showStats) {
            NavigationStack {
                CategoryStatsView().environmentObject(store)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $showGuide) {
            WidgetGuideView()
                .environmentObject(store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.clear)
        }
        .alert("清空全部数据", isPresented: $confirmClear) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) { store.clearAll() }
        } message: {
            Text("确定清空全部数据？此操作不可撤销。")
        }
    }

    // MARK: - 月度预警横幅

    private struct MonthBanner {
        let text: String
        let color: Color
        let ink: Color
    }

    /// 月度总消费预警：60% 提醒、80% 警示、100% 超支
    private func monthBanner(_ snap: Snapshot) -> MonthBanner? {
        let spent = snap.daily.spent + snap.other.spent
        let total = snap.monthlyTotal
        let level = Alerts.monthLevel(spent: spent, monthlyTotal: total)
        let pct = Int((Alerts.monthRatio(spent: spent, monthlyTotal: total) * 100).rounded())
        let left = max(0, total - spent)

        switch level {
        case .none:
            return nil
        case .watch:
            return MonthBanner(text: "月度总消费已用 \(pct)%，还剩 \(Money.format(left))",
                               color: AppColor.warn,
                               ink: AppColor.warn)
        case .warn:
            return MonthBanner(text: "月度总消费已用 \(pct)%，只剩 \(Money.format(left)) 了",
                               color: AppColor.danger,
                               ink: Color(hex: 0xFFC9C9))
        case .over:
            return MonthBanner(text: "月度总消费已超支 \(Money.format(max(0, spent - total)))",
                               color: AppColor.danger,
                               ink: Color(hex: 0xFFC9C9))
        }
    }

    // MARK: - 池卡片

    private func poolCard(_ state: PoolState) -> some View {
        Button {
            calcPool = state.pool
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(state.pool == .daily ? "DAILY" : "OTHER")
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(2.2)
                    .foregroundStyle(AppColor.ink3)
                Text(state.label)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColor.ink2)
                    .padding(.top, 8)
                Text(Money.format(state.remaining))
                    .font(.system(size: 26, weight: .heavy))
                    .tracking(-0.5)
                    .foregroundStyle(state.overspent ? AppColor.danger : AppColor.brand)
                    .padding(.top, 4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(state.pool == .daily ? "吃饭 / 通勤 / 水 / 零食"
                                          : "购物 / 娱乐 / 聚餐 / 数码 / 服装")
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppColor.ink3)
                    .padding(.top, 6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(state.overspent ? AppColor.danger.opacity(0.12) : AppColor.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(state.overspent ? AppColor.danger.opacity(0.55) : AppColor.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 入口行

    private func entryRow(title: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColor.ink)
                Spacer()
                Text(hint)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.ink3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous).fill(AppColor.cardHi)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(AppColor.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 最近记录

    private var recentRecords: some View {
        let recent = store.records.sorted { $0.ts > $1.ts }.prefix(20)

        return VStack(alignment: .leading, spacing: 0) {
            Text("最近记录")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(2.0)
                .foregroundStyle(AppColor.ink3)

            if recent.isEmpty {
                Text("还没有记录")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.ink3)
                    .padding(.vertical, 14)
            } else {
                ForEach(Array(recent)) { r in
                    HStack {
                        Text("\(Self.stamp(r.ts)) · \(r.pool.label)")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColor.ink3)
                        Spacer()
                        Text("\(r.status == .held ? "忍住 " : "")\(Money.format(r.amount))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(r.status == .held ? AppColor.brand : AppColor.ink)
                    }
                    .padding(.vertical, 11)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(AppColor.line).frame(height: 1)
                    }
                }
            }

            Button("清空全部数据") { confirmClear = true }
                .font(.system(size: 13.5))
                .foregroundStyle(AppColor.ink3)
                .padding(.top, 14)
        }
    }

    private static func stamp(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM/dd HH:mm"
        return f.string(from: d)
    }
}

/// 让 Pool 能直接驱动 .sheet(item:)
extension Pool: Identifiable {
    public var id: String { rawValue }
}
