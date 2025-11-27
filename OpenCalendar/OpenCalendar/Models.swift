//
//  Models.swift
//  OpenCalendar
//
//  Created by Guilhem Cozier on 24/11/2025.
//

import Foundation

// MARK: - View Mode

enum ViewMode: String, CaseIterable {
    case oneDay = "One day"
    case threeDays = "Three days"
    case week = "Week"

    var numberOfDays: Int {
        switch self {
        case .oneDay: return 1
        case .threeDays: return 3
        case .week: return 7
        }
    }
}

// MARK: - Time Selection State

struct TimeSelection: Equatable {
    var startSlotIndex: Int  // 0-95 (96 slots of 15 minutes)
    var endSlotIndex: Int    // 0-95

    var startTime: String {
        let hour = startSlotIndex / 4
        let minute = (startSlotIndex % 4) * 15
        return String(format: "%02d:%02d", hour, minute)
    }

    var endTime: String {
        let hour = endSlotIndex / 4
        let minute = (endSlotIndex % 4) * 15
        return String(format: "%02d:%02d", hour, minute)
    }

    var duration: Int {
        endSlotIndex - startSlotIndex
    }
}

// MARK: - Repetition Type

enum RepetitionType: String, CaseIterable, Hashable {
    case none = "No"
    case daily = "Every day"
    case weekly = "Every week"
    case monthly = "Every month"
    case yearly = "Every year"
}

// MARK: - Event Model

struct CalendarEvent: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var description: String
    var startSlotIndex: Int
    var endSlotIndex: Int
    var isAllDay: Bool
    var startDate: Date
    var endDate: Date
    var repetition: RepetitionType

    var startTime: String {
        let hour = startSlotIndex / 4
        let minute = (startSlotIndex % 4) * 15
        return String(format: "%02d:%02d", hour, minute)
    }

    var endTime: String {
        let hour = endSlotIndex / 4
        let minute = (endSlotIndex % 4) * 15
        return String(format: "%02d:%02d", hour, minute)
    }
}
