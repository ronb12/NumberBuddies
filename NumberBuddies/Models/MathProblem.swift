import Foundation

struct MathProblem: Identifiable, Equatable, Sendable {
    let id: UUID
    let operation: MathOperation
    let operandA: Int
    let operandB: Int
    let answer: Int
    let prompt: String
    let spokenText: String

    init(
        operation: MathOperation,
        operandA: Int,
        operandB: Int,
        answer: Int,
        prompt: String? = nil,
        spokenText: String? = nil
    ) {
        self.id = UUID()
        self.operation = operation
        self.operandA = operandA
        self.operandB = operandB
        self.answer = answer
        self.prompt = prompt ?? "\(operandA) \(operation.symbol) \(operandB) = ?"
        self.spokenText = spokenText ?? Self.defaultSpoken(
            operation: operation,
            operandA: operandA,
            operandB: operandB
        )
    }

    private static func defaultSpoken(operation: MathOperation, operandA: Int, operandB: Int) -> String {
        let opWord: String
        switch operation {
        case .addition: opWord = "plus"
        case .subtraction: opWord = "minus"
        case .multiplication: opWord = "times"
        case .division: opWord = "divided by"
        }
        return "\(operandA) \(opWord) \(operandB) equals what?"
    }
}
