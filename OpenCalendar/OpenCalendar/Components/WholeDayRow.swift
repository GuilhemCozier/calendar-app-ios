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
                Text("All\nday")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color.grey50)
                    .multilineTextAlignment(.trailing)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.grey50)
            }
            
            .padding(.horizontal, 5.5)
            .padding(.vertical, 5)
            .frame(maxWidth: 45, maxHeight: .infinity, alignment: .trailing)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color.borderSoft8)
                    .frame(width: 0.5)
                    .padding(.top, 0)
                    .padding(.bottom, 0)
                    .padding(.trailing, 0)
        
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.borderSoft8)
                    .frame(height: 0.5)
                    .padding(.bottom, 0)
                    .padding(.leading, 0)
                    .padding(.trailing, 0)
        
            }
            // Right: All-day events
            VStack(spacing: 2) {
                ForEach(events) { event in
                    AllDayEventView(event: event)
                }

                
            }
            .frame(maxWidth: .infinity, minHeight: 32, alignment: .top)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.borderSoft8)
                    .frame(height: 0.5)
                    .padding(.bottom, 0)
                    .padding(.leading, 0)
                    .padding(.trailing, 0)
        
            }
        }
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
