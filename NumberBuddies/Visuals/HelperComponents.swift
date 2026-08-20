import SwiftUI

struct AnimatedCounterDot: View {
    let color: Color
    let size: CGFloat
    let index: Int
    var animate: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 1)
            }
            .scaleEffect(appeared ? 1 : 0.2)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                guard animate, !reduceMotion else {
                    appeared = true
                    return
                }
                withAnimation(
                    .spring(response: 0.38, dampingFraction: 0.62)
                        .delay(Double(index) * 0.045)
                ) {
                    appeared = true
                }
            }
    }
}

struct PictureHelperToggle: View {
    @Binding var isOn: Bool
    let accent: Color
    var usesPaperWork: Bool = false

    var body: some View {
        Toggle(isOn: $isOn) {
            Label {
                Text(usesPaperWork ? "Show paper work" : "Show picture helper")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
            } icon: {
                Image(systemName: usesPaperWork ? "square.and.pencil" : "photo.on.rectangle.angled")
                    .foregroundStyle(accent)
            }
        }
        .tint(accent)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.ink.opacity(0.14), lineWidth: 1)
        )
        .colorScheme(.light)
        .accessibilityLabel(usesPaperWork ? "Show paper work" : "Show picture helper")
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

struct StoryHeader: View {
    let iconName: String
    let title: String
    var tint: Color = AppTheme.ink
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .foregroundStyle(tint)
            Text(title)
                .font(compact ? .subheadline.weight(.semibold) : .headline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HelperStepLabel: View {
    let text: String
    var color: Color = AppTheme.ink

    @State private var appeared = false

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
            .scaleEffect(appeared ? 1 : 0.92)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                    appeared = true
                }
            }
    }
}

struct HelperEquationStrip: View {
    let problem: MathProblem
    var compact: Bool = false
    var revealAnswer: Bool = false

    var body: some View {
        Text(equationText)
            .font(.system(size: compact ? 18 : 22, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.color(for: problem.operation).opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel(revealAnswer ? "The answer is \(problem.answer)" : "Equation to solve")
    }

    private var equationText: String {
        if revealAnswer {
            return "\(problem.operandA) \(problem.operation.symbol) \(problem.operandB) = \(problem.answer)"
        }
        return "\(problem.operandA) \(problem.operation.symbol) \(problem.operandB) = ?"
    }
}

struct HelperGroupBox<Content: View>: View {
    let title: String
    var tint: Color = AppTheme.coral
    var compact: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: compact ? 4 : 6) {
            HelperStepLabel(text: title, color: tint)
            content
                .padding(compact ? 8 : 10)
                .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tint.opacity(0.25), lineWidth: 1.5)
                }
        }
    }
}

struct MergedCounterView: View {
    let firstCount: Int
    let secondCount: Int
    let firstColor: Color
    let secondColor: Color
    var compact: Bool = false

    private var dotSize: CGFloat { compact ? 14 : 20 }
    private var spacing: CGFloat { compact ? 4 : 6 }
    private var dotsPerRow: Int { compact ? 5 : 10 }

    var body: some View {
        let total = firstCount + secondCount
        let rows = max(1, Int(ceil(Double(max(total, 1)) / Double(dotsPerRow))))

        VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(dotsInRow(row), id: \.self) { index in
                        AnimatedCounterDot(
                            color: color(for: index),
                            size: dotSize,
                            index: index
                        )
                    }
                }
            }
        }
        .accessibilityLabel("\(firstCount) plus \(secondCount), \(total) in all")
    }

    private func dotsInRow(_ row: Int) -> [Int] {
        let start = row * dotsPerRow
        let end = min(start + dotsPerRow, firstCount + secondCount)
        guard start < end else { return [] }
        return Array(start..<end)
    }

    private func color(for index: Int) -> Color {
        index < firstCount ? firstColor : secondColor
    }
}

struct RemainingCounterView: View {
    let total: Int
    let remove: Int
    var story: SubtractionStory?
    var accent: Color = AppTheme.teal
    var compact: Bool = false

    private var remaining: Int { max(total - remove, 0) }
    private var dotSize: CGFloat { compact ? 14 : 20 }
    private var spacing: CGFloat { compact ? 4 : 6 }
    private var dotsPerRow: Int { compact ? 5 : 10 }

    var body: some View {
        VStack(spacing: compact ? 8 : 12) {
            if let story {
                StoryHeader(
                    iconName: story.iconName,
                    title: story.startLabel(count: total) + ". " + story.actionLabel(count: remove) + ". How many are left?",
                    tint: accent,
                    compact: compact
                )
            }

            beforeView

            HelperStepLabel(
                text: story?.actionLabel(count: remove) ?? "Take away \(remove)",
                color: AppTheme.coral
            )

            Image(systemName: "arrow.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.ink.opacity(0.35))

            afterView
        }
    }

    private var beforeView: some View {
        HelperGroupBox(
            title: story?.startLabel(count: total) ?? "You have \(total)",
            tint: accent,
            compact: compact
        ) {
            dotGrid(count: total)
        }
    }

    private var afterView: some View {
        HelperGroupBox(
            title: story?.leftLabel(count: remaining) ?? "\(remaining) left",
            tint: accent.opacity(0.85),
            compact: compact
        ) {
            keptDots(count: remaining)
        }
    }

    @ViewBuilder
    private func keptDots(count: Int) -> some View {
        let rows = max(1, Int(ceil(Double(max(count, 1)) / Double(dotsPerRow))))
        VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(dotsInRow(row, count: count), id: \.self) { _ in
                        Circle()
                            .fill(accent)
                            .frame(width: dotSize, height: dotSize)
                            .overlay {
                                Circle().stroke(accent.opacity(0.4), lineWidth: 1)
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dotGrid(count: Int) -> some View {
        let rows = max(1, Int(ceil(Double(max(count, 1)) / Double(dotsPerRow))))
        VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(dotsInRow(row, count: count), id: \.self) { index in
                        dot(at: index)
                    }
                }
            }
        }
    }

    private func dotsInRow(_ row: Int, count: Int) -> [Int] {
        let start = row * dotsPerRow
        let end = min(start + dotsPerRow, count)
        guard start < end else { return [] }
        return Array(start..<end)
    }

    @ViewBuilder
    private func dot(at index: Int) -> some View {
        let showCrossOut = story == nil && index >= total - remove

        ZStack {
            AnimatedCounterDot(
                color: showCrossOut ? AppTheme.coral.opacity(0.15) : accent,
                size: dotSize,
                index: index
            )

            if showCrossOut {
                Image(systemName: "xmark")
                    .font(.system(size: compact ? 7 : 9, weight: .black))
                    .foregroundStyle(AppTheme.coral.opacity(0.8))
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
