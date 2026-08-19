import SwiftUI

struct ProblemVisualView: View {
    let problem: MathProblem

    var body: some View {
        Group {
            switch problem.operation {
            case .addition:
                VStack(spacing: 8) {
                    TenFrameView(total: problem.operandA, accent: AppTheme.color(for: .addition))
                    Text("+")
                        .font(.title.weight(.bold))
                        .foregroundStyle(AppTheme.ink.opacity(0.5))
                    TenFrameView(
                        total: problem.operandB,
                        highlight: problem.operandB,
                        accent: AppTheme.color(for: .addition).opacity(0.65)
                    )
                }
            case .subtraction:
                VStack(spacing: 8) {
                    TenFrameView(total: problem.operandA, accent: AppTheme.color(for: .subtraction))
                    Text("take away \(problem.operandB)")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink.opacity(0.6))
                    TenFrameView(
                        total: max(problem.operandA - problem.operandB, 0),
                        accent: AppTheme.color(for: .subtraction)
                    )
                }
            case .multiplication:
                ArrayGridView(
                    rows: problem.operandA,
                    columns: problem.operandB,
                    accent: AppTheme.color(for: .multiplication)
                )
            case .division:
                SharingGroupsView(
                    groups: problem.operandB,
                    perGroup: problem.answer,
                    accent: AppTheme.color(for: .division)
                )
            }
        }
        .padding()
        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
    }
}
