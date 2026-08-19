import Foundation

struct ProblemGenerator: Sendable {
    static let questionsPerRound = 9

    func round(for operation: MathOperation, difficulty: Int) -> [MathProblem] {
        let level = max(1, min(difficulty, 3))
        var problems: [MathProblem] = []
        var seen = Set<String>()

        while problems.count < Self.questionsPerRound {
            let problem = makeProblem(for: operation, difficulty: level)
            let key = "\(problem.operandA)-\(problem.operandB)-\(problem.operation.rawValue)"
            if seen.insert(key).inserted {
                problems.append(problem)
            }
        }
        return problems
    }

    func makeProblem(for operation: MathOperation, difficulty: Int) -> MathProblem {
        switch operation {
        case .addition:
            return makeAddition(difficulty: difficulty)
        case .subtraction:
            return makeSubtraction(difficulty: difficulty)
        case .multiplication:
            return makeMultiplication(difficulty: difficulty)
        case .division:
            return makeDivision(difficulty: difficulty)
        }
    }

    private func makeAddition(difficulty: Int) -> MathProblem {
        let maxSum: Int
        switch difficulty {
        case 1: maxSum = 10
        case 2: maxSum = 20
        default: maxSum = 50
        }
        let answer = Int.random(in: 2...maxSum)
        let operandA = Int.random(in: 1...max(1, answer - 1))
        let operandB = answer - operandA
        return MathProblem(operation: .addition, operandA: operandA, operandB: operandB, answer: answer)
    }

    private func makeSubtraction(difficulty: Int) -> MathProblem {
        let maxValue: Int
        switch difficulty {
        case 1: maxValue = 10
        case 2: maxValue = 20
        default: maxValue = 50
        }
        let operandA = Int.random(in: 2...maxValue)
        let operandB = Int.random(in: 1...operandA - 1)
        let answer = operandA - operandB
        return MathProblem(operation: .subtraction, operandA: operandA, operandB: operandB, answer: answer)
    }

    private func makeMultiplication(difficulty: Int) -> MathProblem {
        let maxFactor: Int
        switch difficulty {
        case 1: maxFactor = 5
        case 2: maxFactor = 10
        default: maxFactor = 12
        }
        let operandA = Int.random(in: 1...maxFactor)
        let operandB = Int.random(in: 1...maxFactor)
        let answer = operandA * operandB
        return MathProblem(operation: .multiplication, operandA: operandA, operandB: operandB, answer: answer)
    }

    private func makeDivision(difficulty: Int) -> MathProblem {
        let maxFactor: Int
        switch difficulty {
        case 1: maxFactor = 5
        case 2: maxFactor = 10
        default: maxFactor = 12
        }
        let divisor = Int.random(in: 2...maxFactor)
        let quotient = Int.random(in: 1...maxFactor)
        let dividend = divisor * quotient
        return MathProblem(
            operation: .division,
            operandA: dividend,
            operandB: divisor,
            answer: quotient
        )
    }
}
