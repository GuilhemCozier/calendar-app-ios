//
//  ContentView.swift
//  OpenCalendar
//
//  Created by Guilhem Cozier on 24/11/2025.
//

import SwiftUI

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
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                TopNavBar()
                DateRow()
                WholeDayRow(events: filteredAllDayEvents)
                DayCanvas(
                    timeSelection: $timeSelection,
                    events: filteredTimedEvents
                )
            }

            AddEventButton()
                .padding(.trailing, 20)
                .padding(.bottom, 20)

            // Event creation module
            if timeSelection != nil {
                EventCreationModule(
                    timeSelection: $timeSelection,
                    sheetPosition: $sheetPosition,
                    onAddEvent: { event in
                        events.append(event)
                    }
                )
            }
        }
        .background(Color.white)
        .onChange(of: timeSelection) { _, newValue in
            if newValue != nil {
                sheetPosition = .peek
            } else {
                sheetPosition = .hidden
            }
        }
    }
}

// MARK: - Top Nav Bar
struct TopNavBar: View {
    var body: some View {
        HStack {
            // Left side
            HStack(spacing: 12) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18))
                    .foregroundColor(.black)

                Text("November")
                    .font(.system(size: 15))
                    .foregroundColor(.black)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.black)
            }

            Spacer()

            // Right side
            HStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(.black)

                Text("19")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .frame(width: 32, height: 32)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

// MARK: - Date Row
struct DateRow: View {
    var body: some View {
        HStack {
            // UTC Button
            HStack(spacing: 4) {
                Text("UTC+1")
                    .font(.system(size: 11))
                    .foregroundColor(.black)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)

            Spacer()

            // Date Container
            VStack(spacing: 2) {
                Text("Wed")
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                Text("19")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
    }
}

// MARK: - Whole Day Row
struct WholeDayRow: View {
    let events: [CalendarEvent]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left: "All day" label
            Text("All day")
                .font(.system(size: 11))
                .foregroundColor(.black)
                .frame(width: 60, alignment: .trailing)
                .padding(.trailing, 8)

            // Right: All-day events
            VStack(spacing: 4) {
                ForEach(events) { event in
                    AllDayEventView(event: event)
                }

                if events.isEmpty {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 40)
                }
            }
            .overlay(alignment: .bottom) {
                Divider()
            }
        }
        .padding(.horizontal, 16)
        .background(Color.white)
    }
}

// MARK: - All Day Event View
struct AllDayEventView: View {
    let event: CalendarEvent

