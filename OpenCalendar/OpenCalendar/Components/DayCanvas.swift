//
//  DayCanvas.swift
//  OpenCalendar
//
//  Created by Claude Code on 2025-11-27.
//

import SwiftUI

// MARK: - Day Canvas
struct DayCanvas: View {
    @Binding var timeSelection: TimeSelection?
    let events: [CalendarEvent]
    private let hours = Array(0..<24)

    var body: some View {
        ScrollView(showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                // Left column: Hour labels
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(hours, id: \.self) { hour in
                        HourLabel(hour: hour)
                    }
                }
                .frame(width: 65)

                // Right column: Time slots with overlay
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        ForEach(0..<96, id: \.self) { slotIndex in
                            TimeSlotRow(
                                slotIndex: slotIndex,
                                onTap: {
                                    handleSlotTap(slotIndex: slotIndex)
                                }
                            )
                        }
                    }

                    // Events overlay
                    ForEach(events) { event in
                        EventView(event: event)
                    }

                    // Time selector overlay
                    if timeSelection != nil {
                        TimeSelector(
                            selection: $timeSelection,
                            totalSlots: 96
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(AppColors.surface)
    }

    private func handleSlotTap(slotIndex: Int) {
        // Round down to the nearest hour (4 slots = 1 hour)
        let roundedStart = (slotIndex / 4) * 4
        // Default duration: 1 hour (4 slots)
        let defaultEnd = min(roundedStart + 4, 95)

        timeSelection = TimeSelection(
            startSlotIndex: roundedStart,
            endSlotIndex: defaultEnd
        )
    }
}

struct HourLabel: View {
    let hour: Int

    private var timeString: String {
        String(format: "%02d:00", hour)
    }

    var body: some View {
        Text(timeString)
            .font(AppTypography.caption(weight: .regular))
            .foregroundColor(AppColors.textTertiary)
            .frame(height: 60, alignment: .top)
            .padding(.trailing, 12)
            .offset(y: -7)
    }
}

struct TimeSlotRow: View {
    let slotIndex: Int
    var onTap: () -> Void

    private var showBorder: Bool {
        slotIndex % 4 == 0
    }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 15)
            .overlay(alignment: .bottom) {
                if showBorder {
                    Rectangle()
                        .fill(AppColors.borderSubtle)
                        .frame(height: 1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Time Selector
struct TimeSelector: View {
    @Binding var selection: TimeSelection?
    let totalSlots: Int
    private let slotHeight: CGFloat = 15

    @State private var initialStart: Int = 0
    @State private var initialEnd: Int = 0

    var body: some View {
        guard let selection = selection else { return AnyView(EmptyView()) }

        let yOffset = CGFloat(selection.startSlotIndex) * slotHeight
        let height = CGFloat(selection.duration) * slotHeight

        return AnyView(
            ZStack(alignment: .topLeading) {
                // Main rectangle
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.accentSubtle.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.accent, lineWidth: 2)
                    )
                    .frame(height: height)
                    .shadow(color: AppColors.accent.opacity(0.1), radius: 8, x: 0, y: 2)
                    .overlay(
                        // Time display
                        VStack(spacing: 4) {
                            Text(selection.startTime)
                                .font(AppTypography.callout(weight: .semibold))
                            Text("-")
                                .font(AppTypography.caption(weight: .regular))
                            Text(selection.endTime)
                                .font(AppTypography.callout(weight: .semibold))
                        }
                        .foregroundColor(AppColors.textPrimary)
                    )
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 5)
                            .onChanged { value in
                                handleBodyDrag(value)
                            }
                            .onEnded { _ in
                                if let sel = self.selection {
                                    initialStart = sel.startSlotIndex
                                    initialEnd = sel.endSlotIndex
                                }
                            }
                    )

                // Top handle
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "arrow.up.and.down")
                            .font(AppTypography.caption(weight: .bold))
                            .foregroundColor(AppColors.surfaceElevated)
                    )
                    .shadow(color: AppColors.accent.opacity(0.25), radius: 4, x: 0, y: 2)
                    .position(x: 14, y: 0)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleTopHandleDrag(value)
                            }
                            .onEnded { _ in
                                if let sel = self.selection {
                                    initialStart = sel.startSlotIndex
                                    initialEnd = sel.endSlotIndex
                                }
                            }
                    )

                // Bottom handle
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "arrow.up.and.down")
                            .font(AppTypography.caption(weight: .bold))
                            .foregroundColor(AppColors.surfaceElevated)
                    )
                    .shadow(color: AppColors.accent.opacity(0.25), radius: 4, x: 0, y: 2)
                    .position(x: 14, y: height)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleBottomHandleDrag(value)
                            }
                            .onEnded { _ in
                                if let sel = self.selection {
                                    initialStart = sel.startSlotIndex
                                    initialEnd = sel.endSlotIndex
                                }
                            }
                    )
            }
            .offset(y: yOffset)
            .onAppear {
                initialStart = selection.startSlotIndex
                initialEnd = selection.endSlotIndex
            }
            .onChange(of: selection.startSlotIndex) { _, newValue in
                initialStart = newValue
            }
            .onChange(of: selection.endSlotIndex) { _, newValue in
                initialEnd = newValue
            }
        )
    }

    private func handleTopHandleDrag(_ value: DragGesture.Value) {
        let draggedSlots = Int(round(value.translation.height / slotHeight))
        let newStart = max(0, min(initialEnd - 1, initialStart + draggedSlots))

        self.selection = TimeSelection(
            startSlotIndex: newStart,
            endSlotIndex: initialEnd
        )
    }

    private func handleBottomHandleDrag(_ value: DragGesture.Value) {
        let draggedSlots = Int(round(value.translation.height / slotHeight))
        let newEnd = max(initialStart + 1, min(95, initialEnd + draggedSlots))

        self.selection = TimeSelection(
            startSlotIndex: initialStart,
            endSlotIndex: newEnd
        )
    }

    private func handleBodyDrag(_ value: DragGesture.Value) {
        let draggedSlots = Int(round(value.translation.height / slotHeight))
        let duration = initialEnd - initialStart

        var newStart = initialStart + draggedSlots
        var newEnd = initialEnd + draggedSlots

        // Ensure boundaries
        if newStart < 0 {
            newStart = 0
            newEnd = duration
        }
        if newEnd > 95 {
            newEnd = 95
            newStart = 95 - duration
        }

        self.selection = TimeSelection(
            startSlotIndex: newStart,
            endSlotIndex: newEnd
        )
    }
}

// MARK: - Event View
struct EventView: View {
    let event: CalendarEvent
    private let slotHeight: CGFloat = 15

    var body: some View {
        let yOffset = CGFloat(event.startSlotIndex) * slotHeight
        let height = CGFloat(event.endSlotIndex - event.startSlotIndex) * slotHeight

        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(AppTypography.subheadline(weight: .semibold))
                .foregroundColor(AppColors.eventBlue)
                .lineLimit(height > 40 ? 2 : 1)

            if !event.isAllDay && height > 40 {
                Text("\(event.startTime) - \(event.endTime)")
                    .font(AppTypography.caption(weight: .regular))
                    .foregroundColor(AppColors.eventBlue.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppColors.eventBlueBg)
        .cornerRadius(10)
        .shadow(color: AppColors.eventBlue.opacity(0.08), radius: 4, x: 0, y: 2)
        .frame(height: height)
        .offset(y: yOffset)
    }
}
