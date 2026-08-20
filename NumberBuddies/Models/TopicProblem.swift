import Foundation
import SwiftUI

enum MathTopic: String, CaseIterable, Codable, Identifiable, Sendable {
    case fractions
    case decimals
    case percentages
    case time
    case money
    case measurement
    case geometry
    case placeValue
    case graphsAndData
    case probability
    case wordProblems

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fractions: "Fractions"
        case .decimals: "Decimals"
        case .percentages: "Percentages"
        case .time: "Time"
        case .money: "Money"
        case .measurement: "Measurement"
        case .geometry: "Geometry"
        case .placeValue: "Place Value"
        case .graphsAndData: "Graphs & Data"
        case .probability: "Probability"
        case .wordProblems: "Word Problems"
        }
    }

    var subtitle: String {
        switch self {
        case .fractions: "Parts of a whole"
        case .decimals: "Tenths and hundredths"
        case .percentages: "Parts out of 100"
        case .time: "Clocks & calendars"
        case .money: "Coins & dollars"
        case .measurement: "Length, weight & more"
        case .geometry: "Shapes, area & perimeter"
        case .placeValue: "Expanded form & rounding"
        case .graphsAndData: "Charts & tallies"
        case .probability: "Likely or unlikely?"
        case .wordProblems: "Read, think, solve"
        }
    }

    var iconName: String {
        switch self {
        case .fractions: "circle.lefthalf.filled"
        case .decimals: "textformat.123"
        case .percentages: "percent"
        case .time: "clock.fill"
        case .money: "dollarsign.circle.fill"
        case .measurement: "ruler.fill"
        case .geometry: "square.on.square"
        case .placeValue: "textformat.abc"
        case .graphsAndData: "chart.bar.fill"
        case .probability: "die.face.5.fill"
        case .wordProblems: "text.book.closed.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .fractions: AppTheme.coral
        case .decimals: AppTheme.teal
        case .percentages: AppTheme.purple
        case .time: AppTheme.teal
        case .money: AppTheme.sunny
        case .measurement: AppTheme.teal
        case .geometry: AppTheme.purple
        case .placeValue: AppTheme.coral
        case .graphsAndData: AppTheme.sunny
        case .probability: AppTheme.purple
        case .wordProblems: AppTheme.coral
        }
    }

    static func available(for ageGroup: AgeGroup) -> [MathTopic] {
        switch ageGroup {
        case .preK:
            return [.geometry, .time, .money, .graphsAndData]
        case .early:
            return [
                .geometry, .time, .money, .measurement, .placeValue,
                .fractions, .graphsAndData, .probability, .wordProblems
            ]
        case .upper:
            return MathTopic.allCases
        }
    }

    var questionsPerRound: Int {
        switch self {
        case .wordProblems: 6
        default: 8
        }
    }
}

enum TopicAnswerKind: Equatable, Sendable {
    case integer(Int)
    case text(String)
    case choiceIndex(Int)
}

enum TopicVisual: Equatable, Sendable {
    case fraction(numerator: Int, denominator: Int)
    case decimalGrid(tenths: Int)
    case percentGrid(percent: Int)
    case clock(hour: Int, minute: Int)
    case money(pieces: [MoneyPiece])
    case ruler(lengthA: Int, lengthB: Int, unit: String)
    case shape(kind: GeometryShape, width: Int, height: Int)
    case barGraph(items: [BarGraphItem])
    case placeValue(number: Int)
    case spinner(redSections: Int, totalSections: Int)
}

