import Foundation

struct ProblemGenerator: Sendable {
    let ageGroup: AgeGroup

    init(ageGroup: AgeGroup = .early) {
        self.ageGroup = ageGroup
    }

    var questionsPerRound: Int { ageGroup.questionsPerRound }

    func round(for operation: MathOperation, difficulty: Int) -> [MathProblem] {
        let level = clampedLevel(difficulty)
        let operation = resolvedOperation(operation, level: level)
        return uniqueProblems(for: operation, difficulty: level, count: questionsPerRound)
    }

    func mixedRound(operations: [MathOperation], difficulty: Int) -> [MathProblem] {
        let level = clampedLevel(difficulty)
        let allowed = ageGroup.availableOperations(for: level)
        let requested = operations.filter { allowed.contains($0) }
        let active = requested.isEmpty ? allowed : requested
        guard !active.isEmpty else {
            return uniqueProblems(for: .addition, difficulty: level, count: questionsPerRound)
        }

        let targetCount = questionsPerRound
        let perOperation = max(1, targetCount / active.count)
        var problems: [MathProblem] = []

        for operation in active {
            problems.append(contentsOf: uniqueProblems(for: operation, difficulty: level, count: perOperation))
        }

        while problems.count < targetCount, let operation = active.randomElement() {
            if let problem = uniqueProblem(for: operation, difficulty: level, excluding: problems) {
                problems.append(problem)
            }
        }

        return problems.shuffled()
    }

    func makeProblem(for operation: MathOperation, difficulty: Int) -> MathProblem {
        let level = clampedLevel(difficulty)
        let operation = resolvedOperation(operation, level: level)
        switch operation {
        case .addition:
            return makeAddition(difficulty: level)
        case .subtraction:
            return makeSubtraction(difficulty: level)
        case .multiplication:
            return makeMultiplication(difficulty: level)
        case .division:
            return makeDivision(difficulty: level)
        }
    }

    private func clampedLevel(_ difficulty: Int) -> Int {
        max(1, min(difficulty, ageGroup.maxDifficulty))
    }

    private func resolvedOperation(_ operation: MathOperation, level: Int) -> MathOperation {
        let allowed = ageGroup.availableOperations(for: level)
        if allowed.contains(operation) {
            return operation
        }
        return allowed.first ?? .addition
    }

    private func uniqueProblems(for operation: MathOperation, difficulty: Int, count: Int) -> [MathProblem] {
        var problems: [MathProblem] = []
        var seen = Set<String>()
        var attempts = 0

        while problems.count < count, attempts < count * 30 {
            attempts += 1
            let problem = makeProblem(for: operation, difficulty: difficulty)
            let key = problemKey(problem)
            if seen.insert(key).inserted {
                problems.append(problem)
            }
        }
        return problems
    }

    private func uniqueProblem(
        for operation: MathOperation,
        difficulty: Int,
        excluding existing: [MathProblem]
    ) -> MathProblem? {
        var seen = Set(existing.map(problemKey))
        for _ in 0..<30 {
            let problem = makeProblem(for: operation, difficulty: difficulty)
            let key = problemKey(problem)
            if seen.insert(key).inserted {
                return problem
            }
        }
        return nil
    }

    private func problemKey(_ problem: MathProblem) -> String {
        let remainder = problem.remainder.map(String.init) ?? "0"
        return "\(problem.operandA)-\(problem.operandB)-\(problem.operation.rawValue)-\(remainder)"
    }

    private func randomInt(from lower: Int, through upper: Int) -> Int {
        let lowerBound = min(lower, upper)
        let upperBound = max(lower, upper)
        return Int.random(in: lowerBound...upperBound)
    }

    private func makeAddition(difficulty: Int) -> MathProblem {
        let caps = ageGroup.caps(for: difficulty)
        if ageGroup.prefersRegrouping(for: difficulty), caps.maxSum >= 20 {
            if let problem = makeRegroupingAddition(maxSum: caps.maxSum) {
                return problem
            }
        }

        let maxSum = max(2, caps.maxSum)
        let answer = randomInt(from: 2, through: maxSum)
        let operandA = randomInt(from: 1, through: max(1, answer - 1))
        let operandB = answer - operandA
        return MathProblem(operation: .addition, operandA: operandA, operandB: operandB, answer: answer)
    }

