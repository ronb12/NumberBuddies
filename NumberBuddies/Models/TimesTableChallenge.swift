import Foundation

enum TimesTableChallengeKind: Hashable, Identifiable {
    case table(Int)
    case marathon

    var id: String {
        switch self {
        case .table(let value): "table-\(value)"
        case .marathon: "marathon"
        }
    }

    static let tableRange = 1...12

    static var allTables: [TimesTableChallengeKind] {
        tableRange.map { .table($0) }
    }

    var tableNumber: Int? {
        if case .table(let value) = self { return value }
        return nil
    }

    var title: String {
        switch self {
        case .table(let value): "\(value)s Table"
        case .marathon: "Tables 1–12 Marathon"
        }
    }

    var subtitle: String {
        switch self {
        case .table(let value):
            "\(value) × 1 through \(value) × 12 in order"
        case .marathon:
            "All facts from 1 × 1 through 12 × 12 in order"
        }
    }

    var questionCount: Int {
        switch self {
        case .table: 12
        case .marathon: 144
        }
    }

    var iconName: String {
        switch self {
        case .table: "number"
        case .marathon: "flag.checkered"
        }
    }
}

enum TimesTableGenerator {
    static func problems(for kind: TimesTableChallengeKind) -> [MathProblem] {
        switch kind {
        case .table(let raw):
            let table = clampTable(raw)
            return orderedFacts(for: table)
        case .marathon:
            return TimesTableChallengeKind.tableRange.flatMap { orderedFacts(for: $0) }
        }
    }

    static func orderedFacts(for table: Int) -> [MathProblem] {
        let table = clampTable(table)
        return (1...12).map { multiplier in
            MathProblem(
                operation: .multiplication,
                operandA: table,
                operandB: multiplier,
                answer: table * multiplier,
                prompt: "\(table) × \(multiplier) = ?",
                spokenText: "What is \(SpokenNumbers.word(for: table)) times \(SpokenNumbers.word(for: multiplier))?"
            )
        }
    }

    static func clampTable(_ table: Int) -> Int {
        max(1, min(12, table))
    }

    static func challengeLabel(for problem: MathProblem, index: Int, kind: TimesTableChallengeKind) -> String {
        switch kind {
        case .table:
            return "Fact \(index + 1) of 12"
        case .marathon:
            let table = clampTable(problem.operandA)
            let factIndex = problem.operandB
            return "Table \(table) of 12 · fact \(factIndex) of 12"
        }
    }
}
