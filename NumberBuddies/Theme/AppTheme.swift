import SwiftUI

enum AppTheme {
    static let cream = Color(red: 1.0, green: 0.98, blue: 0.94)
    static let coral = Color(red: 1.0, green: 0.45, blue: 0.42)
    static let teal = Color(red: 0.18, green: 0.72, blue: 0.68)
    static let sunny = Color(red: 1.0, green: 0.82, blue: 0.35)
    static let purple = Color(red: 0.55, green: 0.42, blue: 0.92)
    static let ink = Color(red: 0.18, green: 0.16, blue: 0.22)

    static func color(for operation: MathOperation) -> Color {
        switch operation {
        case .addition: coral
        case .subtraction: teal
        case .multiplication: sunny
        case .division: purple
        }
    }

    static let cardCornerRadius: CGFloat = 24
    static let minTapSize: CGFloat = 56
}

struct PlayfulBackground: View {
    var body: some View {
        AppTheme.cream
            .ignoresSafeArea()
            .overlay {
                Circle()
                    .fill(AppTheme.coral.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .offset(x: -120, y: -220)
                Circle()
                    .fill(AppTheme.teal.opacity(0.08))
                    .frame(width: 220, height: 220)
                    .offset(x: 140, y: 260)
            }
    }
}

struct StarBurst: View {
    let count: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Image(systemName: "star.fill")
                    .foregroundStyle(AppTheme.sunny)
                    .font(.title2)
                    .scaleEffect(reduceMotion ? 1 : 1.2)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.55).delay(Double(index) * 0.05),
                        value: count
                    )
            }
        }
        .accessibilityLabel("\(count) stars earned")
    }
}