    private func makeRegroupingAddition(maxSum: Int) -> MathProblem? {
        guard maxSum >= 20 else { return nil }
        for _ in 0..<40 {
            let operandA = randomInt(from: 10, through: min(99, max(10, maxSum - 10)))
            let operandB = randomInt(from: 10, through: min(99, maxSum - operandA))
            let answer = operandA + operandB
            guard answer <= maxSum else { continue }
            guard (operandA % 10) + (operandB % 10) >= 10 else { continue }
            return MathProblem(operation: .addition, operandA: operandA, operandB: operandB, answer: answer)
        }
        return nil
    }

    private func makeSubtraction(difficulty: Int) -> MathProblem {
        let caps = ageGroup.caps(for: difficulty)
        if ageGroup.prefersRegrouping(for: difficulty), caps.maxValue >= 20 {
            if let problem = makeRegroupingSubtraction(maxValue: caps.maxValue) {
                return problem
            }
        }

        let maxValue = max(2, caps.maxValue)
        let operandA = randomInt(from: 2, through: maxValue)
        let operandB = randomInt(from: 1, through: operandA - 1)
        let answer = operandA - operandB
        return MathProblem(operation: .subtraction, operandA: operandA, operandB: operandB, answer: answer)
    }

    private func makeRegroupingSubtraction(maxValue: Int) -> MathProblem? {
        guard maxValue >= 20 else { return nil }
        for _ in 0..<40 {
            let operandA = randomInt(from: 20, through: min(999, maxValue))
            let operandB = randomInt(from: 10, through: operandA - 1)
            guard (operandA % 10) < (operandB % 10) else { continue }
            let answer = operandA - operandB
            return MathProblem(operation: .subtraction, operandA: operandA, operandB: operandB, answer: answer)
        }
        return nil
    }

    private func makeMultiplication(difficulty: Int) -> MathProblem {
        let caps = ageGroup.caps(for: difficulty)
        guard caps.maxFactor >= 2 else {
            return makeAddition(difficulty: difficulty)
        }

        if caps.twoDigitMultiplication {
            let operandA = randomInt(from: 10, through: 99)
            let operandB = randomInt(from: 2, through: 9)
            let answer = operandA * operandB
            return MathProblem(operation: .multiplication, operandA: operandA, operandB: operandB, answer: answer)
        }

        let maxFactor = caps.maxFactor
        let operandA = randomInt(from: 2, through: maxFactor)
        let operandB = randomInt(from: 2, through: maxFactor)
        let answer = operandA * operandB
        return MathProblem(operation: .multiplication, operandA: operandA, operandB: operandB, answer: answer)
    }

    private func makeDivision(difficulty: Int) -> MathProblem {
        let caps = ageGroup.caps(for: difficulty)
        guard caps.maxFactor >= 2 else {
            return makeSubtraction(difficulty: difficulty)
        }

        let maxFactor = caps.maxFactor

        if ageGroup.allowsRemainders(for: difficulty), maxFactor >= 3, Bool.random() {
            let divisor = randomInt(from: 3, through: maxFactor)
            let quotient = randomInt(from: 2, through: maxFactor)
            let remainder = randomInt(from: 1, through: divisor - 1)
            let dividend = divisor * quotient + remainder
            return MathProblem(
                operation: .division,
                operandA: dividend,
                operandB: divisor,
                answer: quotient,
                remainder: remainder
            )
        }

        let divisor = randomInt(from: 2, through: maxFactor)
        let quotient = randomInt(from: 1, through: maxFactor)
        let dividend = divisor * quotient
        return MathProblem(
            operation: .division,
            operandA: dividend,
            operandB: divisor,
            answer: quotient
        )
    }
}