    var body: some View {
        HStack {
            Text(event.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 20)
        .background(Color.blue.opacity(0.8))
        .cornerRadius(4)
    }
}

// MARK: - Day Canvas
struct DayCanvas: View {
    @Binding var timeSelection: TimeSelection?
    let events: [CalendarEvent]
    private let hours = Array(0..<24)

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 0) {
                // Left column: Hour labels
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(hours, id: \.self) { hour in
                        HourLabel(hour: hour)
                    }
                }
                .frame(width: 60)

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
            .padding(.horizontal, 16)
        }
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
            .font(.system(size: 11))
            .foregroundColor(.black)
            .frame(height: 60, alignment: .top)
            .padding(.trailing, 8)
            .offset(y: -6)
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
                    Divider()
                        .background(Color.gray.opacity(0.2))
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
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .frame(height: height)
                    .overlay(
                        // Time display
                        VStack(spacing: 4) {
                            Text(selection.startTime)
                                .font(.system(size: 14, weight: .semibold))
                            Text("-")
                                .font(.system(size: 12))
                            Text(selection.endTime)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.black)
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
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "arrow.up.and.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                    )
                    .position(x: 12, y: 0)
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
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "arrow.up.and.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                    )
                    .position(x: 12, y: height)
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

        VStack(alignment: .leading, spacing: 2) {
            Text(event.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(3)

            if !event.isAllDay && height > 30 {
                Text("\(event.startTime) - \(event.endTime)")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(6)
        .background(Color.blue.opacity(0.8))
        .cornerRadius(6)
        .frame(height: height)
        .offset(y: yOffset)
    }
}

// MARK: - Add Event Button
struct AddEventButton: View {
    var body: some View {
        Button(action: {
            // Action to add event
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 56, height: 56)
                .background(Color.gray.opacity(0.8))
                .clipShape(Circle())
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
    let onAddEvent: (CalendarEvent) -> Void

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var isAllDay: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var showDatePicker: Bool = false
    @State private var showTimePicker: Bool = false
    @State private var datePickerMode: DatePickerMode = .start
    @State private var timePickerMode: TimePickerMode = .start
    @FocusState private var isTitleFocused: Bool

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
                    .foregroundColor(.black)

                    Spacer()

                    Text("New event")
                        .font(.system(size: 17, weight: .semibold))

                    Spacer()

                    Button("Add") {
                        handleAdd()
                    }
                    .foregroundColor(isAddButtonEnabled ? .blue : .gray)
                    .fontWeight(.semibold)
                    .disabled(!isAddButtonEnabled)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(alignment: .bottom) {
                    Divider()
                }

                // Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Section 1: Title and Description
                        VStack(spacing: 12) {
                            TextField("Add a title", text: $title)
                                .font(.system(size: 17))
                                .foregroundColor(.black)
                                .focused($isTitleFocused)

                            TextField("Description", text: $description, axis: .vertical)
                                .font(.system(size: 15))
                                .foregroundColor(.black)
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .overlay(alignment: .bottom) {
                            Divider()
                        }

                        // Section 2: Duration
                        VStack(spacing: 0) {
                            // All-day toggle
                            HStack {
                                Text("All day")
                                    .font(.system(size: 17))
                                    .foregroundColor(.black)

                                Spacer()

                                Toggle("", isOn: $isAllDay)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            Divider()
                                .padding(.leading, 16)

                            // Start date and time
                            HStack {
                                Button(action: {
                                    datePickerMode = .start
                                    showDatePicker = true
                                }) {
                                    Text(formattedDate(startDate))
                                        .font(.system(size: 17))
                                        .foregroundColor(.black)
                                }

                                Spacer()

                                if !isAllDay {
                                    Button(action: {
                                        timePickerMode = .start
                                        showTimePicker = true
                                    }) {
                                        Text(startTime)
                                            .font(.system(size: 17))
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .onChange(of: startDate) { _, newValue in
                                if newValue > endDate {
                                    endDate = newValue
                                }
                            }

                            Divider()
                                .padding(.leading, 16)

                            // End date and time
                            HStack {
                                Button(action: {
                                    datePickerMode = .end
                                    showDatePicker = true
                                }) {
                                    Text(formattedDate(endDate))
                                        .font(.system(size: 17))
                                        .foregroundColor(.black)
                                }

                                Spacer()

                                if !isAllDay {
                                    Button(action: {
                                        timePickerMode = .end
                                        showTimePicker = true
                                    }) {
                                        Text(endTime)
                                            .font(.system(size: 17))
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            Divider()
                                .padding(.leading, 16)

                            // Repeats
                            HStack {
                                Text("Repeats")
                                    .font(.system(size: 17))
                                    .foregroundColor(.black)

                                Spacer()

                                Text("No")
                                    .font(.system(size: 17))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(Color.white)
                        .overlay(alignment: .bottom) {
                            Divider()
                        }
                    }
                }
            }
            .background(Color.gray.opacity(0.05))
            #if os(iOS)
            .cornerRadius(16, corners: [.topLeft, .topRight])
            #else
            .cornerRadius(16, corners: [.topLeft, .topRight])
            #endif
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -2)
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

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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

        let event = CalendarEvent(
            title: title,
            description: description,
            startSlotIndex: selection.startSlotIndex,
            endSlotIndex: selection.endSlotIndex,
            isAllDay: isAllDay,
            startDate: startDate,
            endDate: endDate
        )

        onAddEvent(event)

        // Close the module and reset
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            sheetPosition = .hidden
            timeSelection = nil
            title = ""
            description = ""
            isAllDay = false
            startDate = Date()
            endDate = Date()
            isTitleFocused = false
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
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .padding(.top, 20)
                .padding(.bottom, 16)

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
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.white)
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -2)
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)

                Spacer()

                HStack(spacing: 16) {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                    }

                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Week days row
            HStack(spacing: 0) {
                ForEach(["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(datesInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DateCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: tempSelectedDate),
                            isCurrentMonth: Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month)
                        ) {
                            tempSelectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -50 {
                            nextMonth()
                        } else if value.translation.width > 50 {
                            previousMonth()
                        }
                    }
            )

            // Confirm button
            Button(action: {
                selectedDate = tempSelectedDate
                showPicker = false
            }) {
                Text("Confirm")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.white)
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -2)
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
        withAnimation(.easeInOut(duration: 0.3)) {
            slideDirection = .right
            if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
                displayedMonth = newMonth
            }
        }
    }

    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            slideDirection = .left
            if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
                displayedMonth = newMonth
            }
        }
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
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .white : (isCurrentMonth ? .black : .gray))
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.blue : Color.clear)
                .clipShape(Circle())
        }
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
