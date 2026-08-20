import SwiftUI

struct ProblemVisualView: View {
    let problem: MathProblem
    var compact: Bool = false
    var revealAnswer: Bool = false

    var body: some View {
        VStack(spacing: compact ? 10 : 14) {
            switch problem.operation {
            case .addition:
                additionVisual
            case .subtraction:
                subtractionVisual
            case .multiplication:
                multiplicationVisual
            case .division:
                divisionVisual
            }

            HelperEquationStrip(problem: problem, compact: compact, revealAnswer: revealAnswer)
        }
        .padding(compact ? 10 : 16)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.color(for: problem.operation).opacity(0.2), lineWidth: 1.5)
        }
    }

    @ViewBuilder
    private var additionVisual: some View {
        let firstColor = AppTheme.color(for: .addition)
        let secondColor = AppTheme.teal
        let story = problem.additionStory

        VStack(spacing: compact ? 8 : 12) {
            if let story {
                StoryHeader(
                    iconName: story.item.iconName,
                    title: story.storyTitle(start: problem.operandA, add: problem.operandB),
                    tint: firstColor,
                    compact: compact
                )
            }

            HStack(alignment: .top, spacing: compact ? 8 : 12) {
                HelperGroupBox(
                    title: story?.startLabel(count: problem.operandA) ?? "Start with \(problem.operandA)",
                    tint: firstColor,
                    compact: compact
                ) {
                    TenFrameView(
                        total: problem.operandA,
                        accent: firstColor,
                        compact: compact,
                        showEmptySlots: false
                    )
                }

                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink.opacity(0.4))
                    .padding(.top, compact ? 24 : 28)

                HelperGroupBox(
                    title: story?.addLabel(count: problem.operandB) ?? "Add \(problem.operandB) more",
                    tint: secondColor,
                    compact: compact
                ) {
                    TenFrameView(
                        total: problem.operandB,
                        accent: secondColor,
                        compact: compact,
                        showEmptySlots: false
                    )
                }
            }

            Image(systemName: "arrow.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.ink.opacity(0.35))

            HelperGroupBox(
                title: revealAnswer
                    ? (story?.totalLabel(count: problem.answer) ?? "\(problem.answer) altogether")
                    : "Count them all",
                tint: firstColor,
                compact: compact
            ) {
                MergedCounterView(
                    firstCount: problem.operandA,
                    secondCount: problem.operandB,
                    firstColor: firstColor,
                    secondColor: secondColor,
                    compact: compact
                )
            }
        }
    }

    @ViewBuilder
    private var subtractionVisual: some View {
        RemainingCounterView(
            total: problem.operandA,
            remove: problem.operandB,
            story: problem.subtractionStory,
            accent: AppTheme.color(for: .subtraction),
            compact: compact
        )
    }

    @ViewBuilder
    private var multiplicationVisual: some View {
        let story = problem.multiplicationStory

        VStack(spacing: compact ? 8 : 12) {
            if let story {
                StoryHeader(
                    iconName: story.item.iconName,
                    title: story.storyTitle(groups: problem.operandA, perGroup: problem.operandB),
                    tint: AppTheme.color(for: .multiplication),
                    compact: compact
                )
            }

            EqualGroupsView(
                groups: problem.operandA,
                perGroup: problem.operandB,
                story: story,
                accent: AppTheme.color(for: .multiplication),
                compact: compact
            )
        }
    }

    @ViewBuilder
    private var divisionVisual: some View {
        let story = problem.divisionStory

        VStack(spacing: compact ? 8 : 12) {
            if let story {
                StoryHeader(
                    iconName: story.item.iconName,
                    title: story.storyTitle(total: problem.operandA, friends: problem.operandB),
                    tint: AppTheme.color(for: .division),
                    compact: compact
                )
            }

            SharingGroupsView(
                groups: problem.operandB,
                perGroup: problem.answer,
                remainder: problem.remainder ?? 0,
                story: story,
                accent: AppTheme.color(for: .division),
                compact: compact
            )
        }
    }
}
