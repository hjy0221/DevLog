import SwiftUI

struct ActivityCalendarGrid: View {
    let days: [CalendarDayActivity]
    let selectedDate: Date
    let onSelect: (CalendarDayActivity) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DSSpacing.xs), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            LazyVGrid(columns: columns, spacing: DSSpacing.xs) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(DSTypography.caption)
                        .foregroundStyle(DSColor.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: DSSpacing.xs) {
                ForEach(days) { day in
                    Button {
                        onSelect(day)
                    } label: {
                        CalendarDayCell(day: day, isSelected: Calendar.current.isDate(day.date, inSameDayAs: selectedDate))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct CalendarDayCell: View {
    let day: CalendarDayActivity
    let isSelected: Bool

    var body: some View {
        Text(day.date.formatted(.dateTime.day()))
            .font(.caption.weight(isSelected ? .bold : .medium))
            .foregroundStyle(isSelected ? Color.white : DSColor.textPrimary)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.sm, style: .continuous)
                    .stroke(isSelected ? DSColor.accent : Color.clear, lineWidth: 1)
            )
    }

    private var backgroundColor: Color {
        if isSelected {
            return DSColor.accent
        }

        switch day.intensity {
        case 0: return DSColor.elevatedSurface
        case 1: return DSColor.successSoft
        case 2: return DSColor.success.opacity(0.28)
        case 3: return DSColor.success.opacity(0.46)
        case 4: return DSColor.success.opacity(0.64)
        default: return DSColor.success.opacity(0.82)
        }
    }
}
