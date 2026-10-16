import SwiftUI

/// 分类管理 —— 其他池那七个分类在这里增删改、调顺序。
///
/// 默认顺序：饰品 / 零食 / 日用品 / 宠物用品 / 电子设备 / 家具 / 手动输入
/// （「手动输入」是让用户自己打字的入口，不是普通分类，所以不显示删除按钮。）
struct CategorySettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var categories: [String] = CategoryStore.categories
    @State private var newName = ""
    @State private var editingIndex: Int?
    @State private var editingText = ""
    @State private var savedToast = false

    var body: some View {
        List {
            Section {
                ForEach(Array(categories.enumerated()), id: \.offset) { idx, name in
                    HStack(spacing: 10) {
                        if let editingIndex, editingIndex == idx {
                            TextField("分类名", text: $editingText)
                                .font(.system(size: 15))
                                .foregroundStyle(AppColor.ink)
                                .onSubmit { finishEditing() }
                            Button("完成") { finishEditing() }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColor.brand)
                        } else {
                            Text(name)
                                .font(.system(size: 15))
                                .foregroundStyle(AppColor.ink)
                            Spacer()
                            if CategoryStore.isManualEntry(name) {
                                Text("自己打字")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppColor.ink3)
                            }
                        }
                    }
                    .listRowBackground(AppColor.card)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !CategoryStore.isManualEntry(name) else { return }
                        editingIndex = idx
                        editingText = name
                    }
                    .swipeActions(edge: .trailing) {
                        if !CategoryStore.isManualEntry(name) {
                            Button(role: .destructive) {
                                categories.remove(at: idx)
                                save()
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
                .onMove { from, to in
                    categories.move(fromOffsets: from, toOffset: to)
                    save()
                }
            } header: {
                Text("其他消费的分类")
                    .foregroundStyle(AppColor.ink3)
            } footer: {
                Text("顺序就是记账时弹出的顺序。左右滑动可以删除，长按拖动可以调整顺序，点一下可以改名。")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.ink3)
            }

            Section {
                HStack(spacing: 8) {
                    TextField("新增一个分类", text: $newName)
                        .font(.system(size: 15))
                        .foregroundStyle(AppColor.ink)
                    Button {
                        let t = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty, !categories.contains(t) else { return }
                        // 插在「手动输入」之前，保持它永远是最后一项
                        if let last = categories.last, CategoryStore.isManualEntry(last) {
                            categories.insert(t, at: categories.count - 1)
                        } else {
                            categories.append(t)
                        }
                        newName = ""
                        save()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppColor.brand)
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(AppColor.card)

                Button {
                    categories = CategoryStore.defaultCategories
                    save()
                } label: {
                    Text("恢复默认分类")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColor.danger)
                }
                .listRowBackground(AppColor.card)
            } footer: {
                Text("改动立刻生效，已有的记录不受影响。")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.ink3)
            }
        }
        .scrollContentBackground(.hidden)
        .background(GlowBackground().ignoresSafeArea())
        .environment(\.editMode, .constant(.active))   // 开启拖动排序
        .navigationTitle("消费分类")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { dismiss() }.foregroundStyle(AppColor.brand)
            }
        }
        .overlay(alignment: .top) {
            if savedToast {
                Text("已保存")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppColor.surface))
                    .padding(.top, 6)
            }
        }
    }

    private func finishEditing() {
        guard let idx = editingIndex else { return }
        let t = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { categories[idx] = t }
        editingIndex = nil
        save()
    }

    private func save() {
        categories = CategoryStore.sanitize(categories)
        CategoryStore.categories = categories
        savedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { savedToast = false }
    }
}
