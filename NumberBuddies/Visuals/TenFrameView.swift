import SwiftUI

struct TenFrameView: View {
    let count: Int
    let highlightCount: Int?
    let crossedOutCount: Int?
    var accent: Color = AppTheme.coral

    init(
        total: Int,
        highlight: Int? = nil,
        crossedOut: Int? = nil,
        accent: Color = AppTheme.coral
    ) {
        self.count = total
        self.highlightCount = highlight
        self.crossedOutCount = crossedOut
        self.accent = accent
    }

    var body: some View {
        let frames = max(1, Int(ceil(Double(count) / 10.0)))
        VStack(spacing: 8) {
            ForEach(0..<frames, id: \.self) { frameIndex in
                HStack(spacing: 8) {
                    ForEach(0..<10, id: \.self) { slot in
                        let index = frameIndex * 10 + slot
                        counter(at: index)
                    }
                }
            }
        }
        .accessibilityLabel(accessibilityDescription)
    }

    @ViewBuilder
    private func counter(at index: Int) -> some View {
        ZStack {
            Circle()
                .fill(fillColor(for: index))
                .frame(width: 22, height: 22)
                .overlay {
                    Circle()
                        .stroke(strokeColor(for: index), lineWidth: 1.5)
                }

            if isCrossedOut(index) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
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
        if let highlightCount, highlightCount > 0, index >= count - highlightCount {
            return accent.opacity(0.45)
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
