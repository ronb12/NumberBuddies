import Foundation
import SwiftUI

enum PracticeMode: Hashable {
    case operation(MathOperation)
    case mixedReview
    case mathChallenge(MathChallengeKind)

    var title: String {
        switch self {
        case .operation(let op): op.title
        case .mixedReview: "Mixed Review"
        case .mathChallenge(let kind): kind.title
        }
    }

    var iconName: String {
        switch self {
        case .operation(let op): op.iconName
        case .mixedReview: "shuffle"
        case .mathChallenge(let kind): kind.iconName
        }
    }

    var accentColor: Color {
        switch self {
        case .operation(let op): AppTheme.color(for: op)
        case .mixedReview: AppTheme.purple
        case .mathChallenge(let kind): AppTheme.color(for: kind.operation)
        }
    }

    var progressOperation: MathOperation? {
        switch self {
        case .operation(let op): op
        case .mathChallenge(let kind): kind.operation
        case .mixedReview: nil
        }
    }
}
