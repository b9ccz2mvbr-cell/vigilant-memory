import SwiftUI
import PhotosUI

/// 规格 5.4 快速计算。
///
/// 「其他池」的流程比日常池多一步：
///   点「其他消费」→ **先竖排列出分类**（饰品 / 零食 / 日用品 / 宠物用品 /
///   电子设备 / 家具 / 手动输入，顺序即 CategoryStore 里的顺序）
///   → 选完再输金额，并可**选填**备注与图片。
struct CalcSheet: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    let initialPool: Pool?

    @State private var pool: Pool = .daily
    @State private var pinned = false
    @State private var input = ""
    @State private var toast: String?

    // 其他池的附加信息
    @State private var category: String?
    @State private var manualCategory = ""
    @State private var note = ""
    @State private var imageFile: String?
    @State private var showNoteField = false

    @State private var photoItem: PhotosPickerItem?

    /// 其他池且还没选分类 → 先显示分类列表
    private var pickingCategory: Bool {
        pool == .other && category == nil
    }

    private var amount: Double { Double(input) ?? 0 }

    var body: some View {
        VStack(spacing: 0) {
            header
            if pickingCategory {
                categoryList
            } else {
                entryArea
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
        .background(
            LinearGradient(colors: [Color(hex: 0x131A24), Color(hex: 0x0E141C)],
                           startPoint: .top, endPoint: .bottom)
        )
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
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toast)
        .onAppear {
            pool = initialPool ?? .daily
            pinned = initialPool != nil
            if pool == .other { category = nil }
        }
        // 用 iOS 16 兼容的单参数版 onChange：
        // 两参数的 onChange(of:initial:_:) 要 iOS 17，而本 App 部署目标是 16.4。
        .onChange(of: photoItem) { newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let img = UIImage(data: data),
                   let name = ImageStore.save(img) {
                    await MainActor.run {
                        imageFile = name
                        toast = "图片已附加"
                        clearToastLater()
                    }
                } else {
                    await MainActor.run {
                        toast = "图片读取失败"
                        clearToastLater()
                    }
                }
            }
        }
    }

    // MARK: - 顶部

    private var header: some View {
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
        .padding(.top, 6)
    }

    private func tab(_ label: String, _ value: Pool) -> some View {
        let active = pool == value
        return Button {
            pool = value
            pinned = true
            if value == .other { category = nil }   // 其他池重新走分类
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

    // MARK: - 分类列表（竖排，顺序 = 设置里的顺序）

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("这笔记在哪一类？")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColor.ink)
                .padding(.top, 16)
                .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 7) {
                    ForEach(Array(CategoryStore.categories.enumerated()), id: \.offset) { _, name in
                        Button {
                            if CategoryStore.isManualEntry(name) { manualCategory = "" }
                            category = name
                            showNoteField = false
                        } label: {
                            HStack {
                                Text(name)
                                    .font(.system(size: 15))
                                    .foregroundStyle(AppColor.ink)
                                Spacer()
                                if CategoryStore.isManualEntry(name) {
                                    Text("自己打字")
                                        .font(.system(size: 11))
                                        .foregroundStyle(AppColor.ink3)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColor.ink3)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 14).fill(AppColor.card))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColor.line, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 300)
        }
    }

    // MARK: - 金额输入区

    private var entryArea: some View {
        VStack(spacing: 0) {
            if pool == .other, let cat = category {
                otherExtras(cat)
            }

            VStack(alignment: .trailing, spacing: 6) {
                Text(input.isEmpty ? "输入金额" : "¥\(input)")
                    .font(.system(size: 36, weight: .heavy))
                    .tracking(-1)
                    .foregroundStyle(input.isEmpty ? AppColor.ink3 : AppColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(resultLine)
                    .font(.system(size: 13))
                    .foregroundStyle(resultColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 10)

            keypad.padding(.top, 10)

            HStack(spacing: 10) {
                PrimaryButton(label: "我买了") { commit(.bought) }
                GhostButton(label: "算了，不买了") { commit(.held) }
            }
            .padding(.top, 10)
        }
    }

    private func otherExtras(_ cat: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button { category = nil } label: {
                    HStack(spacing: 5) {
                        Text(displayCategory(cat))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColor.brand)
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColor.ink3)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(AppColor.brand.opacity(0.14)))
                    .overlay(Capsule().stroke(AppColor.brand.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()

                Button { showNoteField.toggle() } label: {
                    Label(note.isEmpty ? "备注" : "已备注", systemImage: "text.bubble")
                        .font(.system(size: 12))
                        .foregroundStyle(note.isEmpty ? AppColor.ink3 : AppColor.brand)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AppColor.card))
                        .overlay(Capsule().stroke(note.isEmpty ? AppColor.line : AppColor.brand.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(imageFile == nil ? "图片" : "已附图",
                          systemImage: imageFile == nil ? "photo" : "photo.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(imageFile == nil ? AppColor.ink3 : AppColor.brand)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AppColor.card))
                        .overlay(Capsule().stroke(imageFile == nil ? AppColor.line : AppColor.brand.opacity(0.4), lineWidth: 1))
                }
            }

            if CategoryStore.isManualEntry(cat) {
                TextField("输入分类名，例如「运动装备」", text: $manualCategory)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 11).fill(AppColor.card))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(AppColor.line, lineWidth: 1))
            }

            if showNoteField {
                TextField("写点备注…", text: $note, axis: .vertical)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.ink)
                    .lineLimit(1...3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 11).fill(AppColor.card))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(AppColor.line, lineWidth: 1))
            }

            if let imageFile, let img = ImageStore.load(imageFile) {
                HStack(spacing: 10) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 46, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                    Text("已附加图片")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColor.ink3)
                    Spacer()
                    Button("移除") {
                        ImageStore.delete(imageFile)
                        self.imageFile = nil
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(AppColor.danger)
                }
            }
        }
        .padding(.top, 12)
    }

    private func displayCategory(_ cat: String) -> String {
        if CategoryStore.isManualEntry(cat) {
            return manualCategory.isEmpty ? "手动输入…" : manualCategory
        }
        return cat
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
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(key == "back" ? AppColor.cardHi : AppColor.card)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14).stroke(AppColor.line, lineWidth: 1)
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
        if !pinned, !input.isEmpty {
            let suggested = BudgetStore.suggestPool(for: amount)
            if suggested != pool {
                pool = suggested
                if pool == .other { category = nil }
            }
        }
    }

    private func commit(_ status: RecordStatus) {
        guard amount > 0 else {
            toast = "请填写金额"
            clearToastLater()
            return
        }

        var cat: String? = nil
        if pool == .other, let c = category {
            if CategoryStore.isManualEntry(c) {
                let typed = manualCategory.trimmingCharacters(in: .whitespacesAndNewlines)
                cat = typed.isEmpty ? CategoryStore.manualEntryTitle : typed
            } else {
                cat = c
            }
        }

        store.addRecord(amount: amount,
                        pool: pool,
                        status: status,
                        category: cat,
                        note: showNoteField ? note : nil,
                        imageFile: imageFile)

        // 忍住记录不占图片空间
        if status == .held, let imageFile, cat == nil {
            ImageStore.delete(imageFile)
        }
        dismiss()
    }

    private func clearToastLater() {
        let snapshot = toast
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if toast == snapshot { toast = nil }
        }
    }
}
