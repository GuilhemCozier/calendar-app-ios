# Calendar App - iOS

## Project Overview
A native iOS calendar app built in Swift/SwiftUI focused on UX and UI design taste. This is a personal project to showcase product design and development skills.

## Project Structure
```
calendar-app-ios/                    # Git root (open Claude Code here)
├── .git/
├── OpenCalendar/
│   ├── OpenCalendar.xcodeproj/
│   └── OpenCalendar/
│       ├── CLAUDE.md               # This file
│       ├── ContentView.swift       # Main app file
│       └── [other Swift files]
├── LICENSE
└── README.md
```
**Important**: Always open Claude Code sessions at the git root (`/calendar-app-ios/`) for full project visibility and proper git operations.

## Tech Stack
- Swift/SwiftUI
- SwiftData for local persistence
- SF Symbols for icons
- iOS 17+ target

## Design Principles
- Clean, minimal interface prioritizing visual hierarchy
- Smooth 60fps animations and transitions
- Native iOS patterns and conventions
- Focus on daily/weekly views optimized for mobile

## Current Features
- ✅ Day view with 96 15-minute time slots (00:00-00:00)
- ✅ Day-to-day navigation with smooth carousel swipe
- ✅ Quick date selector with month grid
- ✅ Event creation by tapping time slots
- ✅ Month navigation with smooth carousel animations
- ✅ Date picker calendar module

## Development Approach
- Build iteratively, one feature at a time
- Test frequently in Xcode simulator
- Prioritize feel and polish over feature scope
- Maintain smooth 60fps animations throughout

## Established Patterns

### Smooth Carousel Animation Pattern
For swipeable month/day carousels (see QuickDateSelector, DayContentView, DatePickerCalendarModule):

```swift
// 1. Setup: Pre-render prev/current/next views in ZStack with offsets
ZStack {
    PrevView().offset(x: -screenWidth + dragOffset).opacity(dragOffset > 0 ? 1 : 0)
    CurrentView().offset(x: dragOffset)
    NextView().offset(x: screenWidth + dragOffset).opacity(dragOffset < 0 ? 1 : 0)
}

// 2. On drag: Update offset directly
.simultaneousGesture(
    DragGesture(minimumDistance: 10)
        .onChanged { value in
            dragOffset = value.translation.width
        }
        .onEnded { value in
            handleSwipe(value, screenWidth: width)
        }
)

// 3. On swipe end: Animate to completion, then update state
func handleSwipe(_ gesture: DragGesture.Value, screenWidth: CGFloat) {
    if shouldNavigateNext {
        // Animate offset to full width
        withAnimation(AppAnimations.spring) {
            dragOffset = -screenWidth
        }

        // Wait for animation, then update state instantly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                currentMonth = nextMonth
                dragOffset = 0
            }
        }
    }
}
```

**Key principles:**
- Use opacity based on `dragOffset` only (not `isDragging`) so views stay visible during release animation
- Animate offset to full width first, THEN update state after 0.4s delay
- Wrap state update in `Transaction` with `disablesAnimations = true` to prevent internal animations
- Apply to both swipe gestures AND button navigation for consistency

### Gesture Handling Pattern
For making carousels both tappable and draggable:

```swift
.contentShape(Rectangle())  // Make entire area interactive
.simultaneousGesture(        // Allow both taps and drags
    DragGesture(minimumDistance: 10)  // Distinguish taps from drags
        .onChanged { /* handle drag */ }
        .onEnded { /* handle swipe */ }
)
```

## Naming Conventions
- `viewedDate`: The date currently being viewed in the app (can be any date)
- `today`: The actual current date (`Date()`)
- Use descriptive names to avoid confusion in date selection logic

## Notes for Claude Code
- Explain SwiftUI patterns when introducing new concepts
- Favor modern Swift idioms and SwiftUI best practices
- Keep views small and composable
- Maintain established animation patterns for consistency
