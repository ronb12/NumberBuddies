import Foundation

enum MathOperation: String, CaseIterable, Codable, Identifiable, Sendable {
    case addition
    case subtraction
    case multiplication
    case division

    var id: String { rawValue }

    var title: String {
        switch self {
        case .addition: "Addition"
        case .subtraction: "Subtraction"
        case .multiplication: "Multiplication"
        case .division: "Division"
        }
    }

    var symbol: String {
        switch self {
        case .addition: "+"
        case .subtraction: "-"
        case .multiplication: "x"
        case .division: "/"
        }
    }

    var iconName: String {
        switch self {
        case .addition: "plus.circle.fill"
        case .subtraction: "minus.circle.fill"
        case .multiplication: "multiply.circle.fill"
        case .division: "divide.circle.fill"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .addition: "Practice putting numbers together"
        case .subtraction: "Practice taking numbers away"
        case .multiplication: "Practice equal groups"
        case .division: "Practice fair sharing"
        }
    }
}
