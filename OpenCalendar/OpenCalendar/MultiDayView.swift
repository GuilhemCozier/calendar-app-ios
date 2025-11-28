//
//  MultiDayView.swift
//  OpenCalendar
//
//  Created by Guilhem Cozier on 24/11/2025.
//

import SwiftUI

// MARK: - Multi Day View

struct MultiDayView: View {
    let startDate: Date
    let numberOfDays: Int
    @Binding var timeSelection: DayTimeSelection?
    let events: [CalendarEvent]
    @Binding var carouselOffset: CGFloat
    @Binding var isDragging: Bool

    private let calendar = Calendar.current

    // Use carousel intervals matching the view mode to prevent overlapping days
    private var carouselInterval: Int {
        numberOfDays
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Date headers row
                HStack(spacing: 0) {
                    // Spacer for hour labels column
                    Spacer()
                        .frame(width: 65)

                    // Date headers carousel
                    ZStack {
                        // Previous range headers
                        if let prevStart = calendar.date(byAdding: .day, value: -carouselInterval, to: startDate) {
                            DateHeadersRow(
                                startDate: prevStart,
                                numberOfDays: numberOfDays,
                                width: geometry.size.width - 65
                            )
                            .offset(x: -(geometry.size.width - 65) + carouselOffset)
                        }

                        // Current range headers
                        DateHeadersRow(
                            startDate: startDate,
                            numberOfDays: numberOfDays,
                            width: geometry.size.width - 65
                        )
                        .offset(x: carouselOffset)

                        // Next range headers
                        if let nextStart = calendar.date(byAdding: .day, value: carouselInterval, to: startDate) {
                            DateHeadersRow(
                                startDate: nextStart,
                                numberOfDays: numberOfDays,
                                width: geometry.size.width - 65
                            )
                            .offset(x: (geometry.size.width - 65) + carouselOffset)
                        }
                    }
                    .clipped()
                }
                .frame(height: 56)

                // Single all-day row with label + day columns
                HStack(spacing: 0) {
                    // "All day" label (matches hour labels width)
                    Text("All day")
                        .font(AppTypography.caption(weight: .regular))
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 65, alignment: .trailing)
                        .padding(.trailing, 12)

                    // All-day events carousel
                    ZStack {
                        // Previous range all-day events
                        if let prevStart = calendar.date(byAdding: .day, value: -carouselInterval, to: startDate) {
                            AllDayEventsRow(
                                startDate: prevStart,
                                numberOfDays: numberOfDays,
                                events: events,
                                width: geometry.size.width - 65
                            )
                            .offset(x: -(geometry.size.width - 65) + carouselOffset)
                        }

                        // Current range all-day events
                        AllDayEventsRow(
                            startDate: startDate,
                            numberOfDays: numberOfDays,
                            events: events,
                            width: geometry.size.width - 65
                        )
                        .offset(x: carouselOffset)

                        // Next range all-day events
                        if let nextStart = calendar.date(byAdding: .day, value: carouselInterval, to: startDate) {
                            AllDayEventsRow(
                                startDate: nextStart,
                                numberOfDays: numberOfDays,
                                events: events,
                                width: geometry.size.width - 65
                            )
                            .offset(x: (geometry.size.width - 65) + carouselOffset)
                        }
                    }
                    .clipped()
                }
                .background(AppColors.surface)

                // Single synchronized ScrollView for hour labels + time grids
                ScrollView(showsIndicators: false) {
                    HStack(alignment: .top, spacing: 0) {
                        // Hour labels column
                        HourLabelsColumn()

                        // Time grids carousel
                        ZStack {
                            // Previous range
                            if let prevStart = calendar.date(byAdding: .day, value: -carouselInterval, to: startDate) {
                                TimeGridsRow(
                                    startDate: prevStart,
                                    numberOfDays: numberOfDays,
                                    timeSelection: $timeSelection,
                                    events: events,
                                    width: geometry.size.width - 65
                                )
                                .offset(x: -(geometry.size.width - 65) + carouselOffset)
                                .allowsHitTesting(false)
                            }

                            // Current range
                            TimeGridsRow(
                                startDate: startDate,
                                numberOfDays: numberOfDays,
                                timeSelection: $timeSelection,
                                events: events,
                                width: geometry.size.width - 65
                            )
                            .offset(x: carouselOffset)

                            // Next range
                            if let nextStart = calendar.date(byAdding: .day, value: carouselInterval, to: startDate) {
                                TimeGridsRow(
                                    startDate: nextStart,
                                    numberOfDays: numberOfDays,
                                    timeSelection: $timeSelection,
                                    events: events,
                                    width: geometry.size.width - 65
                                )
                                .offset(x: (geometry.size.width - 65) + carouselOffset)
                                .allowsHitTesting(false)
                            }
                        }
                        .clipped()
                    }
                    .padding(.top, 8)
                }
                .background(AppColors.surface)
            }
        }
    }
}

// MARK: - Date Headers Row

struct DateHeadersRow: View {
    let startDate: Date
    let numberOfDays: Int
    let width: CGFloat

    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<numberOfDays, id: \.self) { dayOffset in
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                    DateRow(viewedDate: date)
                        .frame(width: width / CGFloat(numberOfDays))
                }
            }
        }
        .frame(width: width)
    }
}

// MARK: - All-Day Events Row (without labels)

struct AllDayEventsRow: View {
    let startDate: Date
    let numberOfDays: Int
    let events: [CalendarEvent]
    let width: CGFloat

    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<numberOfDays, id: \.self) { dayOffset in
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                    DayAllDayEventsColumn(date: date, events: events)
                        .frame(width: width / CGFloat(numberOfDays))
                }
            }
        }
        .frame(width: width)
    }
}

// MARK: - Day All-Day Events Column (just events, no label)

struct DayAllDayEventsColumn: View {
    let date: Date
    let events: [CalendarEvent]

    private let calendar = Calendar.current

    private var filteredAllDayEvents: [CalendarEvent] {
        events.filter { event in
            event.isAllDay && calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ForEach(filteredAllDayEvents) { event in
                AllDayEventView(event: event)
            }

            if filteredAllDayEvents.isEmpty {
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
        .padding(.vertical, 12)
    }
}

// MARK: - Time Grids Row

struct TimeGridsRow: View {
    let startDate: Date
    let numberOfDays: Int
    @Binding var timeSelection: DayTimeSelection?
    let events: [CalendarEvent]
    let width: CGFloat

    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<numberOfDays, id: \.self) { dayOffset in
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                    TimeGrid(
                        date: date,
                        timeSelection: $timeSelection,
                        events: events
                    )
                    .frame(width: width / CGFloat(numberOfDays))
                }
            }
        }
        .frame(width: width)
    }
}
