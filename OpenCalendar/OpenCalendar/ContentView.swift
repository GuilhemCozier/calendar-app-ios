//
//  ContentView.swift
//  OpenCalendar
//
//  Created by Guilhem Cozier on 24/11/2025.
//

import SwiftUI

// MARK: - Design System
struct AppColors {
    // Cream backgrounds - warm but subtle
    static let background = Color(hex: "#F5F3EE")
    static let surface = Color(hex: "#FDFCFA")
    static let surfaceElevated = Color.white

    // Sage green accent
    static let accent = Color(hex: "#8B9D83")
    static let accentLight = Color(hex: "#A8B89F")
    static let accentSubtle = Color(hex: "#E8EBE6")

    // Neutrals
    static let textPrimary = Color(hex: "#1A1A1A")
    static let textSecondary = Color(hex: "#666666")
    static let textTertiary = Color(hex: "#999999")
    static let border = Color(hex: "#E6E3DD")
    static let borderSubtle = Color(hex: "#F0EDE7")

    // Semantic
    static let eventBlue = Color(hex: "#7B93B3")
    static let eventBlueBg = Color(hex: "#E8EDF3")
}

struct AppTypography {
    // SF Pro with refined weights
    static func largeTitle(weight: Font.Weight = .semibold) -> Font {
        .system(size: 28, weight: weight, design: .default)
    }

    static func title(weight: Font.Weight = .semibold) -> Font {
        .system(size: 20, weight: weight, design: .default)
    }

    static func headline(weight: Font.Weight = .medium) -> Font {
        .system(size: 17, weight: weight, design: .default)
    }

    static func body(weight: Font.Weight = .regular) -> Font {
        .system(size: 15, weight: weight, design: .default)
    }

    static func callout(weight: Font.Weight = .regular) -> Font {
        .system(size: 14, weight: weight, design: .default)
    }

    static func subheadline(weight: Font.Weight = .regular) -> Font {
        .system(size: 13, weight: weight, design: .default)
    }

    static func caption(weight: Font.Weight = .regular) -> Font {
        .system(size: 11, weight: weight, design: .default)
    }
}

struct AppAnimations {
    // Spring animations (Anthropic-style: responsive but refined)
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let springQuick = Animation.spring(response: 0.25, dampingFraction: 0.8)

    // Ease animations
    static let easeOut = Animation.easeOut(duration: 0.3)
    static let easeInOut = Animation.easeInOut(duration: 0.25)

    // Alternative options (commented for testing):
    // static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    // static let smooth = Animation.easeInOut(duration: 0.4)
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Time Selection State
struct TimeSelection: Equatable {
    var startSlotIndex: Int  // 0-95 (96 slots of 15 minutes)
    var endSlotIndex: Int    // 0-95

    var startTime: String {
        let hour = startSlotIndex / 4
        let minute = (startSlotIndex % 4) * 15
        return String(format: "%02d:%02d", hour, minute)
    }

    var endTime: String {
        let hour = endSlotIndex / 4
        let minute = (endSlotIndex % 4) * 15
        return String(format: "%02d:%02d", hour, minute)
    }

    var duration: Int {
        endSlotIndex - startSlotIndex
    }
}

// MARK: - Repetition Type
enum RepetitionType: String, CaseIterable, Hashable {
    case none = "No"
    case daily = "Every day"
    case weekly = "Every week"
    case monthly = "Every month"
    case yearly = "Every year"
}

// MARK: - Event Model
struct CalendarEvent: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var description: String
    var startSlotIndex: Int
    var endSlotIndex: Int
    var isAllDay: Bool
    var startDate: Date
    var endDate: Date
    var repetition: RepetitionType

    var startTime: String {
        let hour = startSlotIndex / 4
        let minute = (startSlotIndex % 4) * 15
        return String(format: "%02d:%02d", hour, minute)
    }

    var endTime: String {
        let hour = endSlotIndex / 4
        let minute = (endSlotIndex % 4) * 15
        return String(format: "%02d:%02d", hour, minute)
    }
}

struct ContentView: View {
    @State private var timeSelection: TimeSelection?
    @State private var sheetPosition: SheetPosition = .hidden
    @State private var events: [CalendarEvent] = []
    @State private var currentDate: Date = Date()
    @State private var showQuickNavigation: Bool = false
    @State private var shouldScrollMonthToToday: Bool = true
    @State private var buttonDragOffset: CGSize = .zero
    @State private var isDraggingButton: Bool = false
    @State private var dragStartLocation: CGPoint?

    // Carousel state
    @State private var dayCarouselOffset: CGFloat = 0
    @State private var isDraggingDay: Bool = false

    private var filteredAllDayEvents: [CalendarEvent] {
        events.filter { event in
            event.isAllDay && Calendar.current.isDate(event.startDate, inSameDayAs: currentDate)
        }
    }