/// One bill or coin shown in money helpers. Values are always in cents.
struct MoneyPiece: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case bill
        case coin
    }

    let kind: Kind
    let valueCents: Int

    static func bill(_ dollars: Int) -> MoneyPiece {
        MoneyPiece(kind: .bill, valueCents: dollars * 100)
    }

    static func coin(_ cents: Int) -> MoneyPiece {
        MoneyPiece(kind: .coin, valueCents: cents)
    }

    var totalCents: Int { valueCents }

    var name: String {
        switch kind {
        case .bill:
            switch valueCents {
            case 100: "Dollar bill"
            case 500: "Five-dollar bill"
            case 1000: "Ten-dollar bill"
            default: "$\(valueCents / 100) bill"
            }
        case .coin:
            switch valueCents {
            case 25: "Quarter"
            case 10: "Dime"
            case 5: "Nickel"
            default: "Penny"
            }
        }
    }

    var centsLabel: String {
        "\(valueCents)¢"
    }

    var helperLine: String {
        if kind == .bill {
            return "\(name) = \(valueCents) cents"
        }
        return "\(name) = \(centsLabel)"
    }
}

struct BarGraphItem: Equatable, Sendable {
    let label: String
    let value: Int
}

enum GeometryShape: String, Sendable {
    case triangle
    case square
    case rectangle
    case circle
    case hexagon
}

struct TopicProblem: Identifiable, Equatable, Sendable {
    let id: UUID
    let topic: MathTopic
    let prompt: String
    let spokenText: String
    let story: String?
    let answer: TopicAnswerKind
    let choices: [String]?
    let acceptedAnswers: [String]?
    let helper: TopicHelper?
    let visual: TopicVisual?

    init(
        topic: MathTopic,
        prompt: String,
        spokenText: String? = nil,
        story: String? = nil,
        answer: TopicAnswerKind,
        choices: [String]? = nil,
        acceptedAnswers: [String]? = nil,
        helper: TopicHelper? = nil,
        visual: TopicVisual? = nil
    ) {
        self.id = UUID()
        self.topic = topic
        self.prompt = prompt
        self.story = story
        self.answer = answer
        self.choices = choices
        self.acceptedAnswers = acceptedAnswers
        self.helper = helper
        self.visual = visual
        self.spokenText = spokenText ?? [story, prompt].compactMap { $0 }.joined(separator: " ")
    }

    var expectsNumericInput: Bool {
        if case .integer = answer { return true }
        return false
    }

    var expectsTextInput: Bool {
        if case .text = answer { return true }
        return false
    }

    var hasChoiceShortcuts: Bool {
        !(choices?.isEmpty ?? true)
    }

    var expectsChoiceOnlyInput: Bool {
        if case .choiceIndex = answer {
            return hasChoiceShortcuts
        }
        return false
    }

    var hasHelper: Bool {
        visual != nil || helper != nil
    }

    var textPadStyle: TextAnswerPadStyle {
        TextAnswerPadStyle.forTopic(topic)
    }

    func isCorrect(input: String, selectedChoice: Int?) -> Bool {
        switch answer {
        case .integer(let value):
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let entered = Int(trimmed) else { return false }
            return entered == value
        case .text(let value):
            if matchesAcceptedAnswer(input, primary: value) { return true }
            if let selectedChoice, let choices, choices.indices.contains(selectedChoice) {
                return matchesAcceptedAnswer(choices[selectedChoice], primary: value)
            }
            return false
        case .choiceIndex(let index):
            guard let choices, choices.indices.contains(index) else { return false }
            let correct = choices[index]
            if matchesAcceptedAnswer(input, primary: correct) { return true }
            if let selectedChoice, choices.indices.contains(selectedChoice) {
                return normalizedAnswer(choices[selectedChoice]) == normalizedAnswer(correct)
            }
            return false
        }
    }

    private func matchesAcceptedAnswer(_ input: String, primary: String) -> Bool {
        let typed = normalizedAnswer(input)
        guard !typed.isEmpty else { return false }
        var candidates = [primary]
        if let acceptedAnswers {
            candidates.append(contentsOf: acceptedAnswers)
        }
        return candidates.contains { normalizedAnswer($0) == typed }
    }

    private func normalizedAnswer(_ text: String) -> String {
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        value = value.replacingOccurrences(of: " ", with: "")
        return value
    }

    var correctDisplayAnswer: String {
        switch answer {
        case .integer(let value): "\(value)"
        case .text(let value): value
        case .choiceIndex(let index): choices?[index] ?? "\(index)"
        }
    }
}
