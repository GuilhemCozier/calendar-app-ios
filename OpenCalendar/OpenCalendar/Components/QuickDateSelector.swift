//
//  QuickDateSelector.swift
//  OpenCalendar
//
//  Created by Claude Code on 2025-11-27.
//

import SwiftUI

// MARK: - Quick Date Selector
struct QuickDateSelector: View {
    @Binding var viewedDate: Date
    let today: Date = Date()

    @State private var dragOffset: CGFloat = 0
    @State private var displayMonth: Date
    @State private var isDragging: Bool = false

    private let calendar = Calendar.current

    init(viewedDate: Binding<Date>) {
        self._viewedDate = viewedDate
        // Initialize displayMonth to the first of the viewed month
        let calendar = Calendar.current
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: viewedDate.wrappedValue)) ?? Date()
        self._displayMonth = State(initialValue: firstOfMonth)
    }

    private var weekDays: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!)!
            return formatter.string(from: date).prefix(1).uppercased()
        }
    }

    // Calculate number of weeks for dynamic height
    private var numberOfWeeks: Int {
        guard let range = calendar.range(of: .weekOfMonth, in: .month, for: displayMonth) else {
            return 5
        }
        return range.count
    }

    private var dynamicHeight: CGFloat {
        let weekHeaderHeight: CGFloat = 20
        let rowHeight: CGFloat = 40
        let verticalPadding: CGFloat = 32
        return weekHeaderHeight + (CGFloat(numberOfWeeks) * rowHeight) + verticalPadding
    }

    var body: some View {
        VStack(spacing: 8) {
            // Week days header
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(AppTypography.caption(weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)

            // Carousel of month grids
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Previous month (pre-rendered, shown when swiping right)
                    if let prevMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth) {
                        MonthGridView(
                            month: prevMonth,
                            viewedDate: viewedDate,
                            today: today,
                            onDateTap: { date in
                                viewedDate = date
                            }
                        )
                        .animation(nil, value: displayMonth)
                        .frame(width: geometry.size.width)
                        .offset(x: -geometry.size.width + dragOffset)
                        .opacity(dragOffset > 0 ? 1 : 0)
                    }

                    // Current month (main/centered grid)
                    MonthGridView(
                        month: displayMonth,
                        viewedDate: viewedDate,
                        today: today,
                        onDateTap: { date in
                            viewedDate = date
                        }
                    )
                    .animation(nil, value: displayMonth)
                    .frame(width: geometry.size.width)
                    .offset(x: dragOffset)

                    // Next month (pre-rendered, shown when swiping left)
                    if let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayMonth) {
                        MonthGridView(
                            month: nextMonth,
                            viewedDate: viewedDate,
                            today: today,
                            onDateTap: { date in
                                viewedDate = date
                            }
                        )
                        .animation(nil, value: displayMonth)
                        .frame(width: geometry.size.width)
                        .offset(x: geometry.size.width + dragOffset)
                        .opacity(dragOffset < 0 ? 1 : 0)
                    }
                }
                .clipped()
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            isDragging = true
                            // Sticky to finger - follows proportionally
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            handleSwipe(value, screenWidth: geometry.size.width)
                            isDragging = false
                        }
                )
            }
            .frame(height: CGFloat(numberOfWeeks) * 40)
        }
        .padding(.vertical, 16)
        .background(AppColors.surface)
        .animation(nil, value: displayMonth) // Prevent bounce - don't animate layout changes
        .animation(nil, value: numberOfWeeks) // Prevent bounce on height change
        .frame(height: dynamicHeight)
        .onAppear {
            // Initialize display month to viewed date's month
            if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: viewedDate)) {
                displayMonth = monthStart
            }
        }
        .onChange(of: viewedDate) { _, newValue in
            // Update display month when viewed date changes from external source (e.g., month selector)
            if !calendar.isDate(newValue, equalTo: displayMonth, toGranularity: .month) {
                // No animation - just update state to prevent bounce
                if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: newValue)) {
                    displayMonth = monthStart
                }
            }
        }
    }

    private func handleSwipe(_ gesture: DragGesture.Value, screenWidth: CGFloat) {
        let threshold: CGFloat = screenWidth * 0.3
        let velocity = gesture.predictedEndTranslation.width - gesture.translation.width

        let shouldNavigate = abs(gesture.translation.width) > threshold || abs(velocity) > 500

        if gesture.translation.width < 0 && shouldNavigate {
            // Swipe left: next month
            if let nextMonthBase = calendar.date(byAdding: .month, value: 1, to: displayMonth) {
                // Get the first day of the next month
                let components = calendar.dateComponents([.year, .month], from: nextMonthBase)
                if let nextMonth = calendar.date(from: components) {
                    // Smoothly complete the swipe animation - the next month grid slides in from the right
                    withAnimation(AppAnimations.spring) {
                        dragOffset = -screenWidth
                    }

                    // Wait for the animation to complete, THEN update the month and reset offset
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        // Disable all animations for the state update to prevent date cells from animating
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            // If swiping to today's month, select today; otherwise select 1st of month
                            if self.calendar.isDate(nextMonth, equalTo: self.today, toGranularity: .month) {
                                self.viewedDate = self.today
                            } else {
                                self.viewedDate = nextMonth
                            }

                            // Reset display month and offset instantly (no animation)
                            self.displayMonth = nextMonth
                            self.dragOffset = 0
                        }
                    }
                }
            } else {
                withAnimation(AppAnimations.spring) {
                    dragOffset = 0
                }
            }
        } else if gesture.translation.width > 0 && shouldNavigate {
            // Swipe right: previous month
            if let prevMonthBase = calendar.date(byAdding: .month, value: -1, to: displayMonth) {
                // Get the first day of the previous month
                let components = calendar.dateComponents([.year, .month], from: prevMonthBase)
                if let prevMonth = calendar.date(from: components) {
                    // Smoothly complete the swipe animation - the previous month grid slides in from the left
                    withAnimation(AppAnimations.spring) {
                        dragOffset = screenWidth
                    }

                    // Wait for the animation to complete, THEN update the month and reset offset
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        // Disable all animations for the state update to prevent date cells from animating
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            // If swiping to today's month, select today; otherwise select 1st of month
                            if self.calendar.isDate(prevMonth, equalTo: self.today, toGranularity: .month) {
                                self.viewedDate = self.today
                            } else {
                                self.viewedDate = prevMonth
                            }

                            // Reset display month and offset instantly (no animation)
                            self.displayMonth = prevMonth
                            self.dragOffset = 0
                        }
                    }
                }
            } else {
                withAnimation(AppAnimations.spring) {
                    dragOffset = 0
                }
            }
        } else {
            // Snap back to center
            withAnimation(AppAnimations.spring) {
                dragOffset = 0
            }
        }
    }
}

