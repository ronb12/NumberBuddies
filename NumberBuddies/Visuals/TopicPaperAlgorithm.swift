import Foundation

enum TopicPaperAlgorithm {
    static func needsPaperWork(for problem: TopicProblem) -> Bool {
        guard let helper = problem.helper else { return false }
        return needsPaperWork(for: helper)
    }

    static func work(for problem: TopicProblem, revealAnswer: Bool) -> PaperAlgorithmWork? {
        guard let helper = problem.helper else { return nil }
        return work(for: helper, revealAnswer: revealAnswer)
    }

    private static func needsPaperWork(for helper: TopicHelper) -> Bool {
        guard let mathProblem = mathProblem(for: helper) else { return false }
        return PaperAlgorithm.needsPaperWork(for: mathProblem)
    }

    private static func work(for helper: TopicHelper, revealAnswer: Bool) -> PaperAlgorithmWork? {
        guard let mathProblem = mathProblem(for: helper) else { return nil }
        return PaperAlgorithm.work(for: mathProblem, revealAnswer: revealAnswer)
    }

    private static func mathProblem(for helper: TopicHelper) -> MathProblem? {
        switch helper {
        case .addition(let a, let b):
            return MathProblem(operation: .addition, operandA: a, operandB: b, answer: a + b)
        case .subtraction(let total, let remove):
            return MathProblem(operation: .subtraction, operandA: total, operandB: remove, answer: total - remove)
        case .multiplicationThenSubtract:
            // Keep the multi-step picture helper (groups, then take away).
            // Paper work only shows product − remove and hides the story math.
            return nil
        case .difference(let larger, let smaller):
            return MathProblem(
                operation: .subtraction,
                operandA: larger,
                operandB: smaller,
                answer: larger - smaller
            )
        case .percentOf, .decimalTenthsSum:
            return nil
        }
    }
}
