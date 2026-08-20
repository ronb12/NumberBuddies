import SwiftUI

struct TopicHelperView: View {
    let problem: TopicProblem
    var accent: Color
    var compact: Bool = false
    var revealAnswer: Bool = false

    var body: some View {
        VStack(spacing: compact ? 10 : 14) {
            if let stepHint = topicStepHint {
                HelperStepLabel(text: stepHint, color: accent)
            }

            if let visual = problem.visual {
                TopicVisualView(visual: visual, compact: compact, revealAnswer: revealAnswer)
            }

            if let helper = problem.helper {
                helperContent(for: helper)
            }

            if revealAnswer {
                answerStrip
            }
        }
        .padding(compact ? 10 : 14)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.2), lineWidth: 1.5)
        }
    }

    private var topicStepHint: String? {
        if problem.helper != nil { return nil }
        switch problem.topic {
        case .fractions:
            return "Count the shaded parts. The bottom number is all the parts."
        case .decimals:
            return "Each square is one tenth."
        case .percentages:
            return "Shaded squares show parts out of 100."
        case .time:
            return "Read the short hand for the hour and the long hand for minutes."
        case .money:
            if case .money(let pieces) = problem.visual, pieces.contains(where: { $0.kind == .bill }) {
                return "Dollar bills first: $1 = 100 cents. Then add the coins."
            }
            return "Name each coin, then add: quarter 25¢, dime 10¢, nickel 5¢."
        case .measurement:
            return "Compare the bar lengths on the ruler."
        case .geometry:
            return "Count carefully — area fills the inside, perimeter goes around."
        case .placeValue:
            return "Each column shows a place: ones, tens, or hundreds."
        case .graphsAndData:
            return "Taller bars mean more votes."
        case .probability:
            return "More red means a better chance of landing on red."
        case .wordProblems:
            return nil
        }
    }

    @ViewBuilder
    private func helperContent(for helper: TopicHelper) -> some View {
        switch helper {
        case .addition(let a, let b):
            additionHelper(a: a, b: b)
        case .subtraction(let total, let remove):
            subtractionHelper(total: total, remove: remove)
        case .multiplicationThenSubtract(let groups, let perGroup, let remove):
            multiplicationThenSubtractHelper(groups: groups, perGroup: perGroup, remove: remove)
        case .difference(let larger, let smaller):
            differenceHelper(larger: larger, smaller: smaller)
        case .percentOf(let percent, let whole):
            percentHelper(percent: percent, whole: whole)
        case .decimalTenthsSum(let a, let b):
            decimalSumHelper(a: a, b: b)
        }
    }

    @ViewBuilder
    private func additionHelper(a: Int, b: Int) -> some View {
        HStack(alignment: .top, spacing: compact ? 8 : 12) {
            HelperGroupBox(title: "Start with \(a)", tint: accent, compact: compact) {
                TenFrameView(total: a, accent: accent, compact: compact, showEmptySlots: false)
            }
            Image(systemName: "plus")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.ink.opacity(0.4))
                .padding(.top, compact ? 24 : 28)
            HelperGroupBox(title: "Add \(b) more", tint: AppTheme.teal, compact: compact) {
                TenFrameView(total: b, accent: AppTheme.teal, compact: compact, showEmptySlots: false)
            }
        }
        HelperGroupBox(
            title: revealAnswer ? "\(a + b) altogether" : "Count them all",
            tint: accent,
            compact: compact
        ) {
            MergedCounterView(
                firstCount: a,
                secondCount: b,
                firstColor: accent,
                secondColor: AppTheme.teal,
                compact: compact
            )
        }
    }

    @ViewBuilder
    private func subtractionHelper(total: Int, remove: Int) -> some View {
        RemainingCounterView(
            total: total,
            remove: remove,
            accent: accent,
            compact: compact
        )
    }

    @ViewBuilder
    private func multiplicationThenSubtractHelper(groups: Int, perGroup: Int, remove: Int) -> some View {
        let product = groups * perGroup
        VStack(spacing: compact ? 8 : 12) {
            HelperGroupBox(title: "\(groups) groups of \(perGroup)", tint: accent, compact: compact) {
                EqualGroupsView(groups: groups, perGroup: perGroup, accent: accent, compact: compact)
            }
            HelperStepLabel(text: "Take away \(remove)", color: AppTheme.coral)
            RemainingCounterView(total: product, remove: remove, accent: accent, compact: compact)
            if revealAnswer {
                Text("\(product) − \(remove) = \(product - remove)")
                    .font(.system(size: compact ? 18 : 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private func differenceHelper(larger: Int, smaller: Int) -> some View {
        VStack(spacing: compact ? 8 : 12) {
            HStack(spacing: compact ? 12 : 16) {
                HelperGroupBox(title: "\(larger)", tint: accent, compact: compact) {
                    TenFrameView(total: larger, accent: accent, compact: compact, showEmptySlots: false)
                }
                HelperGroupBox(title: "\(smaller)", tint: AppTheme.teal, compact: compact) {
                    TenFrameView(total: smaller, accent: AppTheme.teal, compact: compact, showEmptySlots: false)
                }
            }
            HelperStepLabel(text: "How many more in \(larger)?", color: accent)
            if revealAnswer {
                Text("\(larger) − \(smaller) = \(larger - smaller)")
                    .font(.system(size: compact ? 18 : 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private func percentHelper(percent: Int, whole: Int) -> some View {
        let answer = whole * percent / 100
        VStack(spacing: compact ? 8 : 12) {
            HelperGroupBox(title: "\(percent)% means \(percent) out of 100", tint: accent, compact: compact) {
                PercentGridView(percent: percent, compact: compact)
            }
            HelperStepLabel(text: "Find \(percent)% of \(whole)", color: accent)
            if revealAnswer {
                Text("\(whole) × \(percent) ÷ 100 = \(answer)")
                    .font(.system(size: compact ? 18 : 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private func decimalSumHelper(a: Int, b: Int) -> some View {
        let sumTenths = a + b
        let answerText = sumTenths >= 10 ? "1.\(sumTenths - 10)" : "0.\(sumTenths)"
        HStack(alignment: .top, spacing: compact ? 8 : 12) {
            HelperGroupBox(title: "0.\(a)", tint: accent, compact: compact) {
                DecimalTenthsGrid(tenths: a, compact: compact)
            }
            Image(systemName: "plus")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.ink.opacity(0.4))
                .padding(.top, compact ? 24 : 28)
            HelperGroupBox(title: "0.\(b)", tint: AppTheme.teal, compact: compact) {
                DecimalTenthsGrid(tenths: b, compact: compact)
            }
        }
        if revealAnswer {
            Text("0.\(a) + 0.\(b) = \(answerText)")
                .font(.system(size: compact ? 18 : 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var answerStrip: some View {
        Text("Answer: \(problem.correctDisplayAnswer)")
            .font(.system(size: compact ? 18 : 22, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("The answer is \(problem.correctDisplayAnswer)")
    }
}

private struct PercentGridView: View {
    let percent: Int
    var compact: Bool

    var body: some View {
        let filled = max(0, min(100, percent))
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 10), spacing: 3) {
            ForEach(0..<100, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(index < filled ? AppTheme.purple : AppTheme.purple.opacity(0.12))
                    .frame(height: compact ? 10 : 14)
            }
        }
        .accessibilityLabel("\(filled) out of 100 squares shaded")
    }
}

private struct DecimalTenthsGrid: View {
    let tenths: Int
    var compact: Bool

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(index < tenths ? AppTheme.teal : AppTheme.teal.opacity(0.12))
                    .frame(height: compact ? 20 : 28)
            }
        }
    }
}
