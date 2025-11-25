//
//  ContentView.swift
//  OpenCalendar
//
//  Created by Guilhem Cozier on 24/11/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                TopNavBar()
                DateRow()
                WholeDayRow()
                DayCanvas()
            }

            AddEventButton()
                .padding(.trailing, 20)
                .padding(.bottom, 20)
        }
        .background(Color.white)
    }
}

// MARK: - Top Nav Bar
struct TopNavBar: View {
    var body: some View {
        HStack {
            // Left side
            HStack(spacing: 12) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18))
                    .foregroundColor(.black)

                Text("November")
                    .font(.system(size: 15))
                    .foregroundColor(.black)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.black)
            }

            Spacer()

            // Right side
            HStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(.black)

                Text("19")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .frame(width: 32, height: 32)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

// MARK: - Date Row
struct DateRow: View {
    var body: some View {
        HStack {
            // UTC Button
            HStack(spacing: 4) {
                Text("UTC+1")
                    .font(.system(size: 11))
                    .foregroundColor(.black)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)

            Spacer()

            // Date Container
            VStack(spacing: 2) {
                Text("Wed")
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                Text("19")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
    }
}

// MARK: - Whole Day Row
struct WholeDayRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left: "All day" label
            Text("All day")
                .font(.system(size: 11))
                .foregroundColor(.black)
                .frame(width: 60, alignment: .trailing)
                .padding(.trailing, 8)

            // Right: Space for all-day events
            Rectangle()
                .fill(Color.clear)
                .frame(height: 40)
                .overlay(alignment: .bottom) {
                    Divider()
                }
        }
        .padding(.horizontal, 16)
        .background(Color.white)
    }
}

// MARK: - Day Canvas
struct DayCanvas: View {
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

                // Right column: Time slots
                VStack(spacing: 0) {
                    ForEach(0..<96, id: \.self) { slotIndex in
                        TimeSlotRow(slotIndex: slotIndex)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct HourLabel: View {
    let hour: Int

    private var timeString: String {
        String(format: "%02d:00", hour)
    }

    var body: some View {
        Text(timeString)
            .font(.system(size: 11))
            .foregroundColor(.black)
            .frame(height: 60, alignment: .top)
            .padding(.trailing, 8)
            .offset(y: -6)
    }
}

struct TimeSlotRow: View {
    let slotIndex: Int

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
                        .background(Color.gray.opacity(0.2))
                }
            }
    }
}

// MARK: - Add Event Button
struct AddEventButton: View {
    var body: some View {
        Button(action: {
            // Action to add event
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.gray.opacity(0.8))
                .clipShape(Circle())
        }
    }
}

#Preview {
    ContentView()
}
