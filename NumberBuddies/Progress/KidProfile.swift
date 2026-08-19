import Foundation
import SwiftData

@Model
final class KidProfile {
    var id: UUID
    var name: String
    var ageGroupRaw: String
    var dailyStreak: Int
    var lastPlayDay: String
    var roundsCompleted: Int
    var totalCorrect: Int
    var totalQuestions: Int
    var createdAt: Date

    init(
        name: String,
        ageGroup: AgeGroup,
        dailyStreak: Int = 0,
        lastPlayDay: String = "",
        roundsCompleted: Int = 0,
        totalCorrect: Int = 0,
        totalQuestions: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.ageGroupRaw = ageGroup.rawValue
        self.dailyStreak = dailyStreak
        self.lastPlayDay = lastPlayDay
        self.roundsCompleted = roundsCompleted
        self.totalCorrect = totalCorrect
        self.totalQuestions = totalQuestions
        self.createdAt = Date()
    }

    var ageGroup: AgeGroup {
        AgeGroup(rawValue: ageGroupRaw) ?? .early
    }
}
