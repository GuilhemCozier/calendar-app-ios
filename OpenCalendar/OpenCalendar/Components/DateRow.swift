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
        VStack(spacing: 4) {
            Text(dayOfWeekShort)
                .font(AppTypography.caption(weight: .medium))
                .foregroundColor(AppColors.textSecondary)

            Text(dayNumber)
                .font(AppTypography.title(weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.surface)
    }
}
