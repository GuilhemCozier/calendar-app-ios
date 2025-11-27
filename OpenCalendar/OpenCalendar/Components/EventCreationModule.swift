//
//  EventCreationModule.swift
//  OpenCalendar
//
//  Created by Claude Code on 2025-11-27.
//

import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - Sheet Position
enum SheetPosition {
    case hidden
    case peek      // Shows top portion
    case expanded  // Nearly full screen
}

// MARK: - Event Creation Module
struct EventCreationModule: View {
    @Binding var timeSelection: TimeSelection?
    @Binding var sheetPosition: SheetPosition
    let viewedDate: Date
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
                                    .toggleStyle(BallToggleStyle(onColor: Color(hex: "#2196F3")))
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
                startDate = viewedDate
                endDate = viewedDate
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

            // Time Wheel Picker with unified selection indicator
            ZStack {
                // Unified selection indicator background (spans both wheels)
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.accentSubtle.opacity(0.3))
                    .frame(height: 40)

                HStack(spacing: 0) {
                    // Hours wheel
                    TimeWheelPicker(
                        selection: $selectedHour,
                        items: Array(0..<24),
                        itemHeight: 40
                    )
                    .frame(width: 80)

                    Text(":")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, 8)

                    // Minutes wheel (0-59)
                    TimeWheelPicker(
                        selection: $selectedMinute,
                        items: Array(0..<60),
                        itemHeight: 40
                    )
                    .frame(width: 80)
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 20)

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

        // Convert hour and minute to slot index (round to nearest 15-minute slot)
        let roundedMinute = (selectedMinute / 15) * 15
        let newSlotIndex = selectedHour * 4 + (roundedMinute / 15)

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

// MARK: - Custom Time Wheel Picker with 3D Depth Effect
struct TimeWheelPicker: View {
    @Binding var selection: Int
    let items: [Int]
    let itemHeight: CGFloat

    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let itemCount: Int

    init(selection: Binding<Int>, items: [Int], itemHeight: CGFloat) {
        self._selection = selection
        self.items = items
        self.itemHeight = itemHeight
        self.itemCount = items.count
    }

    var body: some View {
        GeometryReader { geometry in
            let centerY = geometry.size.height / 2
            let totalOffset = offset + dragOffset

            // ADJUSTMENT POINT: To fine-tune vertical centering, modify the value below
            // Positive values move numbers UP, negative values move numbers DOWN
            let centeringAdjustment: CGFloat = -100  // Adjust this value (e.g., -2, -5, +3)

            ZStack {
                // Render multiple copies for infinite scrolling
                ForEach(-2...2, id: \.self) { cycle in
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        let absoluteIndex = cycle * itemCount + index
                        let itemOffset = CGFloat(absoluteIndex) * itemHeight - totalOffset

                        if abs(itemOffset) < geometry.size.height {
                            TimeWheelItem(
                                value: item,
                                itemHeight: itemHeight,
                                offset: itemOffset
                            )
                            .frame(height: itemHeight)
                            .offset(y: centerY + centeringAdjustment)
                            .allowsHitTesting(false)  // Disable individual tap, use wheel-wide gesture
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())  // Make entire area interactive
            .gesture(
                DragGesture(minimumDistance: 0)  // Respond immediately to touch
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        // Capture the drag amount BEFORE GestureState resets to 0
                        let dragAmount = value.translation.height
                        let velocity = value.predictedEndTranslation.height - value.translation.height

                        // Immediately update offset to include drag (prevents visual jump when dragOffset resets)
                        offset = offset + dragAmount

                        // Calculate target offset with velocity
                        var targetOffset = offset

                        // Add velocity influence
                        if abs(velocity) > 100 {
                            targetOffset += velocity * 0.1
                        }

                        // Snap to nearest item
                        let snappedOffset = round(targetOffset / itemHeight) * itemHeight

                        // Animate to snapped position
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            offset = snappedOffset
                        }

                        // Update selection based on snapped position
                        let selectedIndex = Int(round(snappedOffset / itemHeight))
                        let wrappedIndex = ((selectedIndex % itemCount) + itemCount) % itemCount
                        selection = items[wrappedIndex]
                    }
            )
            .onAppear {
                // Initialize offset based on selection
                if let index = items.firstIndex(of: selection) {
                    offset = CGFloat(index) * itemHeight
                }
            }
        }
        .clipped()
    }
}

