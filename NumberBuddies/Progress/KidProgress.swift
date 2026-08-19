import Foundation
import SwiftData

@Model
final class KidProgress {
    var operationRaw: String
    var stars: Int
    var difficulty: Int
    var streak: Int

    init(operation: MathOperation, stars: Int = 0, difficulty: Int = 1, streak: Int = 0) {
        self.operationRaw = operation.rawValue
        self.stars = stars
        self.difficulty = difficulty
        self.streak = streak
    }

    var operation: MathOperation {
        MathOperation(rawValue: operationRaw) ?? .addition
    }
}

enum ProgressStore {
    static func recordRound(
        operation: MathOperation,
        starsEarned: Int,
        correctCount: Int,
        context: ModelContext
    ) {
        let operationKey = operation.rawValue
        let descriptor = FetchDescriptor<KidProgress>(
            predicate: #Predicate { $0.operationRaw == operationKey }
        )
        let existing = try? context.fetch(descriptor).first
        let progress = existing ?? KidProgress(operation: operation)

        progress.stars += starsEarned
        if correctCount >= ProblemGenerator.questionsPerRound - 1 {
            progress.streak += 1
            if progress.streak >= 2, progress.difficulty < 3 {
                progress.difficulty += 1
                progress.streak = 0
            }
        } else {
            progress.streak = 0
        }

        if existing == nil {
            context.insert(progress)
        }
        try? context.save()
    }

    static func stars(for operation: MathOperation, context: ModelContext) -> Int {
        let operationKey = operation.rawValue
        let descriptor = FetchDescriptor<KidProgress>(
            predicate: #Predicate { $0.operationRaw == operationKey }
        )
        return (try? context.fetch(descriptor).first?.stars) ?? 0
    }

    static func totalStars(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<KidProgress>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.reduce(0) { $0 + $1.stars }
    }

    static func difficulty(for operation: MathOperation, context: ModelContext) -> Int {
        let operationKey = operation.rawValue
        let descriptor = FetchDescriptor<KidProgress>(
            predicate: #Predicate { $0.operationRaw == operationKey }
        )
        return (try? context.fetch(descriptor).first?.difficulty) ?? 1
    }
}
