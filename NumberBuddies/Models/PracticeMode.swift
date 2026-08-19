import Foundation
import SwiftUI

enum PracticeMode: Hashable {
    case operation(MathOperation)
    case mixedReview
    case timesTableChallenge(TimesTableChallengeKind)

    var title: String {
        switch self {
        case .operation(let op): op.title
        case .mixedReview: "Mixed Review"
        case .timesTableChallenge(let kind): kind.title
        }
    }

    var iconName: String {
        switch self {
        case .operation(let op): op.iconName
        case .mixedReview: "shuffle"
        case .timesTableChallenge(let kind): kind.iconName
        }
    }

    var accentColor: Color {
        switch self {
        case .operation(let op): AppTheme.color(for: op)
        case .mixedReview: AppTheme.purple
        case .timesTableChallenge: AppTheme.sunny
        }
    }

    var progressOperation: MathOperation? {
        switch self {
        case .operation(let op): op
        case .timesTableChallenge: .multiplication
        case .mixedReview: nil
        }
    }
}
