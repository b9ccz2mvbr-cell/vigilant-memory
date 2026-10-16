import SwiftUI

/// 规格 5.4 快速计算。底部弹窗，背景压暗，支持下拉关闭。
struct CalcSheet: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    let initialPool: Pool?

    @State private var pool: Pool = .daily
    @State private var pinned = false
    @State private var input = ""
    @State private var toast: String?

    private var amount: Double { Double(input) ?? 0 }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                tab("日常池", .daily)
                tab("其他池", .other)
                Button { dismiss() } label: {
                    Text("✕")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColor.ink2)
                        .frame(width: 54, height: 44)
                        .background(RoundedRectangle(cornerRadius: 13).fill(AppColor.cardHi))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppColor.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // 显示区
            VStack(alignment: .trailing, spacing: 6) {
                Text(input.isEmpty ? "输入金额" : "¥\(input)")
                    .font(.system(size: 38, weight: .heavy))
                    .tracking(-1)
                    .foregroundStyle(input.isEmpty ? AppColor.ink3 : AppColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(resultLine)
                    .font(.system(size: 14))
                    .foregroundStyle(resultColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 16)

            keypad.padding(.top, 14)

            HStack(spacing: 10) {
                PrimaryButton(label: "我买了") { commit(.bought) }
                GhostButton(label: "算了，不买了") { commit(.held) }
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
        .background(
            LinearGradient(colors: [Color(hex: 0x131A24), Color(hex: 0x0E141C)],
                           startPoint: .top, endPoint: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle().fill(AppColor.line).frame(height: 1)
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28,
                                          topTrailingRadius: 28,
                                          style: .continuous))
        .overlay(alignment: .top) {
            if let toast {
                Text(toast)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppColor.surface))
                    .padding(.top, 8)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toast)
        .onAppear {
            pool = initialPool ?? .daily
            pinned = initialPool != nil
        }
    }

    private var resultLine: String {
        guard let snap = store.snapshot() else { return "" }
        let state = pool == .daily ? snap.daily : snap.other
        if input.isEmpty {
            return "\(state.label)当前剩 \(Money.format(state.remaining))"
        }
        let left = state.remaining - amount
        if left >= 0 {
            let pct = state.quota > 0 ? Int((amount / state.quota * 100).rounded()) : 0
            return "买完\(state.label)剩 \(Money.format(left))   占额度的 \(pct)%"
        }
        return "超出 \(Money.format(-left))"
    }

    private var resultColor: Color {
        guard let snap = store.snapshot(), !input.isEmpty else { return AppColor.ink3 }
        let state = pool == .daily ? snap.daily : snap.other
        return state.remaining - amount >= 0 ? AppColor.brand : AppColor.danger
    }

    private func tab(_ label: String, _ value: Pool) -> some View {
        let active = pool == value
        return Button {
            pool = value
            pinned = true
        } label: {
            Text(label)
                .font(.system(size: 14, weight: active ? .bold : .regular))
                .foregroundStyle(active ? AppColor.onBrand : AppColor.ink2)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
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

    private var keypad: some View {
        let rows: [[String]] = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], [".", "0", "back"]]
        return VStack(spacing: 6) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        Button { press(key) } label: {
                            Text(key == "back" ? "⌫" : key)
                                .font(.system(size: 22))
                                .foregroundStyle(AppColor.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(key == "back" ? AppColor.cardHi : AppColor.card)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15).stroke(AppColor.line, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 交互

    private func press(_ key: String) {
        switch key {
        case "back":
            if !input.isEmpty { input.removeLast() }
        case ".":
            if !input.contains(".") { input += "." }
        default:
            if input == "0" { input = key }
            else if input.count < 9 { input += key }
        }
        // 规格 5.4 智能预选：用户没手动切过池时才自动判断
        if !pinned, !input.isEmpty {
            pool = BudgetStore.suggestPool(for: amount)
        }
    }

    private func commit(_ status: RecordStatus) {
        guard amount > 0 else {
            toast = "请填写金额"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast = nil }
            return
        }
        store.addRecord(amount: amount, pool: pool, status: status)
        dismiss()
    }
}