    private var filteredTimedEvents: [CalendarEvent] {
        events.filter { event in
            !event.isAllDay && Calendar.current.isDate(event.startDate, inSameDayAs: currentDate)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    TopNavBar(
                        currentDate: currentDate,
                        onTodayTapped: {
                            animateToDate(Date())
                            shouldScrollMonthToToday = true
                        },
                        onMonthTapped: {
                            withAnimation(AppAnimations.spring) {
                                showQuickNavigation.toggle()
                            }
                        }
                    )

                    // Quick Navigation (conditionally shown)
                    if showQuickNavigation {
                        VStack(spacing: 0) {
                            MonthSelector(
                                currentDate: $currentDate,
                                shouldScrollToToday: $shouldScrollMonthToToday
                            )
                            Divider()
                            QuickDateSelector(currentDate: $currentDate)
                            Divider()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Day carousel with pre-rendered slides
                    ZStack {
                        // Previous day slide
                        if let prevDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) {
                            DayContentView(
                                date: prevDay,
                                timeSelection: $timeSelection,
                                events: events
                            )
                            .id("day-\(Calendar.current.startOfDay(for: prevDay).timeIntervalSince1970)")
                            .frame(width: geometry.size.width)
                            .offset(x: -geometry.size.width + dayCarouselOffset)
                        }

                        // Current day slide
                        DayContentView(
                            date: currentDate,
                            timeSelection: $timeSelection,
                            events: events
                        )
                        .id("day-\(Calendar.current.startOfDay(for: currentDate).timeIntervalSince1970)")
                        .frame(width: geometry.size.width)
                        .offset(x: dayCarouselOffset)

                        // Next day slide
                        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) {
                            DayContentView(
                                date: nextDay,
                                timeSelection: $timeSelection,
                                events: events
                            )
                            .id("day-\(Calendar.current.startOfDay(for: nextDay).timeIntervalSince1970)")
                            .frame(width: geometry.size.width)
                            .offset(x: geometry.size.width + dayCarouselOffset)
                        }
                    }
                    .clipped()
                    .animation(.easeOut(duration: 0.0), value: currentDate)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Only handle horizontal swipes for day navigation
                                guard !showQuickNavigation else { return }

                                let horizontalAmount = value.translation.width
                                let verticalAmount = abs(value.translation.height)

                                if abs(horizontalAmount) > verticalAmount {
                                    isDraggingDay = true
                                    dayCarouselOffset = horizontalAmount
                                }
                            }
                            .onEnded { value in
                                guard !showQuickNavigation else { return }
                                handleDaySwipe(value, screenWidth: geometry.size.width)
                            }
                    )
                }

                // Interactive Add Event Button
                AddEventButton()
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                    .offset(x: buttonDragOffset.width, y: buttonDragOffset.height)
                    .opacity(isDraggingButton ? 0.7 : 1.0)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                                if distance > 5 {
                                    isDraggingButton = true
                                    buttonDragOffset = value.translation
                                }
                            }
                            .onEnded { value in
                                let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                                if distance > 5 {
                                    handleButtonDrop(dragValue: value, geometry: geometry)
                                } else {
                                    handleButtonTap()
                                }
                            }
                    )

                // Event creation module
                if timeSelection != nil {
                    EventCreationModule(
                        timeSelection: $timeSelection,
                        sheetPosition: $sheetPosition,
                        currentDate: currentDate,
                        onAddEvent: { event in
                            events.append(event)
                        }
                    )
                }
            }
            .background(AppColors.background)
            .onChange(of: timeSelection) { _, newValue in
                if newValue != nil {
                    sheetPosition = .peek
                } else {
                    sheetPosition = .hidden
                }
            }
        }
    }

    private func animateToDate(_ date: Date) {
        withAnimation(AppAnimations.spring) {
            currentDate = date
            dayCarouselOffset = 0
        }
    }

    private func handleDaySwipe(_ gesture: DragGesture.Value, screenWidth: CGFloat) {
        let horizontalAmount = gesture.translation.width
        let verticalAmount = abs(gesture.translation.height)

        // Only handle horizontal swipes
        guard abs(horizontalAmount) > verticalAmount else {
            withAnimation(AppAnimations.spring) {
                dayCarouselOffset = 0
                isDraggingDay = false
            }
            return
        }

        let threshold = screenWidth * 0.3

        if abs(horizontalAmount) > threshold {
            if horizontalAmount < 0 {
                // Swipe left: go to next day
                if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) {
                    withAnimation(AppAnimations.spring) {
                        currentDate = nextDay
                        dayCarouselOffset = 0
                    }

                    // Update top nav month if month changed
                    updateMonthIfNeeded(newDate: nextDay)
                }
            } else {
                // Swipe right: go to previous day
                if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) {
                    withAnimation(AppAnimations.spring) {
                        currentDate = previousDay
                        dayCarouselOffset = 0
                    }

                    // Update top nav month if month changed
                    updateMonthIfNeeded(newDate: previousDay)
                }
            }
        } else {
            // Snap back
            withAnimation(AppAnimations.spring) {
                dayCarouselOffset = 0
            }
        }

        isDraggingDay = false
    }

    private func updateMonthIfNeeded(newDate: Date) {
        // This is just for top nav bar - it will update automatically via currentDate binding
    }

    private func handleButtonTap() {
        // Calculate next full hour
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        // Next full hour
        let nextHour = currentMinute > 0 ? currentHour + 1 : currentHour
        let startSlotIndex = nextHour * 4  // Each hour = 4 slots
        let endSlotIndex = min(startSlotIndex + 4, 95)  // +1 hour, max 95

        timeSelection = TimeSelection(
            startSlotIndex: startSlotIndex,
            endSlotIndex: endSlotIndex
        )

        withAnimation(AppAnimations.spring) {
            sheetPosition = .expanded
        }
    }

    private func handleButtonDrop(dragValue: DragGesture.Value, geometry: GeometryProxy) {
        // Calculate drop position relative to screen
        // Button starts at bottom right, so we need to calculate its initial position
        let screenHeight = geometry.size.height
        let buttonInitialY = screenHeight - 56 - 20  // button height + bottom padding
        let dropY = buttonInitialY + dragValue.translation.height

        // DayCanvas starts after TopNavBar + QuickNav (if shown) + DateRow + WholeDayRow
        // Approximate offset to canvas area (adjust based on your layout)
        let topOffset: CGFloat = showQuickNavigation ? 350 : 100  // Rough estimate

        if dropY > topOffset {
            // Calculate which slot based on Y position
            let canvasY = dropY - topOffset
            let slotHeight: CGFloat = 15
            let slotIndex = Int(canvasY / slotHeight)

            // Clamp to valid range (0-95)
            let startSlotIndex = max(0, min(slotIndex, 95))
            let endSlotIndex = min(startSlotIndex + 4, 95)  // +1 hour

            timeSelection = TimeSelection(
                startSlotIndex: startSlotIndex,
                endSlotIndex: endSlotIndex
            )

            withAnimation(AppAnimations.spring) {
                sheetPosition = .expanded
            }
        }

        // Reset button position
        withAnimation(AppAnimations.spring) {
            buttonDragOffset = .zero
            isDraggingButton = false
        }
    }
}

// MARK: - Day Content View
struct DayContentView: View {
    let date: Date
    @Binding var timeSelection: TimeSelection?
    let events: [CalendarEvent]