// MARK: - Month Grid View
struct MonthGridView: View {
    let month: Date
    let viewedDate: Date
    let today: Date
    let onDateTap: (Date) -> Void

    private let calendar = Calendar.current

    private var datesInMonth: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        // Calculate leading empty days
        // firstWeekday: 1 = Sunday, 2 = Monday, etc.
        // We want Monday as first day of week (2)
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        // Convert to 0-indexed where Monday = 0
        let leadingEmptyDays = (firstWeekday == 1) ? 6 : (firstWeekday - 2)

        var dates: [Date?] = Array(repeating: nil, count: leadingEmptyDays)

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                dates.append(date)
            }
        }

        return dates
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
            ForEach(Array(datesInMonth.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    DateCellButton(
                        date: date,
                        viewedDate: viewedDate,
                        today: today,
                        onTap: {
                            onDateTap(date)
                        }
                    )
                } else {
                    Color.clear
                        .frame(height: 32)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct DateCellButton: View {
    let date: Date
    let viewedDate: Date
    let today: Date
    let onTap: () -> Void

    private let calendar = Calendar.current

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: viewedDate)
    }

    private var isToday: Bool {
        calendar.isDate(date, inSameDayAs: today)
    }

    var body: some View {
        Button(action: onTap) {
            Text(dayNumber)
                .font(AppTypography.callout(weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? AppColors.surfaceElevated : (isToday ? AppColors.accent : AppColors.textPrimary))
                .frame(height: 36)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isSelected {
                            AppColors.accent
                        } else if isToday {
                            AppColors.accentSubtle
                        } else {
                            Color.clear
                        }
                    }
                )
                .cornerRadius(10)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
