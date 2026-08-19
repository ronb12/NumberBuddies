import SwiftUI

struct CorrectBurstView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundStyle(AppTheme.sunny)
            Text("Great job!")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.teal)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.sunny.opacity(0.2), in: Capsule())
        .scaleEffect(reduceMotion ? 1 : 1.08)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.55), value: true)
        .accessibilityLabel("Great job, correct answer")
    }
}
