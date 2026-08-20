import SwiftUI

struct PaperWorkView: View {
    let work: PaperAlgorithmWork
    var accent: Color = AppTheme.teal
    var compact: Bool = false
    var revealAnswer: Bool = false

    private var digitSize: CGFloat { compact ? 24 : 30 }
    private var markSize: CGFloat { compact ? 12 : 14 }
    private var lineSpacing: CGFloat { compact ? 4 : 6 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(revealAnswer ? "Paper work (with answer)" : "Paper work example")
                .font(.caption.weight(.bold))
                .foregroundStyle(accent)

            HStack {
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: lineSpacing) {
                    carryRow(columnCount: work.columnCount)
                    numberRow(work.operandTop)
                    operatorRow(work.operatorSymbol, number: work.operandBottom)
                    divider(width: dividerWidth)
                    answerRow
                }
                Spacer(minLength: 0)
            }

            if !work.explanations.isEmpty {
                teacherNotes
            }
        }
        .padding(compact ? 12 : 16)
        .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.25), lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var teacherNotes: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            Text("Why we carry or borrow")
                .font(.caption.weight(.bold))
                .foregroundStyle(accent)

            ForEach(Array(work.explanations.enumerated()), id: \.offset) { index, explanation in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(explanationTint(for: explanation.kind))
                        .frame(width: 16, alignment: .trailing)
                    Text(explanation.text)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.ink.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(compact ? 10 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func explanationTint(for kind: PaperWorkExplanation.Kind) -> Color {
        switch kind {
        case .carry: AppTheme.coral
        case .borrow: AppTheme.teal
        case .column: accent
        }
    }

    @ViewBuilder
    private func carryRow(columnCount: Int) -> some View {
        HStack(spacing: digitSpacing) {
            operatorGutter
            ForEach((0..<columnCount).reversed(), id: \.self) { columnFromRight in
                let carry = work.marks.first {
                    $0.columnFromRight == columnFromRight && $0.kind == .carry
                }
                let borrow = work.marks.first {
                    $0.columnFromRight == columnFromRight && $0.kind == .borrow
                }
                VStack(spacing: 0) {
                    Text(carry?.text ?? " ")
                        .font(.system(size: markSize, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.coral)
                    Text(borrow?.text ?? " ")
                        .font(.system(size: markSize - 1, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.teal)
                }
                .frame(width: digitCellWidth)
            }
        }
        .frame(minHeight: markSize + 6)
    }

    private func numberRow(_ text: String) -> some View {
        HStack(spacing: digitSpacing) {
            operatorGutter
            ForEach(Array(padded(text).enumerated()), id: \.offset) { _, char in
                digitCell(String(char))
            }
        }
    }

    private func operatorRow(_ symbol: String, number: String) -> some View {
        HStack(spacing: digitSpacing) {
            Text(symbol)
                .font(.system(size: digitSize, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
                .frame(width: operatorGutterWidth, alignment: .trailing)
            ForEach(Array(padded(number).enumerated()), id: \.offset) { _, char in
                digitCell(String(char))
            }
        }
    }

    @ViewBuilder
    private var answerRow: some View {
        if let result = work.resultLine {
            HStack(spacing: digitSpacing) {
                operatorGutter
                ForEach(Array(padded(result).enumerated()), id: \.offset) { _, char in
                    digitCell(String(char), emphasized: true)
                }
                if let suffix = work.remainderSuffix {
                    Text(suffix)
                        .font(.system(size: markSize, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                        .padding(.leading, 4)
                }
            }
        } else {
            HStack(spacing: digitSpacing) {
                operatorGutter
                ForEach(0..<work.columnCount, id: \.self) { _ in
                    Text("?")
                        .font(.system(size: digitSize, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink.opacity(0.35))
                        .frame(width: digitCellWidth)
                }
            }
        }
    }

    private func digitCell(_ text: String, emphasized: Bool = false) -> some View {
        Text(text)
            .font(.system(size: digitSize, weight: .bold, design: .monospaced))
            .foregroundStyle(emphasized ? accent : AppTheme.ink)
            .frame(width: digitCellWidth)
    }

    private func divider(width: CGFloat) -> some View {
        Rectangle()
            .fill(AppTheme.ink.opacity(0.35))
            .frame(width: width, height: 2)
    }

    private var operatorGutter: some View {
        Color.clear.frame(width: operatorGutterWidth, height: 1)
    }

    private var digitSpacing: CGFloat { compact ? 2 : 4 }
    private var digitCellWidth: CGFloat { compact ? 22 : 28 }
    private var operatorGutterWidth: CGFloat { compact ? 22 : 28 }

    private var dividerWidth: CGFloat {
        operatorGutterWidth + digitSpacing + CGFloat(work.columnCount) * (digitCellWidth + digitSpacing)
    }

    private func padded(_ text: String) -> String {
        let width = work.columnCount
        let padding = max(0, width - text.count)
        return String(repeating: " ", count: padding) + text
    }

    private var accessibilityDescription: String {
        var parts: [String] = []
        if revealAnswer, let result = work.resultLine {
            parts.append("Paper work showing \(work.operandTop) \(work.operatorSymbol) \(work.operandBottom) equals \(result)")
        } else {
            parts.append("Paper work example for \(work.operandTop) \(work.operatorSymbol) \(work.operandBottom)")
        }
        if !work.explanations.isEmpty {
            parts.append(work.explanations.map(\.text).joined(separator: " "))
        }
        return parts.joined(separator: ". ")
    }
}

#Preview {
    if let work = PaperAlgorithm.work(
        for: MathProblem(operation: .addition, operandA: 47, operandB: 38, answer: 85),
        revealAnswer: true
    ) {
        PaperWorkView(work: work, accent: AppTheme.coral, revealAnswer: true)
            .padding()
    }
}
