//
//  ContentView.swift
//  OpenCalendar
//
//  Created by Guilhem Cozier on 24/11/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var timeSelection: TimeSelection?
    @State private var sheetPosition: SheetPosition = .hidden
    @State private var events: [CalendarEvent] = []
    @State private var viewedDate: Date = Date()
    @State private var showQuickNavigation: Bool = false
    @State private var shouldScrollMonthToToday: Bool = true
    @State private var buttonDragOffset: CGSize = .zero
    @State private var isDraggingButton: Bool = false
    @State private var dragStartLocation: CGPoint?

    // Carousel state
    @State private var dayCarouselOffset: CGFloat = 0
    @State private var isDraggingDay: Bool = false

    // Side panel state
    @State private var showSidePanel: Bool = false
    @State private var selectedViewMode: ViewMode = .oneDay

    private var filteredAllDayEvents: [CalendarEvent] {
        events.filter { event in
            event.isAllDay && Calendar.current.isDate(event.startDate, inSameDayAs: viewedDate)
        }
    }

    private var filteredTimedEvents: [CalendarEvent] {
        events.filter { event in
            !event.isAllDay && Calendar.current.isDate(event.startDate, inSameDayAs: viewedDate)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Side Panel
                if showSidePanel {
                    SidePanel(isVisible: $showSidePanel, selectedViewMode: $selectedViewMode)
                        .transition(.move(edge: .leading))
                }

                // Main App Content
                ZStack(alignment: .bottomTrailing) {
                    VStack(spacing: 0) {
                        TopNavBar(
                            viewedDate: viewedDate,
                            showQuickNavigation: showQuickNavigation,
                            onTodayTapped: {
                                animateToDate(Date())
                                shouldScrollMonthToToday = true
                            },
                            onMonthTapped: {
                                withAnimation(AppAnimations.spring) {
                                    showQuickNavigation.toggle()
                                }
                            },
                            onMenuTapped: {
                                withAnimation(AppAnimations.spring) {
                                    showSidePanel.toggle()
                                }
                            }
                        )

                    // Quick Navigation (conditionally shown)
                    if showQuickNavigation {
                        VStack(spacing: 0) {
                            MonthSelector(
                                viewedDate: $viewedDate,
                                shouldScrollToToday: $shouldScrollMonthToToday
                            )
                            Divider()
                            QuickDateSelector(viewedDate: $viewedDate)
                            Divider()
                        }
                        .transition(.opacity)
                    }

                    // Main content area - switches based on view mode
                    if selectedViewMode == .oneDay {
                        // Day carousel with pre-rendered slides (existing single-day view)
                        ZStack {
                            // Previous day slide
                            if let prevDay = Calendar.current.date(byAdding: .day, value: -1, to: viewedDate) {
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
                                date: viewedDate,
                                timeSelection: $timeSelection,
                                events: events
                            )
                            .id("day-\(Calendar.current.startOfDay(for: viewedDate).timeIntervalSince1970)")
                            .frame(width: geometry.size.width)
                            .offset(x: dayCarouselOffset)

                            // Next day slide
                            if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: viewedDate) {
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
                        .animation(.easeOut(duration: 0.0), value: viewedDate)
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
                    } else {
                        // Multi-day view (3 days or week)
                        MultiDayView(
                            startDate: viewedDate,
                            numberOfDays: selectedViewMode.numberOfDays,
                            timeSelection: $timeSelection,
                            events: events
                        )
                    }
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
                        viewedDate: viewedDate,
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
    }

    private func animateToDate(_ date: Date) {
        withAnimation(AppAnimations.spring) {
            viewedDate = date
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
                if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: viewedDate) {
                    // Smoothly complete the swipe animation - the next day slides in from the right
                    withAnimation(AppAnimations.spring) {
                        dayCarouselOffset = -screenWidth
                    }

                    // Wait for the animation to complete, THEN update the date and reset offset
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.viewedDate = nextDay
                        self.dayCarouselOffset = 0
                        self.isDraggingDay = false

                        // Update top nav month if month changed
                        self.updateMonthIfNeeded(newDate: nextDay)
                    }
                } else {
                    isDraggingDay = false
                }
            } else {
                // Swipe right: go to previous day
                if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: viewedDate) {
                    // Smoothly complete the swipe animation - the previous day slides in from the left
                    withAnimation(AppAnimations.spring) {
                        dayCarouselOffset = screenWidth
                    }

                    // Wait for the animation to complete, THEN update the date and reset offset
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.viewedDate = previousDay
                        self.dayCarouselOffset = 0
                        self.isDraggingDay = false

                        // Update top nav month if month changed
                        self.updateMonthIfNeeded(newDate: previousDay)
                    }
                } else {
                    isDraggingDay = false
                }
            }
        } else {
            // Snap back
            withAnimation(AppAnimations.spring) {
                dayCarouselOffset = 0
            }
            isDraggingDay = false
        }
    }

    private func updateMonthIfNeeded(newDate: Date) {
        // This is just for top nav bar - it will update automatically via viewedDate binding
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

#Preview {
    ContentView()
}
