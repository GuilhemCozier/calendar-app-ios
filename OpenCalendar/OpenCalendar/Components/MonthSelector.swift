//
//  MonthSelector.swift
//  OpenCalendar
//
//  Created by Claude Code on 2025-11-27.
//

import SwiftUI

// MARK: - Month Selector
struct MonthSelector: View {
    @Binding var viewedDate: Date
    @Binding var shouldScrollToToday: Bool
    let today: Date = Date()

    private let calendar = Calendar.current

    private var months: [(date: Date, name: String, isYear: Bool)] {
        var result: [(date: Date, name: String, isYear: Bool)] = []

        // Generate 240 months: 120 before today and 120 after today (20 years total)
        // This creates a virtually infinite scrolling experience
        for offset in -120...120 {
            if let monthDate = calendar.date(byAdding: .month, value: offset, to: today) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                let monthName = formatter.string(from: monthDate)

                result.append((monthDate, monthName, false))

                // Add year indicator after December
                let month = calendar.component(.month, from: monthDate)
                if month == 12 {
                    let year = calendar.component(.year, from: monthDate)
                    let yearDate = monthDate
                    result.append((yearDate, String(year), true))
                }
            }
        }

        return result
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(months.enumerated()), id: \.offset) { index, item in
                        if item.isYear {
                            // Year container
                            Text(item.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        } else {
                            // Month button
                            MonthButton(
                                monthDate: item.date,
                                monthName: item.name,
                                viewedDate: viewedDate,
                                onTap: {
                                    viewedDate = item.date
                                }
                            )
                            .id(index)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 48)
            .background(AppColors.surface)
            .onAppear {
                // Only scroll to today's month on initial appear
                if shouldScrollToToday {
                    if let todayIndex = months.firstIndex(where: { calendar.isDate($0.date, equalTo: today, toGranularity: .month) }) {
                        proxy.scrollTo(todayIndex, anchor: .leading)
                    }
                    shouldScrollToToday = false
                }
            }
            .onChange(of: shouldScrollToToday) { _, newValue in
                // Scroll to today's month when explicitly requested (e.g., today button tapped)
                if newValue {
                    if let todayIndex = months.firstIndex(where: { calendar.isDate($0.date, equalTo: today, toGranularity: .month) }) {
                        withAnimation {
                            proxy.scrollTo(todayIndex, anchor: .leading)
                        }
                    }
                    DispatchQueue.main.async {
                        shouldScrollToToday = false
                    }
                }
            }
        }
    }
}

struct MonthButton: View {
    let monthDate: Date
    let monthName: String
    let viewedDate: Date
    let onTap: () -> Void

    private let calendar = Calendar.current

    private var isSelected: Bool {
        calendar.isDate(monthDate, equalTo: viewedDate, toGranularity: .month)
    }

    var body: some View {
        Button(action: onTap) {
            Text(monthName)
                .font(AppTypography.subheadline(weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? AppColors.surfaceElevated : AppColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.accent : AppColors.surfaceElevated)
                .cornerRadius(10)
                .shadow(color: isSelected ? AppColors.accent.opacity(0.15) : AppColors.textPrimary.opacity(0.03), radius: isSelected ? 6 : 3, x: 0, y: isSelected ? 3 : 1)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
