import SwiftUI

private enum PadKey: Hashable {
    case digit(String)
    case clear
    case submit

    var label: String {
        switch self {
        case .digit(let value): value
        case .clear: "C"
        case .submit: "Go"
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
}

struct NumberPadView: View {
    @Binding var input: String
    let onSubmit: () -> Void
    let onClear: () -> Void
    var accent: Color = AppTheme.teal

    private let rows: [[PadKey]] = [
        [.digit("1"), .digit("2"), .digit("3")],
        [.digit("4"), .digit("5"), .digit("6")],
        [.digit("7"), .digit("8"), .digit("9")],
        [.clear, .digit("0"), .submit]
    ]

    var body: some View {
        VStack(spacing: 10) {
            Group {
                if input.isEmpty {
                    Image(systemName: "circle.dashed")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundStyle(AppTheme.ink.opacity(0.25))
                } else {
                    Text(input)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityLabel("Your answer: \(input.isEmpty ? "empty" : input)")

            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            handleTap(key)
                        } label: {
                            keyLabel(for: key)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppTheme.minTapSize)
                                .background(buttonColor(for: key), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .accessibilityLabel(accessibilityLabel(for: key))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keyLabel(for key: PadKey) -> some View {
        if key.isSubmit {
            Image(systemName: "checkmark")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
        } else {
            Text(key.label)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.ink)
        }
    }

    private func handleTap(_ key: PadKey) {
        switch key {
        case .clear:
            onClear()
        case .submit:
            onSubmit()
        case .digit(let value):
            guard input.count < 4 else { return }
            input += value
        }
    }

    private func buttonColor(for key: PadKey) -> Color {
        switch key {
        case .submit: accent
        case .clear: Color.white.opacity(0.9)
        case .digit: Color.white.opacity(0.95)
        }
    }

    private func accessibilityLabel(for key: PadKey) -> String {
        switch key {
        case .clear: "Clear"
        case .submit: "Submit answer"
        case .digit(let value): "Number \(value)"
        }
    }
}
