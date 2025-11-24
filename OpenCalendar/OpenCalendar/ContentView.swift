//
//  ContentView.swift
//  OpenCalendar
//
//  Created by Guilhem Cozier on 24/11/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DayView()
    }
}

struct DayView: View {
    // Generate 24 hours (0-23)
    private let hours = Array(0..<24)

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 0) {
                // Left column: Hour labels
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(hours, id: \.self) { hour in
                        HourLabel(hour: hour)
                    }
                }
                .frame(width: 60)

                // Right side: Time slots grid
                VStack(spacing: 0) {
                    ForEach(0..<96, id: \.self) { slotIndex in
                        TimeSlotRow(slotIndex: slotIndex)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .background(Color(.white))
    }
}

struct HourLabel: View {
    let hour: Int

    private var timeString: String {
        String(format: "%02d:00", hour)
    }

    var body: some View {
        Text(timeString)
            .font(.system(size: 11, weight: .regular))
            .foregroundColor(.secondary)
            .frame(height: 60, alignment: .top)
            .padding(.trailing, 8)
            .offset(y: -6) // Align with hour line
    }
}

struct TimeSlotRow: View {
    let slotIndex: Int

    // Each slot represents 15 minutes
    // Show border only on hour boundaries (every 4th slot: 0, 4, 8, 12...)
    private var showBorder: Bool {
        slotIndex % 4 == 0
    }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 15)
            .overlay(alignment: .bottom) {
                if showBorder {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                }
            }
    }
}

#Preview {
    ContentView()
}