    private let calendar = Calendar.current

    private var filteredAllDayEvents: [CalendarEvent] {
        events.filter { event in
            event.isAllDay && calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }

    private var filteredTimedEvents: [CalendarEvent] {
        events.filter { event in
            !event.isAllDay && calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            DateRow(currentDate: date)
            WholeDayRow(events: filteredAllDayEvents)
            DayCanvas(
                timeSelection: $timeSelection,
                events: filteredTimedEvents
            )
        }
    }
}

// MARK: - Top Nav Bar
struct TopNavBar: View {
    let currentDate: Date
    let onTodayTapped: () -> Void
    let onMonthTapped: () -> Void

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentDate)
    }

    private var todayDayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left side - Month selector
            Button(action: onMonthTapped) {
                HStack(spacing: 10) {
                    Image(systemName: "line.3.horizontal")
                        .font(AppTypography.body(weight: .regular))
                        .foregroundColor(AppColors.textSecondary)

                    Text(monthName)
                        .font(AppTypography.headline(weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(AppTypography.caption(weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.surfaceElevated)
                .cornerRadius(10)
                .shadow(color: AppColors.textPrimary.opacity(0.04), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            // Right side - Actions
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(AppTypography.body(weight: .regular))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 38, height: 38)
                        .background(AppColors.surfaceElevated)
                        .cornerRadius(10)
                        .shadow(color: AppColors.textPrimary.opacity(0.04), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: onTodayTapped) {
                    Text(todayDayNumber)
                        .font(AppTypography.callout(weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(AppColors.accentSubtle)
                        .cornerRadius(10)
                        .shadow(color: AppColors.accent.opacity(0.08), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            AppColors.surface
                .shadow(color: AppColors.textPrimary.opacity(0.03), radius: 1, x: 0, y: 1)
        )
    }
}

// MARK: - Button Styles
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppAnimations.springQuick, value: configuration.isPressed)
            // Alternative: .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed) // Bouncy
    }
}

// MARK: - Date Row
struct DateRow: View {
    let currentDate: Date

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name for more elegance
        return formatter.string(from: currentDate)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: currentDate)
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentDate)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // UTC/Timezone Button
            Button(action: {}) {
                HStack(spacing: 6) {
                    Text("UTC+1")
                        .font(AppTypography.caption(weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(AppTypography.caption(weight: .regular))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppColors.surfaceElevated)
                .cornerRadius(8)
                .shadow(color: AppColors.textPrimary.opacity(0.03), radius: 4, x: 0, y: 1)
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            // Date Display - Elegant and spacious
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(dayOfWeek)
                    .font(AppTypography.body(weight: .regular))
                    .foregroundColor(AppColors.textSecondary)

                Text(dayNumber)
                    .font(AppTypography.largeTitle(weight: .medium))
                    .foregroundColor(AppColors.textPrimary)

                Text(monthName)
                    .font(AppTypography.body(weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.surface)
    }
}

// MARK: - Quick Date Selector
struct QuickDateSelector: View {
    @Binding var currentDate: Date
    let today: Date = Date()

    @State private var dragOffset: CGFloat = 0
    @State private var displayMonth: Date = Date()
    @State private var isDragging: Bool = false

    private let calendar = Calendar.current

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
                ZStack {
                    // Previous month (pre-rendered, shown only when dragging right)
                    if let prevMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth) {
                        MonthGridView(
                            month: prevMonth,
                            currentDate: currentDate,
                            today: today,
                            onDateTap: { date in
                                currentDate = date
                            }
                        )
                        .frame(width: geometry.size.width)
                        .offset(x: -geometry.size.width + dragOffset)
                        .opacity(isDragging && dragOffset > 0 ? 1 : 0)
                    }

                    // Current month (main/centered grid)
                    MonthGridView(
                        month: displayMonth,
                        currentDate: currentDate,
                        today: today,
                        onDateTap: { date in
                            currentDate = date
                        }
                    )
                    .frame(width: geometry.size.width)
                    .offset(x: dragOffset)

                    // Next month (pre-rendered, shown only when dragging left)
                    if let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayMonth) {
                        MonthGridView(
                            month: nextMonth,
                            currentDate: currentDate,
                            today: today,
                            onDateTap: { date in
                                currentDate = date
                            }
                        )
                        .frame(width: geometry.size.width)
                        .offset(x: geometry.size.width + dragOffset)
                        .opacity(isDragging && dragOffset < 0 ? 1 : 0)
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
            // Initialize display month to current date's month
            if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) {
                displayMonth = monthStart
            }
        }
        .onChange(of: currentDate) { _, newValue in
            // Update display month when current date changes from external source (e.g., month selector)
            if !calendar.isDate(newValue, equalTo: displayMonth, toGranularity: .month) {
                // No animation - just update state to prevent bounce
                if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: newValue)) {
                    displayMonth = monthStart
                }
            }
        }
    }

    private func handleSwipe(_ gesture: DragGesture.Value, screenWidth: CGFloat) {
        let threshold: CGFloat = screenWidth * 0.4 // Need to drag 40% to trigger
        let velocity = gesture.predictedEndTranslation.width - gesture.translation.width

        // Check velocity for quick swipes OR distance for slow drags
        let shouldNavigate = abs(gesture.translation.width) > threshold || abs(velocity) > 500

        if gesture.translation.width < 0 && shouldNavigate {
            // Swipe left: next month
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayMonth) {
                withAnimation(AppAnimations.spring) {
                    displayMonth = nextMonth
                    dragOffset = 0
                }
            } else {
                withAnimation(AppAnimations.spring) {
                    dragOffset = 0
                }
            }
        } else if gesture.translation.width > 0 && shouldNavigate {
            // Swipe right: previous month
            if let prevMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth) {
                withAnimation(AppAnimations.spring) {
                    displayMonth = prevMonth
                    dragOffset = 0
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
    let currentDate: Date
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
                        currentDate: currentDate,
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
    let currentDate: Date
    let today: Date
    let onTap: () -> Void

    private let calendar = Calendar.current

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: currentDate)
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

// MARK: - Month Selector
struct MonthSelector: View {
    @Binding var currentDate: Date
    @Binding var shouldScrollToToday: Bool
    let today: Date = Date()

    private let calendar = Calendar.current

    private var months: [(date: Date, name: String, isYear: Bool)] {
        var result: [(date: Date, name: String, isYear: Bool)] = []

        // Generate 36 months: 24 before today and 12 after today
        // This allows scrolling to previous months
        for offset in -24...12 {
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
                                currentDate: currentDate,
                                onTap: {
                                    currentDate = item.date
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
    let currentDate: Date
    let onTap: () -> Void

    private let calendar = Calendar.current

    private var isSelected: Bool {
        calendar.isDate(monthDate, equalTo: currentDate, toGranularity: .month)
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

// MARK: - Whole Day Row
struct WholeDayRow: View {
    let events: [CalendarEvent]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left: "All day" label
            Text("All day")
                .font(AppTypography.caption(weight: .medium))
                .foregroundColor(AppColors.textTertiary)
                .frame(width: 65, alignment: .trailing)
                .padding(.trailing, 12)

            // Right: All-day events
            VStack(spacing: 6) {
                ForEach(events) { event in
                    AllDayEventView(event: event)
                }

                if events.isEmpty {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 44)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppColors.borderSubtle)
                    .frame(height: 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColors.surface)
    }
}

// MARK: - All Day Event View
struct AllDayEventView: View {
    let event: CalendarEvent

    var body: some View {
        HStack {
            Text(event.title)
                .font(AppTypography.subheadline(weight: .medium))
                .foregroundColor(AppColors.eventBlue)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.eventBlueBg)
        .cornerRadius(8)
    }
}

// MARK: - Day Canvas
struct DayCanvas: View {
    @Binding var timeSelection: TimeSelection?
    let events: [CalendarEvent]
    private let hours = Array(0..<24)

    var body: some View {
        ScrollView(showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                // Left column: Hour labels
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(hours, id: \.self) { hour in
                        HourLabel(hour: hour)
                    }
                }
                .frame(width: 65)

                // Right column: Time slots with overlay
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        ForEach(0..<96, id: \.self) { slotIndex in
                            TimeSlotRow(
                                slotIndex: slotIndex,
                                onTap: {
                                    handleSlotTap(slotIndex: slotIndex)
                                }
                            )
                        }
                    }

                    // Events overlay
                    ForEach(events) { event in
                        EventView(event: event)
                    }

                    // Time selector overlay
                    if timeSelection != nil {
                        TimeSelector(
                            selection: $timeSelection,
                            totalSlots: 96
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(AppColors.surface)
    }

    private func handleSlotTap(slotIndex: Int) {
        // Round down to the nearest hour (4 slots = 1 hour)
        let roundedStart = (slotIndex / 4) * 4
        // Default duration: 1 hour (4 slots)
        let defaultEnd = min(roundedStart + 4, 95)

        timeSelection = TimeSelection(
            startSlotIndex: roundedStart,
            endSlotIndex: defaultEnd
        )
    }
}

struct HourLabel: View {
    let hour: Int

    private var timeString: String {
        String(format: "%02d:00", hour)
    }

    var body: some View {
        Text(timeString)
            .font(AppTypography.caption(weight: .regular))
            .foregroundColor(AppColors.textTertiary)
            .frame(height: 60, alignment: .top)
            .padding(.trailing, 12)
            .offset(y: -7)
    }
}

struct TimeSlotRow: View {
    let slotIndex: Int
    var onTap: () -> Void

    private var showBorder: Bool {
        slotIndex % 4 == 0
    }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 15)
            .overlay(alignment: .bottom) {
                if showBorder {
                    Rectangle()
                        .fill(AppColors.borderSubtle)
                        .frame(height: 1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Time Selector
struct TimeSelector: View {
    @Binding var selection: TimeSelection?
    let totalSlots: Int
    private let slotHeight: CGFloat = 15

    @State private var initialStart: Int = 0
    @State private var initialEnd: Int = 0

    var body: some View {
        guard let selection = selection else { return AnyView(EmptyView()) }

        let yOffset = CGFloat(selection.startSlotIndex) * slotHeight
        let height = CGFloat(selection.duration) * slotHeight

        return AnyView(
            ZStack(alignment: .topLeading) {
                // Main rectangle
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.accentSubtle.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.accent, lineWidth: 2)
                    )
                    .frame(height: height)
                    .shadow(color: AppColors.accent.opacity(0.1), radius: 8, x: 0, y: 2)
                    .overlay(
                        // Time display
                        VStack(spacing: 4) {
                            Text(selection.startTime)
                                .font(AppTypography.callout(weight: .semibold))
                            Text("-")
                                .font(AppTypography.caption(weight: .regular))
                            Text(selection.endTime)
                                .font(AppTypography.callout(weight: .semibold))
                        }
                        .foregroundColor(AppColors.textPrimary)
                    )
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 5)
                            .onChanged { value in
                                handleBodyDrag(value)
                            }
                            .onEnded { _ in
                                if let sel = self.selection {
                                    initialStart = sel.startSlotIndex
                                    initialEnd = sel.endSlotIndex
                                }
                            }
                    )

                // Top handle
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "arrow.up.and.down")
                            .font(AppTypography.caption(weight: .bold))
                            .foregroundColor(AppColors.surfaceElevated)
                    )
                    .shadow(color: AppColors.accent.opacity(0.25), radius: 4, x: 0, y: 2)
                    .position(x: 14, y: 0)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleTopHandleDrag(value)
                            }
                            .onEnded { _ in
                                if let sel = self.selection {
                                    initialStart = sel.startSlotIndex
                                    initialEnd = sel.endSlotIndex
                                }
                            }
                    )

                // Bottom handle
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "arrow.up.and.down")
                            .font(AppTypography.caption(weight: .bold))
                            .foregroundColor(AppColors.surfaceElevated)
                    )
                    .shadow(color: AppColors.accent.opacity(0.25), radius: 4, x: 0, y: 2)
                    .position(x: 14, y: height)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleBottomHandleDrag(value)
                            }
                            .onEnded { _ in
                                if let sel = self.selection {
                                    initialStart = sel.startSlotIndex
                                    initialEnd = sel.endSlotIndex
                                }
                            }
                    )
            }
            .offset(y: yOffset)
            .onAppear {
                initialStart = selection.startSlotIndex
                initialEnd = selection.endSlotIndex
            }
            .onChange(of: selection.startSlotIndex) { _, newValue in
                initialStart = newValue
            }
            .onChange(of: selection.endSlotIndex) { _, newValue in
                initialEnd = newValue
            }
        )
    }

    private func handleTopHandleDrag(_ value: DragGesture.Value) {
        let draggedSlots = Int(round(value.translation.height / slotHeight))
        let newStart = max(0, min(initialEnd - 1, initialStart + draggedSlots))

        self.selection = TimeSelection(
            startSlotIndex: newStart,
            endSlotIndex: initialEnd
        )
    }

    private func handleBottomHandleDrag(_ value: DragGesture.Value) {
        let draggedSlots = Int(round(value.translation.height / slotHeight))
        let newEnd = max(initialStart + 1, min(95, initialEnd + draggedSlots))

        self.selection = TimeSelection(
            startSlotIndex: initialStart,
            endSlotIndex: newEnd
        )
    }

    private func handleBodyDrag(_ value: DragGesture.Value) {
        let draggedSlots = Int(round(value.translation.height / slotHeight))
        let duration = initialEnd - initialStart

        var newStart = initialStart + draggedSlots
        var newEnd = initialEnd + draggedSlots

        // Ensure boundaries
        if newStart < 0 {
            newStart = 0
            newEnd = duration
        }
        if newEnd > 95 {
            newEnd = 95
            newStart = 95 - duration
        }

        self.selection = TimeSelection(
            startSlotIndex: newStart,
            endSlotIndex: newEnd
        )
    }
}

