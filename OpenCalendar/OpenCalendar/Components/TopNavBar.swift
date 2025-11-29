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
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.grey50)
                    
            }
            .buttonStyle(.plain)

            Spacer()
                .frame(width: 10)

            // Left side - Month selector
            Button(action: onMonthTapped) {
                HStack(spacing: 7) {
                    Text(monthName)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color.grey50)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.grey50)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Right side - Actions
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(Color.grey50)
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: onTodayTapped) {
                    Text(todayDayNumber)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.grey50)
                        .frame(width: 23, height: 23)
                        .background(Color.frameTransparent7)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        
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
