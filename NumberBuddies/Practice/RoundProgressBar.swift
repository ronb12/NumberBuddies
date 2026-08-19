import SwiftUI

struct RoundProgressBar: View {
    let current: Int
    let total: Int
    var accent: Color = AppTheme.teal

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(accent.opacity(0.15))
                    Capsule()
                        .fill(accent)
                        .frame(width: max(geo.size.width * progress, current > 0 ? 12 : 0))
                        .animation(.easeOut(duration: 0.25), value: current)
                }
            }
            .frame(height: 10)

            Text("Question \(current) of \(total)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink.opacity(0.6))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Question \(current) of \(total)")
    }
}
