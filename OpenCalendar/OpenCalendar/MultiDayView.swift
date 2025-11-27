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
    @Binding var timeSelection: TimeSelection?
    let events: [CalendarEvent]

    private let calendar = Calendar.current

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Hour labels column (shared for all days)
                VStack(spacing: 0) {
                    // Spacer for date row height
                    Spacer()
                        .frame(height: 56)

                    // Spacer for whole day row (if needed)
                    Spacer()
                        .frame(height: 0)

                    // Hour labels
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                HourLabel(hour: hour)
                            }
                        }
                    }
                    .scrollDisabled(true)
                }
                .frame(width: 60)

                // Day columns
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(0..<numberOfDays, id: \.self) { dayOffset in
                            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                                DayColumn(
                                    date: date,
                                    timeSelection: $timeSelection,
                                    events: events
                                )
                                .frame(width: (geometry.size.width - 60) / CGFloat(numberOfDays))
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Day Column

struct DayColumn: View {
    let date: Date
    @Binding var timeSelection: TimeSelection?
    let events: [CalendarEvent]
    @State private var selectionStart: Int?
    @State private var selectionEnd: Int?
    @State private var isDragging = false

    private let calendar = Calendar.current

    private var filteredTimedEvents: [CalendarEvent] {
        events.filter { event in
            !event.isAllDay && calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Date header
            DateRow(viewedDate: date)

            // Interactive time slots with events
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Time slot grid (interactive)
                    VStack(spacing: 0) {
                        ForEach(0..<96, id: \.self) { slotIndex in
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 15)
                                .border(AppColors.borderSubtle, width: 0.5)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            handleDragChanged(value, slotIndex: slotIndex)
                                        }
                                        .onEnded { _ in
                                            handleDragEnded()
                                        }
                                )
                        }
                    }

                    // Time selection overlay
                    if let start = selectionStart, let end = selectionEnd {
                        Rectangle()
                            .fill(AppColors.accent.opacity(0.2))
                            .frame(height: CGFloat(end - start) * 15)
                            .offset(y: CGFloat(start) * 15)
                            .border(AppColors.accent, width: 2)
                    }

                    // Events overlay
                    ForEach(filteredTimedEvents) { event in
                        EventView(event: event)
                            .offset(y: CGFloat(event.startSlotIndex) * 15)
                    }
                }
            }
            .scrollDisabled(true)
        }
    }

    private func handleDragChanged(_ value: DragGesture.Value, slotIndex: Int) {
        if !isDragging {
            isDragging = true
            selectionStart = slotIndex
            selectionEnd = slotIndex + 1
        } else {
            if let start = selectionStart {
                let currentSlot = slotIndex
                if currentSlot >= start {
                    selectionEnd = min(currentSlot + 1, 96)
                } else {
                    selectionStart = currentSlot
                    selectionEnd = start + 1
                }
            }
        }
    }

    private func handleDragEnded() {
        if let start = selectionStart, let end = selectionEnd {
            timeSelection = TimeSelection(startSlotIndex: start, endSlotIndex: end)
        }
        isDragging = false
        selectionStart = nil
        selectionEnd = nil
    }
}
