import Foundation

enum OrderedTableChallenge: Hashable, Identifiable {
    case table(Int)
    case marathon

    var id: String {
        switch self {
        case .table(let value): "table-\(value)"
        case .marathon: "marathon"
        }
    }

    static let tableRange = 1...12

    static var allTables: [OrderedTableChallenge] {
        tableRange.map { .table($0) }
    }
}

enum MathChallengeKind: Hashable, Identifiable {
    case orderedTable(MathOperation, Int)
    case marathon(MathOperation)
    case doubles
    case makeTen

    var id: String {
        switch self {
        case .orderedTable(let operation, let table):
            "\(operation.rawValue)-table-\(table)"
        case .marathon(let operation):
            "\(operation.rawValue)-marathon"
        case .doubles:
            "addition-doubles"
        case .makeTen:
            "addition-make-ten"
        }
    }

    var operation: MathOperation {
        switch self {
        case .orderedTable(let operation, _), .marathon(let operation):
            operation
        case .doubles, .makeTen:
            .addition
        }
    }

    var title: String {
        switch self {
        case .orderedTable(let operation, let table):
            "\(table)s \(operation.challengeTableLabel)"
        case .marathon(let operation):
            "\(operation.challengeMarathonLabel)"
        case .doubles:
            "Doubles"
        case .makeTen:
            "Make 10"
        }
    }

    var subtitle: String {
        switch self {
        case .orderedTable(let operation, let table):
            operation.challengeTableSubtitle(table: table)
        case .marathon(let operation):
            operation.challengeMarathonSubtitle
        case .doubles:
            "1 + 1 through 12 + 12 in order"
        case .makeTen:
            "Pairs that sum to 10 in order"
        }
    }

    var iconName: String {
        switch self {
        case .orderedTable, .marathon:
            operation.iconName
        case .doubles:
            "plus.square.fill"
        case .makeTen:
            "10.circle.fill"
        }
    }

    var questionCount: Int {
        MathChallengeGenerator.problems(for: self).count
    }
}

private extension MathOperation {
    var challengeTableLabel: String {
        switch self {
        case .addition: "Addends"
        case .subtraction: "Subtract"
        case .multiplication: "Table"
        case .division: "Divide"
        }
    }

    var challengeMarathonLabel: String {
        switch self {
        case .addition: "Addition 1–12 Marathon"
        case .subtraction: "Subtraction 1–12 Marathon"
        case .multiplication: "Tables 1–12 Marathon"
        case .division: "Division 1–12 Marathon"
        }
    }

    var challengeMarathonSubtitle: String {
        switch self {
        case .addition:
            "All facts from 1 + 1 through 12 + 12 in order"
        case .subtraction:
            "All facts from 12 − 1 through 23 − 12 in order"
        case .multiplication:
            "All facts from 1 × 1 through 12 × 12 in order"
        case .division:
            "All facts from 1 ÷ 1 through 144 ÷ 12 in order"
        }
    }

    func challengeTableSubtitle(table: Int) -> String {
        switch self {
        case .addition:
            return "\(table) + 1 through \(table) + 12 in order"
        case .subtraction:
            let minuend = table + 11
            return "\(minuend) − 1 through \(minuend) − 12 in order"
        case .multiplication:
            return "\(table) × 1 through \(table) × 12 in order"
        case .division:
            return "\(table) ÷ \(table) through \(table * 12) ÷ \(table) in order"
        }
    }
}

enum MathChallengeGenerator {
    static func problems(for kind: MathChallengeKind) -> [MathProblem] {
        switch kind {
        case .orderedTable(let operation, let table):
            return orderedTableProblems(for: operation, table: table)
        case .marathon(let operation):
            return OrderedTableChallenge.tableRange.flatMap {
                orderedTableProblems(for: operation, table: $0)
            }
        case .doubles:
            return (1...12).map { value in
                makeAddition(value, value)
            }
        case .makeTen:
            return (1...9).map { value in
                makeAddition(value, 10 - value)
            }
        }
    }

    static func challengeLabel(for problem: MathProblem, index: Int, kind: MathChallengeKind) -> String {
        switch kind {
        case .orderedTable:
            return "Fact \(index + 1) of 12"
        case .marathon(let operation):
            let table = tableNumber(for: problem, operation: operation)
            let factIndex = factIndexInTable(for: problem, operation: operation)
            return "Set \(table) of 12 · fact \(factIndex) of 12"
        case .doubles, .makeTen:
            return "Fact \(index + 1) of \(kind.questionCount)"
        }
    }

