import SwiftUI

struct TenFrameView: View {
    let count: Int
    let crossedOutCount: Int?
    var accent: Color = AppTheme.coral
    var compact: Bool = false
    var showEmptySlots: Bool = true

    init(
        total: Int,
        crossedOut: Int? = nil,
        accent: Color = AppTheme.coral,
        compact: Bool = false,
        showEmptySlots: Bool = true
    ) {
        self.count = total
        self.crossedOutCount = crossedOut
        self.accent = accent
        self.compact = compact
        self.showEmptySlots = showEmptySlots
    }

    private var dotSize: CGFloat { compact ? 14 : 22 }
    private var rowSpacing: CGFloat { compact ? 4 : 8 }
    private var slotSpacing: CGFloat { compact ? 4 : 8 }
    private var dotsPerRow: Int { showEmptySlots ? 10 : (compact ? 5 : 10) }

    var body: some View {
        if showEmptySlots {
            tenFrameLayout
        } else {
            counterOnlyLayout
        }
    }

    private var tenFrameLayout: some View {
        let frames = max(1, Int(ceil(Double(max(count, 1)) / 10.0)))
        return VStack(spacing: rowSpacing) {
            ForEach(0..<frames, id: \.self) { frameIndex in
                HStack(spacing: slotSpacing) {
                    ForEach(0..<10, id: \.self) { slot in
                        let index = frameIndex * 10 + slot
                        counter(at: index)
                    }
                }
            }
        }
        .accessibilityLabel(accessibilityDescription)
    }

    private var counterOnlyLayout: some View {
        let rows = max(1, Int(ceil(Double(max(count, 1)) / Double(dotsPerRow))))
        return VStack(spacing: rowSpacing) {
            ForEach(0..<rows, id: \.self) { rowIndex in
                HStack(spacing: slotSpacing) {
                    ForEach(dotsInRow(rowIndex), id: \.self) { index in
                        counter(at: index)
                    }
                }
            }
        }
        .accessibilityLabel(accessibilityDescription)
    }

    private func dotsInRow(_ rowIndex: Int) -> [Int] {
        let start = rowIndex * dotsPerRow
        let end = min(start + dotsPerRow, count)
        guard start < end else { return [] }
        return Array(start..<end)
    }

    @ViewBuilder
    private func counter(at index: Int) -> some View {
        ZStack {
            if index < count {
                AnimatedCounterDot(
                    color: isCrossedOut(index) ? accent.opacity(0.15) : accent,
                    size: dotSize,
                    index: index
                )
            } else {
                Circle()
                    .stroke(strokeColor(for: index), lineWidth: compact ? 1 : 1.5)
                    .frame(width: dotSize, height: dotSize)
            }

            if isCrossedOut(index) {
                Image(systemName: "xmark")
                    .font(.system(size: compact ? 7 : 10, weight: .bold))
                    .foregroundStyle(AppTheme.ink.opacity(0.45))
            }
        }
    }

    private func isCrossedOut(_ index: Int) -> Bool {
        guard index < count, let crossedOutCount, crossedOutCount > 0 else { return false }
        return index >= count - crossedOutCount
    }

    private func fillColor(for index: Int) -> Color {
        guard index < count else { return .clear }
        if isCrossedOut(index) {
            return accent.opacity(0.15)
        }
        return accent
    }

    private func strokeColor(for index: Int) -> Color {
        if index < count {
            return accent.opacity(isCrossedOut(index) ? 0.5 : 0.35)
        }
        return accent.opacity(0.35)
    }

    private var accessibilityDescription: String {
        if let crossedOutCount, crossedOutCount > 0 {
            let remaining = max(count - crossedOutCount, 0)
            return "Visual model showing \(count) counters, taking away \(crossedOutCount), leaving \(remaining)"
        }
        return "Visual model showing \(count) counters"
    }
}
