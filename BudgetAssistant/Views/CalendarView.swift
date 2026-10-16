import SwiftUI

/// ?? 5.6 ????
struct CalendarView: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.dismiss) private var dismiss

    enum Scope: String, CaseIterable {
        case all = "??", daily = "??", other = "??"
    }

    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var month: Int = Calendar.current.component(.month, from: Date())
    @State private var scope: Scope = .all
    @State private var selectedDay: DaySelection?

    private let weekdays = ["?", "?", "?", "?", "?", "?", "?"]

    private var byDay: [Date: (daily: Double, other: Double, list: [BudgetRecord])] {
        store.groupByDay()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Kicker(text: "Calendar").padding(.top, 8)

                    monthHeader.padding(.top, 14)
                    scopePicker.padding(.top, 16)
                    legend.padding(.top, 14)
                    weekdayRow.padding(.top, 16)
                    grid.padding(.top, 4)
                    summary.padding(.top, 18)

                    Text("???? ? ?????????????")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColor.ink3)
                        .padding(.top, 16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(GlowBackground().ignoresSafeArea())
            .navigationTitle("??")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("??") { dismiss() }
                        .foregroundStyle(AppColor.brand)
                }
            }
        }
        .sheet(item: $selectedDay) { sel in
            DaySheet(dayKey: sel.key).environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.clear)
        }
    }

    // MARK: - ????

    private var monthHeader: some View {
        HStack {
            navButton("<") { shift(-1) }
            Spacer()
            Text("\(year) ? \(month) ?")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(AppColor.ink)
            Spacer()
            navButton(">") { shift(1) }
        }
    }

    private func navButton(_ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 20))
                .foregroundStyle(AppColor.ink2)
                .frame(width: 42, height: 42)
                .background(RoundedRectangle(cornerRadius: 13).fill(AppColor.cardHi))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppColor.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func shift(_ delta: Int) {
        var m = month + delta
        var y = year
        if m < 1 { m = 12; y -= 1 }
        if m > 12 { m = 1; y += 1 }
        month = m
        year = y
    }

    // MARK: - ????

    private var scopePicker: some View {
        HStack(spacing: 6) {
            ForEach(Scope.allCases, id: \.self) { s in
                let active = scope == s
                Button { scope = s } label: {
                    Text(s.rawValue)
                        .font(.system(size: 13, weight: active ? .bold : .regular))
                        .foregroundStyle(active ? AppColor.onBrand : AppColor.ink3)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            Group {
                                if active {
                                    RoundedRectangle(cornerRadius: 11)
                                        .fill(LinearGradient(colors: [AppColor.brandHi, AppColor.brandDark],
                                                             startPoint: .top, endPoint: .bottom))
                                } else {
                                    RoundedRectangle(cornerRadius: 11).fill(AppColor.card)
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(active ? .clear : AppColor.line, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - ??

    private var legend: some View {
        HStack(spacing: 12) {
            legendItem(AppColor.brand.opacity(0.45), "???", circle: false)
            legendItem(AppColor.danger, "????", circle: false)
            legendItem(AppColor.accent2, "?????", circle: true)
            Spacer()
        }
    }

    private func legendItem(_ color: Color, _ label: String, circle: Bool) -> some View {
        HStack(spacing: 5) {
            Group {
                if circle {
                    Circle().fill(color).frame(width: 6, height: 6)
                } else {
                    RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 9, height: 9)
                }
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppColor.ink3)
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 4) {
            ForEach(weekdays, id: \.self) { w in
                Text(w)
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.ink3)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - ??

    private var grid: some View {
        let cal = Calendar.current
        let firstOfMonth = cal.date(from: DateComponents(year: year, month: month, day: 1))!
        let daysInMonth = cal.range(of: .day, in: .month, for: firstOfMonth)!.count
        // ???????
        let weekday = cal.component(.weekday, from: firstOfMonth) // 1=Sun
        let lead = (weekday + 5) % 7
        let todayKey = BudgetClock.dayStart(Date())
        let budget = store.config?.dailyBudget ?? 0
        let map = byDay

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                         spacing: 4) {
            ForEach(0..<lead, id: \.self) { i in
                Color.clear.frame(height: 58).id("blank\(i)")
            }
            ForEach(1...daysInMonth, id: \.self) { d in
                let key = cal.date(from: DateComponents(year: year, month: month, day: d, hour: BudgetClock.dayStartHour))!
                let entry = map[key]
                let daily = entry?.daily ?? 0
                let other = entry?.other ?? 0
                let total = daily + other
                let shown: Double = scope == .all ? total : (scope == .daily ? daily : other)
                let overspent = budget > 0 && daily > budget
                let isToday = key == todayKey

                Button { selectedDay = DaySelection(key: key) } label: {
                    VStack(spacing: 1) {
                        Text("\(d)")
                            .font(.system(size: 13))
                            .foregroundStyle(overspent ? AppColor.danger : AppColor.ink2)
                        Text(shown > 0 ? Money.short(shown) : " ")
                            .font(.system(size: 9.5))
                            .foregroundStyle(overspent ? AppColor.danger
                                                       : (total > 0 ? AppColor.brand : AppColor.ink3))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(overspent ? AppColor.danger.opacity(0.15)
                                            : (total > 0 ? AppColor.brand.opacity(0.13) : Color.white.opacity(0.035)))
                    )
                    .overlay(alignment: .bottomTrailing) {
                        if other > 0 {
                            Circle().fill(AppColor.accent2)
                                .frame(width: 5, height: 5)
                                .padding(6)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isToday ? AppColor.brand
                                            : (overspent ? AppColor.danger.opacity(0.45)
                                                         : (total > 0 ? AppColor.brand.opacity(0.3) : .clear)),
                                    lineWidth: isToday ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - ????

    private var summary: some View {
        let cal = Calendar.current
        let map = byDay
        var spent = 0.0
        var over = 0
        var under = 0
        let budget = store.config?.dailyBudget ?? 0

        for (key, e) in map {
            let c = cal.dateComponents([.year, .month], from: key)
            guard c.year == year, c.month == month else { continue }
            spent += e.daily + e.other
            if budget > 0 {
                if e.daily > budget { over += 1 } else if e.daily > 0 { under += 1 }
            }
        }

        let quota = store.config?.monthlyTotal ?? 0
        let left = quota - spent

        return GlassCard {
            VStack(spacing: 13) {
                HStack(spacing: 10) {
                    kv("????", Money.format(spent), .normal)
                    kv("????", Money.format(quota), .normal)
                }
                HStack(spacing: 10) {
                    kv("??", Money.format(left), left < 0 ? .negative : .normal)
                    kv("?? / ???", "\(over) / \(under) ?", .normal)
                }
            }
        }
    }

    private enum KVKind { case normal, negative }

    private func kv(_ label: String, _ value: String, _ kind: KVKind) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppColor.ink3)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(kind == .negative ? AppColor.danger : AppColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// ????????? .sheet(item:)
/// (?? Date ??,?? Swift ?????? @retroactive ???)
struct DaySelection: Identifiable {
    let key: Date
    var id: Double { key.timeIntervalSince1970 }
}
