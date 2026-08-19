import SwiftUI

struct TenFrameView: View {
    let count: Int
    let highlightCount: Int?
    var accent: Color = AppTheme.coral

    init(total: Int, highlight: Int? = nil, accent: Color = AppTheme.coral) {
        self.count = total
        self.highlightCount = highlight
        self.accent = accent
    }

    var body: some View {
        let frames = max(1, Int(ceil(Double(count) / 10.0)))
        VStack(spacing: 8) {
            ForEach(0..<frames, id: \.self) { frameIndex in
                HStack(spacing: 8) {
                    ForEach(0..<10, id: \.self) { slot in
                        let index = frameIndex * 10 + slot
                        Circle()
                            .fill(fillColor(for: index))
                            .frame(width: 22, height: 22)
                            .overlay {
                                Circle()
                                    .stroke(accent.opacity(0.35), lineWidth: 1.5)
                            }
                    }
                }
            }
        }
        .accessibilityLabel("Visual model showing \(count) counters")
    }

    private func fillColor(for index: Int) -> Color {
        guard index < count else { return .clear }
        if let highlightCount, index >= count - highlightCount {
            return accent.opacity(0.35)
        }
        return accent
    }
}
