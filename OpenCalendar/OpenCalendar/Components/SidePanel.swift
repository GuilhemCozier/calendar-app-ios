//
//  SidePanel.swift
//  OpenCalendar
//
//  Created by Guilhem Cozier on 24/11/2025.
//

import SwiftUI

// MARK: - Side Panel

struct SidePanel: View {
    @Binding var isVisible: Bool
    @Binding var selectedViewMode: ViewMode

    var body: some View {
        VStack(spacing: 0) {
            // User Profile Section
            VStack(spacing: 0) {
                UserProfileRow()
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
            }

            Divider()
                .background(AppColors.border)

            // Views Section
            VStack(spacing: 0) {
                Text("VIEWS")
                    .font(AppTypography.caption(weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ViewOptionRow(
                    icon: "square",
                    title: "One day",
                    viewMode: .oneDay,
                    selectedViewMode: $selectedViewMode
                )
                ViewOptionRow(
                    icon: "rectangle.grid.1x2",
                    title: "Three days",
                    viewMode: .threeDays,
                    selectedViewMode: $selectedViewMode
                )
                ViewOptionRow(
                    icon: "rectangle.grid.2x2",
                    title: "Week",
                    viewMode: .week,
                    selectedViewMode: $selectedViewMode
                )
            }

            Spacer()
        }
        .frame(width: 280)
        .frame(maxHeight: .infinity)
        .background(AppColors.surface)
        .contentShape(Rectangle())
        .allowsHitTesting(true)
        .onTapGesture {
            // Consume any taps that don't hit specific buttons
        }
        .shadow(color: AppColors.textPrimary.opacity(0.08), radius: 12, x: 2, y: 0)
    }
}

// MARK: - User Profile Row

struct UserProfileRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture placeholder
            Circle()
                .fill(AppColors.accentSubtle)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("H")
                        .font(AppTypography.headline(weight: .semibold))
                        .foregroundColor(AppColors.accent)
                )

            // Name
            Text("Name")
                .font(AppTypography.body(weight: .medium))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            // Settings icon
            Image(systemName: "gearshape")
                .font(AppTypography.body(weight: .regular))
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - View Option Row

struct ViewOptionRow: View {
    let icon: String
    let title: String
    let viewMode: ViewMode
    @Binding var selectedViewMode: ViewMode
    @State private var isHovered: Bool = false

    private var isSelected: Bool {
        selectedViewMode == viewMode
    }

    var body: some View {
        Button(action: {
            print("ViewOptionRow tapped: \(viewMode.rawValue)")
            selectedViewMode = viewMode
            print("Selected view mode changed to: \(selectedViewMode.rawValue)")
        }) {
            HStack(spacing: 12) {
                // Icon - Using SF Symbols as placeholders for Lucide icons
                // TODO: Replace with Lucide icons: square, Columns3, Columns4
                Image(systemName: icon)
                    .font(AppTypography.body(weight: .regular))
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.textSecondary)
                    .frame(width: 20)

                // Title
                Text(title)
                    .font(AppTypography.body(weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isHovered ? AppColors.accentSubtle : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AppAnimations.springQuick) {
                isHovered = hovering
            }
        }
    }
}
