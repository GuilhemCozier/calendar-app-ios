//
//  WholeDayRow.swift
//  OpenCalendar
//
//  Created by Claude Code on 2025-11-27.
//

import SwiftUI

// MARK: - Whole Day Row
struct WholeDayRow: View {
    let events: [CalendarEvent]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left: "All day" label
            VStack(alignment: .trailing) {
                Text("All day")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.grey50)
                    .frame(width: 20)
                    .multilineTextAlignment(.trailing)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.grey50)
            }
            .frame(width: 45)
            .padding(.horizontal, 5.5)
            .padding(.vertical, 5)
            // Right: All-day events
            VStack(spacing: 6) {
                ForEach(events) { event in
                    AllDayEventView(event: event)
                }

                if events.isEmpty {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 32)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppColors.borderSubtle)
                    .frame(height: 1)
            }
        }
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