// MARK: - Event View
struct EventView: View {
    let event: CalendarEvent
    private let slotHeight: CGFloat = 15

    var body: some View {
        let yOffset = CGFloat(event.startSlotIndex) * slotHeight
        let height = CGFloat(event.endSlotIndex - event.startSlotIndex) * slotHeight

        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(AppTypography.subheadline(weight: .semibold))
                .foregroundColor(AppColors.eventBlue)
                .lineLimit(height > 40 ? 2 : 1)

            if !event.isAllDay && height > 40 {
                Text("\(event.startTime) - \(event.endTime)")
                    .font(AppTypography.caption(weight: .regular))
                    .foregroundColor(AppColors.eventBlue.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppColors.eventBlueBg)
        .cornerRadius(10)
        .shadow(color: AppColors.eventBlue.opacity(0.08), radius: 4, x: 0, y: 2)
        .frame(height: height)
        .offset(y: yOffset)
    }
}

// MARK: - Add Event Button
struct AddEventButton: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.accent)
                .frame(width: 60, height: 60)
                .shadow(color: AppColors.accent.opacity(0.3), radius: 12, x: 0, y: 4)

            Image(systemName: "plus")
                .font(AppTypography.title(weight: .semibold))
                .foregroundColor(AppColors.surfaceElevated)
        }
    }
}

