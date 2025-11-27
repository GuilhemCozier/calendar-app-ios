//
//  TopNavBar.swift
//  OpenCalendar
//
//  Created by Guilhem Cozier on 24/11/2025.
//

import SwiftUI

// MARK: - Top Nav Bar

struct TopNavBar: View {
    let viewedDate: Date
    let showQuickNavigation: Bool
    let onTodayTapped: () -> Void
    let onMonthTapped: () -> Void
    let onMenuTapped: () -> Void

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: viewedDate)
    }

    private var todayDayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack(spacing: 0) {
            // Hamburger menu button
            Button(action: onMenuTapped) {
                Image(systemName: "line.3.horizontal")
                    .font(AppTypography.body(weight: .regular))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(AppColors.surfaceElevated)
                    .cornerRadius(10)
                    .shadow(color: AppColors.textPrimary.opacity(0.04), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()
                .frame(width: 12)

            // Left side - Month selector
            Button(action: onMonthTapped) {
                HStack(spacing: 10) {


                    Text(monthName)
                        .font(AppTypography.headline(weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    Image(systemName: "chevron.right")
                        .font(AppTypography.caption(weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                        .rotationEffect(.degrees(showQuickNavigation ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.surfaceElevated)
                .cornerRadius(10)
                .shadow(color: AppColors.textPrimary.opacity(0.04), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            // Right side - Actions
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(AppTypography.body(weight: .regular))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 38, height: 38)
                        .background(AppColors.surfaceElevated)
                        .cornerRadius(10)
                        .shadow(color: AppColors.textPrimary.opacity(0.04), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: onTodayTapped) {
                    Text(todayDayNumber)
                        .font(AppTypography.callout(weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(AppColors.accentSubtle)
                        .cornerRadius(10)
                        .shadow(color: AppColors.accent.opacity(0.08), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            AppColors.surface
                .shadow(color: AppColors.textPrimary.opacity(0.03), radius: 1, x: 0, y: 1)
        )
    }
}

// MARK: - Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppAnimations.springQuick, value: configuration.isPressed)
            // Alternative: .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed) // Bouncy
    }
}