    static func challenges(for operation: MathOperation) -> [MathChallengeKind] {
        var items = OrderedTableChallenge.tableRange.map { MathChallengeKind.orderedTable(operation, $0) }
        items.append(.marathon(operation))
        if operation == .addition {
            items.insert(.makeTen, at: 0)
            items.insert(.doubles, at: 0)
        }
        return items
    }

    static func orderedTableProblems(for operation: MathOperation, table: Int) -> [MathProblem] {
        let table = clampTable(table)
        switch operation {
        case .addition:
            return (1...12).map { addend in makeAddition(table, addend) }
        case .subtraction:
            let minuend = table + 11
            return (1...12).map { subtrahend in makeSubtraction(minuend, subtrahend) }
        case .multiplication:
            return (1...12).map { multiplier in makeMultiplication(table, multiplier) }
        case .division:
            return (1...12).map { quotient in makeDivision(table * quotient, table) }
        }
    }

    private static func clampTable(_ table: Int) -> Int {
        max(1, min(12, table))
    }

    private static func tableNumber(for problem: MathProblem, operation: MathOperation) -> Int {
        switch operation {
        case .addition, .multiplication:
            return clampTable(problem.operandA)
        case .subtraction:
            return clampTable(problem.operandA - 11)
        case .division:
            return clampTable(problem.operandB)
        }
    }

    private static func factIndexInTable(for problem: MathProblem, operation: MathOperation) -> Int {
        switch operation {
        case .addition, .multiplication, .subtraction:
            return problem.operandB
        case .division:
            return problem.answer
        }
    }

    private static func makeAddition(_ a: Int, _ b: Int) -> MathProblem {
        MathProblem(
            operation: .addition,
            operandA: a,
            operandB: b,
            answer: a + b,
            prompt: "\(a) + \(b) = ?",
            spokenText: "What is \(SpokenNumbers.word(for: a)) plus \(SpokenNumbers.word(for: b))?"
        )
    }

    private static func makeSubtraction(_ minuend: Int, _ subtrahend: Int) -> MathProblem {
        MathProblem(
            operation: .subtraction,
            operandA: minuend,
            operandB: subtrahend,
            answer: minuend - subtrahend,
            prompt: "\(minuend) − \(subtrahend) = ?",
            spokenText: "What is \(SpokenNumbers.word(for: minuend)) minus \(SpokenNumbers.word(for: subtrahend))?"
        )
    }

    private static func makeMultiplication(_ a: Int, _ b: Int) -> MathProblem {
        MathProblem(
            operation: .multiplication,
            operandA: a,
            operandB: b,
            answer: a * b,
            prompt: "\(a) × \(b) = ?",
            spokenText: "What is \(SpokenNumbers.word(for: a)) times \(SpokenNumbers.word(for: b))?"
        )
    }

    private static func makeDivision(_ dividend: Int, _ divisor: Int) -> MathProblem {
        MathProblem(
            operation: .division,
            operandA: dividend,
            operandB: divisor,
            answer: dividend / divisor,
            prompt: "\(dividend) ÷ \(divisor) = ?",
            spokenText: "What is \(SpokenNumbers.word(for: dividend)) divided by \(SpokenNumbers.word(for: divisor))?"
        )
    }
}

typealias TimesTableChallengeKind = OrderedTableChallenge
enum TimesTableGenerator {
    static func problems(for kind: OrderedTableChallenge) -> [MathProblem] {
        let mapped: MathChallengeKind = switch kind {
        case .table(let table): .orderedTable(.multiplication, table)
        case .marathon: .marathon(.multiplication)
        }
        return MathChallengeGenerator.problems(for: mapped)
    }

    static func challengeLabel(for problem: MathProblem, index: Int, kind: OrderedTableChallenge) -> String {
        let mapped: MathChallengeKind = switch kind {
        case .table(let table): .orderedTable(.multiplication, table)
        case .marathon: .marathon(.multiplication)
        }
        return MathChallengeGenerator.challengeLabel(for: problem, index: index, kind: mapped)
    }
}