// MARK: - Event Creation Module
enum SheetPosition {
    case hidden
    case peek      // Shows top portion
    case expanded  // Nearly full screen
}

struct EventCreationModule: View {
    @Binding var timeSelection: TimeSelection?
    @Binding var sheetPosition: SheetPosition
    let currentDate: Date
    let onAddEvent: (CalendarEvent) -> Void

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var isAllDay: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var repetition: RepetitionType = .none
    @State private var showDatePicker: Bool = false
    @State private var showTimePicker: Bool = false
    @State private var datePickerMode: DatePickerMode = .start
    @State private var timePickerMode: TimePickerMode = .start
    @FocusState private var isTitleFocused: Bool
    @State private var hasInitialized: Bool = false

    private let peekHeight: CGFloat = 80

    #if os(iOS)
    private let expandedHeight: CGFloat = UIScreen.main.bounds.height - 100
    #else
    private let expandedHeight: CGFloat = 600
    #endif

    private var isAddButtonEnabled: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    enum DatePickerMode {
        case start
        case end
    }

    enum TimePickerMode {
        case start
        case end
    }

    private func screenHeight(_ geometry: GeometryProxy) -> CGFloat {
        geometry.size.height
    }

    private func currentOffset(_ geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height
        switch sheetPosition {
        case .hidden:
            return height
        case .peek:
            return height - peekHeight + dragOffset
        case .expanded:
            return height - expandedHeight + dragOffset
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button("Cancel") {
                        handleCancel()
                    }
                    .font(AppTypography.body(weight: .regular))
                    .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    Text("New event")
                        .font(AppTypography.headline(weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Button("Add") {
                        handleAdd()
                    }
                    .font(AppTypography.body(weight: .semibold))
                    .foregroundColor(isAddButtonEnabled ? AppColors.accent : AppColors.textTertiary)
                    .disabled(!isAddButtonEnabled)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(AppColors.surfaceElevated)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(AppColors.border)
                        .frame(height: 1)
                }

                // Content
                ScrollView {
                    VStack(spacing: 12) {
                        // Section 1: Title and Description
                        VStack(spacing: 16) {
                            TextField("Add a title", text: $title)
                                .font(AppTypography.headline(weight: .regular))
                                .foregroundColor(AppColors.textPrimary)
                                .focused($isTitleFocused)

                            TextField("Description", text: $description, axis: .vertical)
                                .font(AppTypography.body(weight: .regular))
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(AppColors.surfaceElevated)
                        .cornerRadius(12)

                        // Section 2: Duration
                        VStack(spacing: 0) {
                            // All-day toggle
                            HStack {
                                Text("All day")
                                    .font(AppTypography.body(weight: .regular))
                                    .foregroundColor(AppColors.textPrimary)

                                Spacer()

                                Toggle("", isOn: $isAllDay)
                                    .labelsHidden()
                                    .tint(AppColors.accent)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)

                            Rectangle()
                                .fill(AppColors.borderSubtle)
                                .frame(height: 1)
                                .padding(.leading, 20)

                            // Start date and time
                            HStack {
                                Button(action: {
                                    datePickerMode = .start
                                    showDatePicker = true
                                }) {
                                    Text(formattedDate(startDate))
                                        .font(AppTypography.body(weight: .regular))
                                        .foregroundColor(AppColors.textPrimary)
                                }

                                Spacer()

                                if !isAllDay {
                                    Button(action: {
                                        timePickerMode = .start
                                        showTimePicker = true
                                    }) {
                                        Text(startTime)
                                            .font(AppTypography.body(weight: .medium))
                                            .foregroundColor(AppColors.accent)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .onChange(of: startDate) { _, newValue in
                                if newValue > endDate {
                                    endDate = newValue
                                }
                            }

                            Rectangle()
                                .fill(AppColors.borderSubtle)
                                .frame(height: 1)
                                .padding(.leading, 20)

                            // End date and time
                            HStack {
                                Button(action: {
                                    datePickerMode = .end
                                    showDatePicker = true
                                }) {
                                    Text(formattedDate(endDate))
                                        .font(AppTypography.body(weight: .regular))
                                        .foregroundColor(AppColors.textPrimary)
                                }

                                Spacer()

                                if !isAllDay {
                                    Button(action: {
                                        timePickerMode = .end
                                        showTimePicker = true
                                    }) {
                                        Text(endTime)
                                            .font(AppTypography.body(weight: .medium))
                                            .foregroundColor(AppColors.accent)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)

                            Rectangle()
                                .fill(AppColors.borderSubtle)
                                .frame(height: 1)
                                .padding(.leading, 20)

                            // Repeats
                            HStack {
                                Text("Repeats")
                                    .font(AppTypography.body(weight: .regular))
                                    .foregroundColor(AppColors.textPrimary)

                                Spacer()

                                Picker("", selection: $repetition) {
                                    ForEach(RepetitionType.allCases, id: \.self) { type in
                                        Text(type.rawValue)
                                            .tag(type)
                                    }
                                }
                                .labelsHidden()
                                .tint(AppColors.accent)
                                .frame(width: 150, alignment: .trailing)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .background(AppColors.surfaceElevated)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .background(AppColors.background)
            #if os(iOS)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            #else
            .cornerRadius(20, corners: [.topLeft, .topRight])
            #endif
            .shadow(color: AppColors.textPrimary.opacity(0.15), radius: 20, x: 0, y: -5)
            .offset(y: currentOffset(geometry))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.height
                        dragOffset = translation
                    }
                    .onEnded { value in
                        let translation = value.translation.height
                        let velocity = value.predictedEndTranslation.height - value.translation.height

                        withAnimation(AppAnimations.spring) {
                            if sheetPosition == .peek {
                                if translation < -50 || velocity < -100 {
                                    sheetPosition = .expanded
                                    isTitleFocused = true
                                } else if translation > 50 {
                                    handleCancel()
                                }
                            } else if sheetPosition == .expanded {
                                if translation > 100 || velocity > 100 {
                                    sheetPosition = .peek
                                    isTitleFocused = false
                                }
                            }
                            dragOffset = 0
                        }
                    }
            )
            .onTapGesture {
                if sheetPosition == .peek {
                    withAnimation(AppAnimations.spring) {
                        sheetPosition = .expanded
                        isTitleFocused = true
                    }
                }
            }
        }
        .ignoresSafeArea()
        .overlay(
            Group {
                if showDatePicker {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showDatePicker = false
                        }

                    VStack {
                        Spacer()
                        DatePickerCalendarModule(
                            selectedDate: datePickerMode == .start ? $startDate : $endDate,
                            showPicker: $showDatePicker
                        )
                        .transition(.move(edge: .bottom))
                    }
                    .ignoresSafeArea()
                }

                if showTimePicker {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showTimePicker = false
                        }

                    VStack {
                        Spacer()
                        TimePickerModule(
                            timeSelection: timePickerMode == .start ? Binding(
                                get: { timeSelection },
                                set: { newValue in
                                    if let newValue = newValue {
                                        timeSelection = newValue
                                        validateAndUpdateEndTime()
                                    }
                                }
                            ) : Binding(
                                get: { timeSelection },
                                set: { newValue in
                                    if let newValue = newValue {
                                        timeSelection = newValue
                                    }
                                }
                            ),
                            showPicker: $showTimePicker,
                            isStartTime: timePickerMode == .start
                        )
                        .transition(.move(edge: .bottom))
                    }
                    .ignoresSafeArea()
                }
            }
        )
        .onChange(of: sheetPosition) { _, newValue in
            // Initialize dates when sheet opens
            if newValue == .expanded && !hasInitialized {
                startDate = currentDate
                endDate = currentDate
                hasInitialized = true

                // Auto-focus title field when expanding
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTitleFocused = true
                }
            } else if newValue == .hidden {
                // Reset initialization flag when sheet closes
                hasInitialized = false
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        return formatter.string(from: date)
    }

    private var startTime: String {
        guard let selection = timeSelection else { return "10:00" }
        return selection.startTime
    }

    private var endTime: String {
        guard let selection = timeSelection else { return "11:00" }
        return selection.endTime
    }

    private func handleCancel() {
        withAnimation(AppAnimations.spring) {
            sheetPosition = .hidden
            timeSelection = nil
            title = ""
            description = ""
            isAllDay = false
            isTitleFocused = false
        }
    }

    private func validateAndUpdateEndTime() {
        guard let selection = timeSelection else { return }

        let calendar = Calendar.current
        let isSameDay = calendar.isDate(startDate, inSameDayAs: endDate)

        if isSameDay && selection.startSlotIndex >= selection.endSlotIndex {
            // Preserve duration and update end time
            let duration = selection.endSlotIndex - selection.startSlotIndex
            let newEnd = min(selection.startSlotIndex + abs(duration), 95)
            timeSelection = TimeSelection(
                startSlotIndex: selection.startSlotIndex,
                endSlotIndex: newEnd
            )
        }
    }

    private func handleAdd() {
        guard let selection = timeSelection,
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Create recurring events based on repetition type
        if repetition == .none {
            // Single event
            let event = CalendarEvent(
                title: title,
                description: description,
                startSlotIndex: selection.startSlotIndex,
                endSlotIndex: selection.endSlotIndex,
                isAllDay: isAllDay,
                startDate: startDate,
                endDate: endDate,
                repetition: repetition
            )
            onAddEvent(event)
        } else {
            // Create recurring events for the next year (52 weeks/365 days)
            createRecurringEvents(
                title: title,
                description: description,
                startSlotIndex: selection.startSlotIndex,
                endSlotIndex: selection.endSlotIndex,
                isAllDay: isAllDay,
                baseStartDate: startDate,
                baseEndDate: endDate,
                repetition: repetition
            )
        }

        // Close the module and reset
        withAnimation(AppAnimations.spring) {
            sheetPosition = .hidden
            timeSelection = nil
            title = ""
            description = ""
            isAllDay = false
            startDate = Date()
            endDate = Date()
            repetition = .none
            isTitleFocused = false
        }
    }

    private func createRecurringEvents(
        title: String,
        description: String,
        startSlotIndex: Int,
        endSlotIndex: Int,
        isAllDay: Bool,
        baseStartDate: Date,
        baseEndDate: Date,
        repetition: RepetitionType
    ) {
        let calendar = Calendar.current
        var occurrences: [Date] = []

        // Determine how many occurrences to create and the interval
        let (count, component): (Int, Calendar.Component) = {
            switch repetition {
            case .daily:
                return (365, .day)  // 365 days
            case .weekly:
                return (52, .weekOfYear)  // 52 weeks
            case .monthly:
                return (12, .month)  // 12 months
            case .yearly:
                return (5, .year)  // 5 years
            case .none:
                return (0, .day)
            }
        }()

        // Generate occurrence dates
        for i in 0..<count {
            if let newStartDate = calendar.date(byAdding: component, value: i, to: baseStartDate) {
                occurrences.append(newStartDate)
            }
        }

        // Create events for each occurrence
        for occurrenceDate in occurrences {
            // Calculate the time difference between baseStartDate and baseEndDate
            let timeDifference = calendar.dateComponents([.day, .hour, .minute], from: baseStartDate, to: baseEndDate)

            // Apply the same time difference to the occurrence date
            let occurrenceEndDate = calendar.date(byAdding: timeDifference, to: occurrenceDate) ?? occurrenceDate

            let event = CalendarEvent(
                title: title,
                description: description,
                startSlotIndex: startSlotIndex,
                endSlotIndex: endSlotIndex,
                isAllDay: isAllDay,
                startDate: occurrenceDate,
                endDate: occurrenceEndDate,
                repetition: repetition
            )
            onAddEvent(event)
        }
    }
}

// MARK: - Time Picker Module
struct TimePickerModule: View {
    @Binding var timeSelection: TimeSelection?
    @Binding var showPicker: Bool
    let isStartTime: Bool

    @State private var selectedHour: Int = 10
    @State private var selectedMinute: Int = 0

    init(timeSelection: Binding<TimeSelection?>, showPicker: Binding<Bool>, isStartTime: Bool) {
        self._timeSelection = timeSelection
        self._showPicker = showPicker
        self.isStartTime = isStartTime

        if let selection = timeSelection.wrappedValue {
            let slotIndex = isStartTime ? selection.startSlotIndex : selection.endSlotIndex
            self._selectedHour = State(initialValue: slotIndex / 4)
            self._selectedMinute = State(initialValue: (slotIndex % 4) * 15)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text(isStartTime ? "Select Start Time" : "Select End Time")
                .font(AppTypography.headline(weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, 24)
                .padding(.bottom, 20)

            // Time Picker
            HStack(spacing: 0) {
                // Hours picker
                Picker("Hour", selection: $selectedHour) {
                    ForEach(0..<24) { hour in
                        Text(String(format: "%02d", hour))
                            .tag(hour)
                    }
                }
                #if os(iOS)
                .pickerStyle(.wheel)
                #endif
                .frame(width: 80)

                Text(":")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)

                // Minutes picker
                Picker("Minute", selection: $selectedMinute) {
                    ForEach([0, 15, 30, 45], id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .tag(minute)
                    }
                }
                #if os(iOS)
                .pickerStyle(.wheel)
                #endif
                .frame(width: 80)
            }
            .frame(height: 200)

            // Confirm button
            Button(action: {
                updateTimeSelection()
                showPicker = false
            }) {
                Text("Confirm")
                    .font(AppTypography.body(weight: .semibold))
                    .foregroundColor(AppColors.surfaceElevated)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accent)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(AppColors.surfaceElevated)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: AppColors.textPrimary.opacity(0.15), radius: 20, x: 0, y: -5)
    }

    private func updateTimeSelection() {
        guard var selection = timeSelection else { return }

        let newSlotIndex = selectedHour * 4 + (selectedMinute / 15)

        if isStartTime {
            // Preserve duration when updating start time
            let currentDuration = selection.endSlotIndex - selection.startSlotIndex
            selection.startSlotIndex = newSlotIndex

            // If new start time would be after end time, preserve duration
            if newSlotIndex >= selection.endSlotIndex {
                let newEndIndex = min(newSlotIndex + currentDuration, 95)
                selection.endSlotIndex = newEndIndex
            }
        } else {
            selection.endSlotIndex = newSlotIndex
        }

        timeSelection = selection
    }
}

// MARK: - Date Picker Calendar Module
struct DatePickerCalendarModule: View {
    @Binding var selectedDate: Date
    @Binding var showPicker: Bool

    @State private var displayedMonth: Date
    @State private var tempSelectedDate: Date
    @State private var dragOffset: CGFloat = 0
    @State private var slideDirection: SlideDirection = .none

    enum SlideDirection {
        case none, left, right
    }

    init(selectedDate: Binding<Date>, showPicker: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._showPicker = showPicker
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue)
        self._tempSelectedDate = State(initialValue: selectedDate.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top row with month/year and navigation
            HStack {
                Text(monthYearString)
                    .font(AppTypography.headline(weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                HStack(spacing: 20) {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(AppTypography.body(weight: .medium))
                            .foregroundColor(AppColors.accent)
                    }

                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(AppTypography.body(weight: .medium))
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            // Week days row
            HStack(spacing: 0) {
                ForEach(["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"], id: \.self) { day in
                    Text(day)
                        .font(AppTypography.caption(weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // Calendar grid with carousel
            GeometryReader { geometry in
                ZStack {
                    // Previous month
                    if let prevMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
                        CalendarGridView(
                            month: prevMonth,
                            selectedDate: tempSelectedDate,
                            onDateTap: { date in
                                tempSelectedDate = date
                            }
                        )
                        .frame(width: geometry.size.width)
                        .offset(x: -geometry.size.width + dragOffset)
                    }

                    // Current month
                    CalendarGridView(
                        month: displayedMonth,
                        selectedDate: tempSelectedDate,
                        onDateTap: { date in
                            tempSelectedDate = date
                        }
                    )
                    .frame(width: geometry.size.width)
                    .offset(x: dragOffset)

                    // Next month
                    if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
                        CalendarGridView(
                            month: nextMonth,
                            selectedDate: tempSelectedDate,
                            onDateTap: { date in
                                tempSelectedDate = date
                            }
                        )
                        .frame(width: geometry.size.width)
                        .offset(x: geometry.size.width + dragOffset)
                    }
                }
                .clipped()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            handleSwipe(value, screenWidth: geometry.size.width)
                        }
                )
            }
            .frame(height: 280)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // Confirm button
            Button(action: {
                selectedDate = tempSelectedDate
                showPicker = false
            }) {
                Text("Confirm")
                    .font(AppTypography.body(weight: .semibold))
                    .foregroundColor(AppColors.surfaceElevated)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accent)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(AppColors.surfaceElevated)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: AppColors.textPrimary.opacity(0.15), radius: 20, x: 0, y: -5)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var datesInMonth: [Date?] {
        guard let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }

        let weekday = Calendar.current.component(.weekday, from: monthStart)
        let adjustedWeekday = weekday == 1 ? 6 : weekday - 2

        guard let monthRange = Calendar.current.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        var dates: [Date?] = []

        for _ in 0..<adjustedWeekday {
            dates.append(nil)
        }

        for day in monthRange {
            if let date = Calendar.current.date(byAdding: .day, value: day - 1, to: monthStart) {
                dates.append(date)
            }
        }

        return dates
    }

    private func previousMonth() {
        withAnimation(AppAnimations.easeInOut) {
            slideDirection = .right
            if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
                displayedMonth = newMonth
            }
        }
    }

    private func nextMonth() {
        withAnimation(AppAnimations.easeInOut) {
            slideDirection = .left
            if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
                displayedMonth = newMonth
            }
        }
    }

    private func handleSwipe(_ gesture: DragGesture.Value, screenWidth: CGFloat) {
        let threshold: CGFloat = screenWidth * 0.3

        if gesture.translation.width < -threshold {
            // Swipe left: next month
            if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
                withAnimation(AppAnimations.spring) {
                    displayedMonth = nextMonth
                    dragOffset = 0
                }
            } else {
                withAnimation(AppAnimations.spring) {
                    dragOffset = 0
                }
            }
        } else if gesture.translation.width > threshold {
            // Swipe right: previous month
            if let prevMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
                withAnimation(AppAnimations.spring) {
                    displayedMonth = prevMonth
                    dragOffset = 0
                }
            } else {
                withAnimation(AppAnimations.spring) {
                    dragOffset = 0
                }
            }
        } else {
            // Snap back
            withAnimation(AppAnimations.spring) {
                dragOffset = 0
            }
        }
    }
}

// MARK: - Calendar Grid View (for DatePicker)
struct CalendarGridView: View {
    let month: Date
    let selectedDate: Date
    let onDateTap: (Date) -> Void

    private let calendar = Calendar.current

    private var datesInMonth: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: monthStart)
        let adjustedWeekday = weekday == 1 ? 6 : weekday - 2

        guard let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        var dates: [Date?] = []

        for _ in 0..<adjustedWeekday {
            dates.append(nil)
        }

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                dates.append(date)
            }
        }

        return dates
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(Array(datesInMonth.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    DateCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: month, toGranularity: .month)
                    ) {
                        onDateTap(date)
                    }
                } else {
                    Color.clear
                        .frame(height: 40)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(AppTypography.body(weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? AppColors.surfaceElevated : (isCurrentMonth ? AppColors.textPrimary : AppColors.textTertiary))
                .frame(width: 44, height: 44)
                .background(isSelected ? AppColors.accent : Color.clear)
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#if os(iOS)
import UIKit

// Helper for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
#else
import AppKit

// macOS version using different corner approach
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RectCorner: OptionSet, Sendable {
    let rawValue: Int
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCorner: Shape, Sendable {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tl = corners.contains(.topLeft) ? radius : 0
        let tr = corners.contains(.topRight) ? radius : 0
        let bl = corners.contains(.bottomLeft) ? radius : 0
        let br = corners.contains(.bottomRight) ? radius : 0

        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        if tr > 0 {
            path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                       radius: tr,
                       startAngle: Angle(degrees: -90),
                       endAngle: Angle(degrees: 0),
                       clockwise: false)
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        if br > 0 {
            path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                       radius: br,
                       startAngle: Angle(degrees: 0),
                       endAngle: Angle(degrees: 90),
                       clockwise: false)
        }
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        if bl > 0 {
            path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
                       radius: bl,
                       startAngle: Angle(degrees: 90),
                       endAngle: Angle(degrees: 180),
                       clockwise: false)
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        if tl > 0 {
            path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
                       radius: tl,
                       startAngle: Angle(degrees: 180),
                       endAngle: Angle(degrees: 270),
                       clockwise: false)
        }

        return path
    }
}
#endif

#Preview {
    ContentView()
}
