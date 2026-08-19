import Foundation

struct MathProblem: Identifiable, Equatable, Sendable {
    let id: UUID
    let operation: MathOperation
    let operandA: Int
    let operandB: Int
    let answer: Int
    let remainder: Int?
    let prompt: String
    let spokenText: String
    let story: MathProblemStory

    init(
        operation: MathOperation,
        operandA: Int,
        operandB: Int,
        answer: Int,
        remainder: Int? = nil,
        prompt: String? = nil,
        spokenText: String? = nil,
        story: MathProblemStory? = nil
    ) {
        self.id = UUID()
        self.operation = operation
        self.operandA = operandA
        self.operandB = operandB
        self.answer = answer
        self.remainder = remainder
        self.story = story ?? MathProblemStory.make(
            for: operation,
            operandA: operandA,
            operandB: operandB
        )
        self.prompt = prompt ?? Self.defaultPrompt(
            operation: operation,
            operandA: operandA,
            operandB: operandB,
            remainder: remainder
        )
        self.spokenText = spokenText ?? self.story.spokenQuestion(
            operandA: operandA,
            operandB: operandB,
            answer: answer
        )
    }

    var hasRemainder: Bool {
        guard let remainder else { return false }
        return remainder > 0
    }

    private static func defaultPrompt(
        operation: MathOperation,
        operandA: Int,
        operandB: Int,
        remainder: Int?
    ) -> String {
        switch operation {
        case .division where remainder != nil && remainder! > 0:
            return "\(operandA) \(operation.symbol) \(operandB) = ?"
        default:
            return "\(operandA) \(operation.symbol) \(operandB) = ?"
        }
    }

    var subtractionStory: SubtractionStory? {
        if case .subtraction(let story) = story { return story }
        return nil
    }

    var additionStory: AdditionStory? {
        if case .addition(let story) = story { return story }
        return nil
    }

    var multiplicationStory: MultiplicationStory? {
        if case .multiplication(let story) = story { return story }
        return nil
    }

    var divisionStory: DivisionStory? {
        if case .division(let story) = story { return story }
        return nil
    }
}
