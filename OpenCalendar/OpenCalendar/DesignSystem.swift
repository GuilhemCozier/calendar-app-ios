//
//  DesignSystem.swift
//  OpenCalendar
//
//  Created by Guilhem Cozier on 24/11/2025.
//

import SwiftUI

// MARK: - Design System

struct AppColors {
    // Cream backgrounds - warm but subtle
    static let background = Color(hex: "#F5F3EE")
    static let surface = Color(hex: "#FDFCFA")
    static let surfaceElevated = Color.white

    // Sage green accent
    static let accent = Color(hex: "#8B9D83")
    static let accentLight = Color(hex: "#A8B89F")
    static let accentSubtle = Color(hex: "#E8EBE6")

    // Neutrals
    static let textPrimary = Color(hex: "#1A1A1A")
    static let textSecondary = Color(hex: "#666666")
    static let textTertiary = Color(hex: "#999999")
    static let border = Color(hex: "#E6E3DD")
    static let borderSubtle = Color(hex: "#F0EDE7")

    // Semantic
    static let eventBlue = Color(hex: "#7B93B3")
    static let eventBlueBg = Color(hex: "#E8EDF3")
}

struct AppTypography {
    // SF Pro with refined weights
    static func largeTitle(weight: Font.Weight = .semibold) -> Font {
        .system(size: 28, weight: weight, design: .default)
    }

    static func title(weight: Font.Weight = .semibold) -> Font {
        .system(size: 20, weight: weight, design: .default)
    }

    static func headline(weight: Font.Weight = .medium) -> Font {
        .system(size: 17, weight: weight, design: .default)
    }

    static func body(weight: Font.Weight = .regular) -> Font {
        .system(size: 15, weight: weight, design: .default)
    }

    static func callout(weight: Font.Weight = .regular) -> Font {
        .system(size: 14, weight: weight, design: .default)
    }

    static func subheadline(weight: Font.Weight = .regular) -> Font {
        .system(size: 13, weight: weight, design: .default)
    }

    static func caption(weight: Font.Weight = .regular) -> Font {
        .system(size: 11, weight: weight, design: .default)
    }
}

struct AppAnimations {
    // Spring animations (Anthropic-style: responsive but refined)
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let springQuick = Animation.spring(response: 0.25, dampingFraction: 0.8)

    // Ease animations
    static let easeOut = Animation.easeOut(duration: 0.3)
    static let easeInOut = Animation.easeInOut(duration: 0.25)

    // Alternative options (commented for testing):
    // static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    // static let smooth = Animation.easeInOut(duration: 0.4)
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
