import Foundation

enum AgeGroup: String, CaseIterable, Codable, Identifiable, Sendable {
    case preK
    case early
    case upper

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preK: "Ages 4–6"
        case .early: "Ages 6–8"
        case .upper: "Ages 9–11"
        }
    }

    var subtitle: String {
        switch self {
        case .preK: "Kindergarten: count & add/sub within 10"
        case .early: "Grades 1–2: +/− then ×/÷ facts"
        case .upper: "Grades 3–5: facts, regrouping & remainders"
        }
    }

    var defaultDifficulty: Int {
        switch self {
        case .preK: 1
        case .early: 1
        case .upper: 1
        }
    }

    var maxDifficulty: Int {
        switch self {
        case .preK: 2
        case .early: 4
        case .upper: 4
        }
    }

    var questionsPerRound: Int {
        switch self {
        case .preK: 6
        case .early: 9
        case .upper: 10
        }
    }

    /// Operations created when a new profile is made.
    var initialOperations: [MathOperation] {
        switch self {
        case .preK, .early: [.addition, .subtraction]
        case .upper: MathOperation.allCases
        }
    }

    /// All operation cards shown on the home screen for this age band.
    var homeOperations: [MathOperation] {
        switch self {
        case .preK: [.addition, .subtraction]
        case .early, .upper: MathOperation.allCases
        }
    }

    struct Caps {
        let maxSum: Int
        let maxValue: Int
        let maxFactor: Int
        let twoDigitMultiplication: Bool
    }

    func caps(for level: Int) -> Caps {
        let level = max(1, min(level, maxDifficulty))
        switch self {
        case .preK:
            switch level {
            case 1: return Caps(maxSum: 5, maxValue: 5, maxFactor: 0, twoDigitMultiplication: false)
            default: return Caps(maxSum: 10, maxValue: 10, maxFactor: 0, twoDigitMultiplication: false)
            }
        case .early:
            switch level {
            case 1: return Caps(maxSum: 10, maxValue: 10, maxFactor: 0, twoDigitMultiplication: false)
            case 2: return Caps(maxSum: 20, maxValue: 20, maxFactor: 0, twoDigitMultiplication: false)
            case 3: return Caps(maxSum: 100, maxValue: 100, maxFactor: 5, twoDigitMultiplication: false)
            default: return Caps(maxSum: 100, maxValue: 100, maxFactor: 10, twoDigitMultiplication: false)
            }
        case .upper:
            switch level {
            case 1: return Caps(maxSum: 100, maxValue: 100, maxFactor: 10, twoDigitMultiplication: false)
            case 2: return Caps(maxSum: 500, maxValue: 500, maxFactor: 12, twoDigitMultiplication: false)
            case 3: return Caps(maxSum: 1000, maxValue: 1000, maxFactor: 12, twoDigitMultiplication: false)
            default: return Caps(maxSum: 1000, maxValue: 1000, maxFactor: 12, twoDigitMultiplication: true)
            }
        }
    }

    func availableOperations(for level: Int) -> [MathOperation] {
        switch self {
        case .preK:
            return [.addition, .subtraction]
        case .early:
            return level >= 3 ? MathOperation.allCases : [.addition, .subtraction]
        case .upper:
            return MathOperation.allCases
        }
    }

    func prefersRegrouping(for level: Int) -> Bool {
        switch self {
        case .preK: false
        case .early: level >= 3
        case .upper: level >= 1
        }
    }

    func allowsRemainders(for level: Int) -> Bool {
        switch self {
        case .preK, .early: false
        case .upper: level >= 3
        }
    }

    /// Grade 2 gate: both addition and subtraction reach level 2 (+/− within 20).
    static let earlyMultiplyUnlockLevel = 2
}
