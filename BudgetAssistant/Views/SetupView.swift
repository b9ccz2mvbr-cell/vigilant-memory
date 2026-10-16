import SwiftUI

/// 规格 5.1 首次设置（三步）
struct SetupView: View {
    @EnvironmentObject var store: BudgetStore

    @State private var step = 1
    @State private var monthly = ""
    @State private var daily = ""
    @State private var meal: Int?
    @State private var transport: Int?
    @State private var misc: Int?
    @State private var toast: String?

    private var days: Int { BudgetClock.daysInPeriod(Date(), monthStartDay: 1) }
    private var monthlyValue: Double { Money.parse(monthly) ?? 0 }
    private var dailyValue: Double { Money.parse(daily) ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Kicker(text: "第 \(step) 步 / 共 3 步")
                .padding(.top, 22)

            Group {
                switch step {
                case 1: step1
                case 2: step2
                default: step3
                }
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
        .overlay(alignment: .top) {
            if let toast {
                Text(toast)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppColor.surface))
                    .padding(.top, 6)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toast)
    }

    // MARK: - 第 1 步

    private var step1: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("月度总额")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.6)
            Text("输入本月可支配总额")
                .font(.system(size: 13.5))
                .foregroundStyle(AppColor.ink2)
                .padding(.top, 8)

            TextField("3000", text: $monthly)
                .keyboardType(.decimalPad)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(AppColor.ink)
                .padding(.top, 26)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(AppColor.line).frame(height: 2)
                }

            Spacer(minLength: 40)

            PrimaryButton(label: "下一步") {
                guard let v = Money.parse(monthly), v > 0 else { return flash("请填写金额") }
                withAnimation { step = 2 }
            }
        }
    }

    // MARK: - 第 2 步

    private var step2: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("日常开支")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.6)
                Text("先选三个大概数，我们会算出单日预算，你也可以直接改")
                    .font(.system(size: 13.5))
                    .foregroundStyle(AppColor.ink2)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)

                chips("每天吃饭大概", [("20 元以内", 20), ("20–35 元", 27), ("35 元以上", 40)], $meal)
                chips("每天交通大概", [("5 元以内", 5), ("5–15 元", 10), ("15 元以上", 18)], $transport)
                chips("每天其他日常（水 / 零食）", [("5 元以内", 5), ("5–15 元", 10), ("15 元以上", 18)], $misc)

                Text("单日预算")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.top, 20)

                TextField("50", text: $daily)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AppColor.ink)
                    .padding(.top, 6)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(AppColor.line).frame(height: 2)
                    }

                Text("预估月合计 \(Money.format(dailyValue * Double(days)))")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.ink3)
                    .padding(.top, 10)

                if monthlyValue > 0 && dailyValue * Double(days) > monthlyValue {
                    Text("单日预算 × 当月天数 不能超过月度总额")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColor.danger)
                        .padding(.top, 6)
                }

                HStack(spacing: 10) {
                    GhostButton(label: "上一步") { withAnimation { step = 1 } }
                    PrimaryButton(label: "下一步") {
                        guard let v = Money.parse(daily), v > 0 else { return flash("请填写金额") }
                        guard v * Double(days) <= monthlyValue else {
                            return flash("单日预算 × 当月天数 不能超过月度总额")
                        }
                        withAnimation { step = 3 }
                    }
                }
                .padding(.top, 26)
            }
            .padding(.bottom, 20)
        }
    }

    private func chips(_ title: String,
                       _ options: [(String, Int)],
                       _ binding: Binding<Int?>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.top, 14)
                .padding(.bottom, 8)

            HStack(spacing: 6) {
                ForEach(options, id: \.1) { opt in
                    let active = binding.wrappedValue == opt.1
                    Button {
                        binding.wrappedValue = opt.1
                        if let m = meal, let t = transport, let x = misc {
                            daily = String(m + t + x)
                        }
                    } label: {
                        Text(opt.0)
                            .font(.system(size: 12.5, weight: active ? .semibold : .regular))
                            .foregroundStyle(active ? AppColor.brand : AppColor.ink2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(active ? AppColor.brand.opacity(0.12) : AppColor.card)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 13)
                                    .stroke(active ? AppColor.brand.opacity(0.5) : AppColor.line, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 第 3 步

    private var step3: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("确认分配")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.6)
            Text("确认后即可开始使用")
                .font(.system(size: 13.5))
                .foregroundStyle(AppColor.ink2)
                .padding(.top, 8)

            let d = dailyValue * Double(days)
            let other = max(0, monthlyValue - d)

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("月度总额    \(Money.format(monthlyValue))")
                        .font(.system(size: 16, weight: .bold))
                    Text("├ 日常开支  \(Money.format(d))（\(Money.format(dailyValue))/天 × \(days) 天）")
                        .font(.system(size: 15))
                        .foregroundStyle(AppColor.brand)
                    Text("└ 其他支出  \(Money.format(other))")
                        .font(.system(size: 15))
                        .foregroundStyle(AppColor.brand)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 24)

            Spacer(minLength: 40)

            HStack(spacing: 10) {
                GhostButton(label: "上一步") { withAnimation { step = 2 } }
                PrimaryButton(label: "开始使用") {
                    store.saveConfig(BudgetConfig(monthlyTotal: monthlyValue,
                                                  dailyBudget: dailyValue,
                                                  monthStartDay: 1))
                }
            }
        }
    }

    private func flash(_ msg: String) {
        toast = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { toast = nil }
    }
}
