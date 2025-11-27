//
//  DayContentView.swift
//  OpenCalendar
//
//  Created by Guilhem Cozier on 24/11/2025.
//

import SwiftUI

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
            DateRow(viewedDate: date)
            WholeDayRow(events: filteredAllDayEvents)
            DayCanvas(
                timeSelection: $timeSelection,
                events: filteredTimedEvents
            )
        }
    }
}