// MARK: - Time Wheel Item with 3D Effect
struct TimeWheelItem: View {
    let value: Int
    let itemHeight: CGFloat
    let offset: CGFloat

    var body: some View {
        // Normalize distance from center (-1 to 1 for items within 1 item distance)
        let normalizedDistance = offset / itemHeight

        // 3D depth effect: scale and opacity based on distance from center
        // At center (offset = 0): scale = 1.0, opacity = 1.0
        // At 1 item away: scale = 0.85, opacity = 0.5
        // At 2+ items away: scale = 0.7, opacity = 0.2
        let absDistance = abs(normalizedDistance)
        let scale = max(0.7, 1.0 - absDistance * 0.15)
        let opacity = max(0.2, 1.0 - absDistance * 0.5)

        // Rotation: -30° to +30° max, but limit to prevent flipping
        // Items above center rotate "away" (positive x-axis rotation)
        // Items below center rotate "away" (negative x-axis rotation)
        let rotationAngle = min(max(normalizedDistance * -30, -30), 30)

        return Text(String(format: "%02d", value))
            .font(.system(size: 28, weight: .medium))
            .foregroundColor(AppColors.textPrimary)
            .opacity(opacity)
            .scaleEffect(scale)
            .rotation3DEffect(
                .degrees(rotationAngle),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.5
            )
            .frame(maxWidth: .infinity)
            .frame(height: itemHeight)
            .offset(y: offset)
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
    @State private var containerWidth: CGFloat = 0

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
                        .animation(nil, value: displayedMonth)
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
                    .animation(nil, value: displayedMonth)
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
                        .animation(nil, value: displayedMonth)
                        .frame(width: geometry.size.width)
                        .offset(x: geometry.size.width + dragOffset)
                    }
                }
                .clipped()
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            handleSwipe(value, screenWidth: geometry.size.width)
                        }
                )
                .onAppear {
                    containerWidth = geometry.size.width
                }
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
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
            // Animate slide to the right (previous month comes from left)
            withAnimation(AppAnimations.spring) {
                dragOffset = containerWidth
            }

            // Wait for animation to complete, then update month and reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // Disable all animations for the state update to prevent date cells from animating
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    self.displayedMonth = newMonth
                    self.dragOffset = 0
                }
            }
        }
    }

    private func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
            // Animate slide to the left (next month comes from right)
            withAnimation(AppAnimations.spring) {
                dragOffset = -containerWidth
            }

            // Wait for animation to complete, then update month and reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // Disable all animations for the state update to prevent date cells from animating
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    self.displayedMonth = newMonth
                    self.dragOffset = 0
                }
            }
        }
    }

    private func handleSwipe(_ gesture: DragGesture.Value, screenWidth: CGFloat) {
        let threshold: CGFloat = screenWidth * 0.3

        if gesture.translation.width < -threshold {
            // Swipe left: next month
            if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
                // Smoothly complete the swipe animation - the next month slides in from the right
                withAnimation(AppAnimations.spring) {
                    dragOffset = -screenWidth
                }

                // Wait for the animation to complete, THEN update the month and reset offset
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    // Disable all animations for the state update to prevent date cells from animating
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        self.displayedMonth = nextMonth
                        self.dragOffset = 0
                    }
                }
            } else {
                withAnimation(AppAnimations.spring) {
                    dragOffset = 0
                }
            }
        } else if gesture.translation.width > threshold {
            // Swipe right: previous month
            if let prevMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
                // Smoothly complete the swipe animation - the previous month slides in from the left
                withAnimation(AppAnimations.spring) {
                    dragOffset = screenWidth
                }

                // Wait for the animation to complete, THEN update the month and reset offset
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    // Disable all animations for the state update to prevent date cells from animating
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        self.displayedMonth = prevMonth
                        self.dragOffset = 0
                    }
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

// MARK: - Ball Toggle Style
struct BallToggleStyle: ToggleStyle {
    let onColor: Color
    let offColor: Color
    let ballColor: Color

    init(onColor: Color = Color(hex: "#2196F3"), offColor: Color = Color(hex: "#E0E0E0"), ballColor: Color = .white) {
        self.onColor = onColor
        self.offColor = offColor
        self.ballColor = ballColor
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                // Background capsule
                Capsule()
                    .fill(configuration.isOn ? onColor : offColor)
                    .frame(width: 51, height: 31)

                // Ball
                Circle()
                    .fill(ballColor)
                    .frame(width: 27, height: 27)
                    .padding(2)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}
