import SwiftUI

struct ProblemVisualView: View {
    let problem: MathProblem

    var body: some View {
        Group {
            switch problem.operation {
            case .addition:
                VStack(spacing: 10) {
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            TenFrameView(total: problem.operandA, accent: AppTheme.color(for: .addition))
                            Text("\(problem.operandA)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.ink.opacity(0.6))
                        }

                        Text("+")
                            .font(.title.weight(.bold))
                            .foregroundStyle(AppTheme.ink.opacity(0.5))

                        VStack(spacing: 4) {
                            TenFrameView(
                                total: problem.operandB,
                                highlight: problem.operandB,
                                accent: AppTheme.color(for: .addition)
                            )
                            Text("\(problem.operandB)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.ink.opacity(0.6))
                        }
                    }

                    Text("= \(problem.answer) altogether")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink.opacity(0.7))

                    TenFrameView(total: problem.answer, accent: AppTheme.color(for: .addition).opacity(0.85))
                }

            case .subtraction:
                VStack(spacing: 10) {
                    TenFrameView(
                        total: problem.operandA,
                        crossedOut: problem.operandB,
                        accent: AppTheme.color(for: .subtraction)
                    )

                    Text("take away \(problem.operandB)")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink.opacity(0.6))

                    Text("= \(problem.answer) left")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.color(for: .subtraction))
                }

            case .multiplication:
                VStack(spacing: 8) {
                    Text("\(problem.operandA) groups of \(problem.operandB)")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink.opacity(0.7))

                    ArrayGridView(
                        rows: problem.operandA,
                        columns: problem.operandB,
                        accent: AppTheme.color(for: .multiplication)
                    )

                    Text("= \(problem.answer) in all")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                }

            case .division:
                VStack(spacing: 8) {
                    Text("Share \(problem.operandA) into \(problem.operandB) equal groups")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink.opacity(0.7))
                        .multilineTextAlignment(.center)

                    SharingGroupsView(
                        groups: problem.operandB,
                        perGroup: problem.answer,
                        accent: AppTheme.color(for: .division)
                    )

                    Text("= \(problem.answer) in each group")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                }
            }
        }
        .padding()
        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
    }
}
