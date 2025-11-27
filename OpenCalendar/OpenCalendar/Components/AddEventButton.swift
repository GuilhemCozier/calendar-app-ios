//
//  AddEventButton.swift
//  OpenCalendar
//
//  Created by Claude Code on 2025-11-27.
//

import SwiftUI

// MARK: - Add Event Button
struct AddEventButton: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.accent)
                .frame(width: 60, height: 60)
                .shadow(color: AppColors.accent.opacity(0.3), radius: 12, x: 0, y: 4)

            Image(systemName: "plus")
                .font(AppTypography.title(weight: .semibold))
                .foregroundColor(AppColors.surfaceElevated)
        }
    }
}
