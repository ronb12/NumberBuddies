import SwiftUI

enum TextAnswerPadStyle {
    case fraction
    case decimal
    case percent
    case expandedForm
    case time
    case words

    static func forTopic(_ topic: MathTopic) -> TextAnswerPadStyle {
        switch topic {
        case .fractions: .fraction
        case .decimals: .decimal
        case .percentages: .percent
        case .placeValue: .expandedForm
        case .time: .time
        case .graphsAndData, .probability: .words
        default: .decimal
        }
    }
}

private enum TextPadKey: Hashable {
    case character(String)
    case clear
    case submit
    case backspace

    var label: String {
        switch self {
        case .character(let value): value
        case .clear: "C"
        case .submit: "Go"
        case .backspace: "⌫"
        }
    }

    var isSubmit: Bool {
        if case .submit = self { return true }
        return false
    }

    var isClear: Bool {
        if case .clear = self { return true }
        return false
    }

    var isBackspace: Bool {
        if case .backspace = self { return true }
        return false
    }
}

struct TextAnswerPadView: View {
    @Binding var input: String
    let style: TextAnswerPadStyle
    let onSubmit: () -> Void
    let onClear: () -> Void
    var accent: Color = AppTheme.teal
    var isDisabled: Bool = false
    var compact: Bool = false
    var maxLength: Int = 16

    private var keyHeight: CGFloat { compact ? 44 : AppTheme.minTapSize }
    private var rowSpacing: CGFloat { compact ? 6 : 8 }
    private var displayHeight: CGFloat { compact ? 48 : 56 }

    private var rows: [[TextPadKey]] {
        switch style {
        case .fraction:
            return [
                [.character("1"), .character("2"), .character("3")],
                [.character("4"), .character("5"), .character("6")],
                [.character("7"), .character("8"), .character("9")],
                [.clear, .character("0"), .character("/")],
                [.backspace, .submit]
            ]
        case .decimal:
            return [
                [.character("1"), .character("2"), .character("3")],
                [.character("4"), .character("5"), .character("6")],
                [.character("7"), .character("8"), .character("9")],
                [.clear, .character("0"), .character(".")],
                [.backspace, .submit]
            ]
        case .percent:
            return [
                [.character("1"), .character("2"), .character("3")],
                [.character("4"), .character("5"), .character("6")],
                [.character("7"), .character("8"), .character("9")],
                [.clear, .character("0"), .character("%")],
                [.backspace, .submit]
            ]
        case .expandedForm:
            return [
                [.character("1"), .character("2"), .character("3")],
                [.character("4"), .character("5"), .character("6")],
                [.character("7"), .character("8"), .character("9")],
                [.clear, .character("0"), .character("+")],
                [.character(" "), .backspace, .submit]
            ]
        case .time:
            return [
                [.character("1"), .character("2"), .character("3")],
                [.character("4"), .character("5"), .character("6")],
                [.character("7"), .character("8"), .character("9")],
                [.clear, .character("0"), .character(":")],
                [.backspace, .submit]
            ]
        case .words:
            return [
                [.character("R"), .character("e"), .character("d")],
                [.character("B"), .character("l"), .character("u")],
                [.character("G"), .character("r"), .character("e")],
                [.character("Y"), .character("e"), .character("l")],
                [.character("w"), .character("o"), .character(" ")],
                [.clear, .backspace, .submit]
            ]
        }
    }

    var body: some View {
        VStack(spacing: rowSpacing) {
            answerDisplay

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: rowSpacing) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            guard !isDisabled else { return }
                            FeedbackService.lightTap()
                            handleTap(key)
                        } label: {
                            keyLabel(for: key)
                                .frame(maxWidth: .infinity)
                                .frame(height: keyHeight)
                                .background(buttonColor(for: key), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isDisabled)
                    }
                }
            }
        }
    }

    private var answerDisplay: some View {
        Group {
            if input.isEmpty {
                Text("Type your answer")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.ink.opacity(0.35))
            } else {
                Text(input)
                    .font(.system(size: compact ? 28 : 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: displayHeight)
        .padding(.horizontal, 8)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Your answer: \(input.isEmpty ? "empty" : input)")
    }

    @ViewBuilder
    private func keyLabel(for key: TextPadKey) -> some View {
        if key.isSubmit {
            Image(systemName: "checkmark")
                .font(compact ? .headline.weight(.bold) : .title3.weight(.bold))
                .foregroundStyle(.white)
        } else {
            Text(key.label)
                .font(compact ? .subheadline.weight(.bold) : .headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
        }
    }

    private func handleTap(_ key: TextPadKey) {
        switch key {
        case .clear:
            onClear()
        case .backspace:
            guard !input.isEmpty else { return }
            input.removeLast()
        case .submit:
            guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            onSubmit()
        case .character(let value):
            guard input.count < maxLength else { return }
            input += value
        }
    }

    private func buttonColor(for key: TextPadKey) -> Color {
        switch key {
        case .submit: accent
        case .clear, .backspace: Color.white.opacity(0.9)
        case .character: Color.white.opacity(0.95)
        }
    }
}
