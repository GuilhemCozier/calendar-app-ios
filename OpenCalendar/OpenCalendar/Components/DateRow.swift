//
//  DateRow.swift
//  OpenCalendar
//
//  Created by Claude Code on 2025-11-27.
//

import SwiftUI

struct DateRow: View {
    let viewedDate: Date

    private var dayOfWeekShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Short day name (e.g., "Thu")
        return formatter.string(from: viewedDate)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: viewedDate)
    }

    var body: some View {
        // Compact date display - day abbreviation and number
        HStack(alignment: .bottom){
            
            VStack(spacing: 1) {
                Text(dayOfWeekShort)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color.darkGrey60)
                
                Text(dayNumber)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.pitchBlack100)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            
                        
                
        }
        .overlay(alignment: .bottomTrailing) {
            Rectangle()
                .fill(Color.borderSoft8)
                .frame(width: 1, height: 15)
        }
        .overlay(alignment: .bottomLeading) {
            Rectangle()
                .fill(Color.borderSoft8)
                .frame(width: 1, height: 15)
        }
        
    }
}
