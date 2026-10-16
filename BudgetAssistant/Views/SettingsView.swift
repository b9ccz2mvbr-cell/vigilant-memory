import SwiftUI

/// 规格 5.10 调整额度：改月度总额 / 单日预算 / 每月起始日。
/// 改完只影响之后的计算，已有记录不动。
struct SettingsView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    @State private var monthly = ""
    @State private var daily = ""
    @State private var anchor = 1
    @State private var toast: String?

    private let anchors = [1, 5, 10, 15, 20, 25]

    private var days: Int { BudgetClock.daysInPeriod(Date(), monthStartDay: anchor) }
    private var monthlyValue: Double { Money.parse(monthly) ?? 0 }
    private var dailyValue: Double { Money.parse(daily) ?? 0 }
    private var invalid: Bool { monthlyValue > 0 && dailyValue * Double(days) > monthlyValue }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("月度总额")
                        .font(.system(size: 15, weight: .bold))
                        .padding(.top, 16)
                    bigField("3000", $monthly)

                    Text("日常开支（单日预算）")
                        .font(.system(size: 15, weight: .bold))
                        .padding(.top, 18)
                    bigField("50", $daily)

                    Text("每月起始日")
                        .font(.system(size: 15, weight: .bold))
                        .padding(.top, 18)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                              spacing: 6) {
                        ForEach(anchors, id: \.self) { d in
                            let active = anchor == d
                            Button { anchor = d } label: {
                                Text("\(d) 号")
                                    .font(.system(size: 13, weight: active ? .bold : .regular))
                                    .foregroundStyle(active ? AppColor.onBrand : AppColor.ink3)
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
                    .padding(.top, 10)

                    Text("按起始日 \(anchor) 号算，本周期 \(days) 天 · 预估合计 \(Money.format(dailyValue * Double(days)))")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColor.ink3)
                        .padding(.top, 16)

                    if invalid {
                        Text("单日预算 × 本周期天数 不能超过月度总额")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColor.danger)
                            .padding(.top, 8)
                    }

                    Text("改完只影响之后的计算，已有记录不会被删除。")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColor.ink3)
                        .padding(.top, 10)

                    if let toast {
                        Text(toast)
                            .font(.system(size: 13))
                            .foregroundStyle(AppColor.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(AppColor.surface))
                            .padding(.top, 12)
                    }

                    HStack(spacing: 10) {
                        GhostButton(label: "取消") { dismiss() }
                        PrimaryButton(label: "保存") { save() }
                    }
                    .padding(.top, 26)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(GlowBackground().ignoresSafeArea())
            .navigationTitle("调整额度")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            monthly = trim(store.config?.monthlyTotal ?? 0)
            daily = trim(store.config?.dailyBudget ?? 0)
            anchor = store.config?.monthStartDay ?? 1
        }
    }

    private func bigField(_ placeholder: String, _ binding: Binding<String>) -> some View {
        TextField(placeholder, text: binding)
            .keyboardType(.decimalPad)
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(AppColor.ink)
            .padding(.top, 8)
            .overlay(alignment: .bottom) {
                Rectangle().fill(AppColor.line).frame(height: 2)
            }
    }

    private func save() {
        guard let m = Money.parse(monthly), m > 0 else { return flash("请填写月度总额") }
        guard let d = Money.parse(daily), d > 0 else { return flash("请填写单日预算") }
        guard d * Double(days) <= m else {
            return flash("单日预算 × 本周期天数 不能超过月度总额")
        }
        store.saveConfig(BudgetConfig(monthlyTotal: m, dailyBudget: d, monthStartDay: anchor))
        dismiss()
    }

    private func trim(_ v: Double) -> String {
        v == v.rounded() ? "\(Int(v))" : "\(v)"
    }

    private func flash(_ msg: String) {
        toast = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { toast = nil }
    }
}
