import Foundation
import SwiftData

@Model
final class PracticeSession {
    var id: UUID
    var profileId: String
    var completedAt: Date
    var dayKey: String
    var modeTitle: String
    var correct: Int
    var total: Int
    var durationSeconds: Int
    var missedAddition: Int
    var missedSubtraction: Int
    var missedMultiplication: Int
    var missedDivision: Int
    var addCorrect: Int
    var addTotal: Int
    var subCorrect: Int
    var subTotal: Int
    var mulCorrect: Int
    var mulTotal: Int
    var divCorrect: Int
    var divTotal: Int

    init(
        profileId: UUID,
        completedAt: Date = Date(),
        modeTitle: String,
        correct: Int,
        total: Int,
        durationSeconds: Int,
        missedByOperation: [MathOperation: Int] = [:],
        operationResults: [MathOperation: (correct: Int, total: Int)] = [:]
    ) {
        self.id = UUID()
        self.profileId = profileId.uuidString
        self.completedAt = completedAt
        self.dayKey = ProfileStore.dayString(completedAt)
        self.modeTitle = modeTitle
        self.correct = correct
        self.total = total
        self.durationSeconds = max(0, durationSeconds)
        self.missedAddition = missedByOperation[.addition] ?? 0
        self.missedSubtraction = missedByOperation[.subtraction] ?? 0
        self.missedMultiplication = missedByOperation[.multiplication] ?? 0
        self.missedDivision = missedByOperation[.division] ?? 0
        self.addCorrect = operationResults[.addition]?.correct ?? 0
        self.addTotal = operationResults[.addition]?.total ?? 0
        self.subCorrect = operationResults[.subtraction]?.correct ?? 0
        self.subTotal = operationResults[.subtraction]?.total ?? 0
        self.mulCorrect = operationResults[.multiplication]?.correct ?? 0
        self.mulTotal = operationResults[.multiplication]?.total ?? 0
        self.divCorrect = operationResults[.division]?.correct ?? 0
        self.divTotal = operationResults[.division]?.total ?? 0
    }

    func operationResults() -> [MathOperation: (correct: Int, total: Int)] {
        var results: [MathOperation: (correct: Int, total: Int)] = [:]
        if addTotal > 0 { results[.addition] = (addCorrect, addTotal) }
        if subTotal > 0 { results[.subtraction] = (subCorrect, subTotal) }
        if mulTotal > 0 { results[.multiplication] = (mulCorrect, mulTotal) }
        if divTotal > 0 { results[.division] = (divCorrect, divTotal) }
        return results
    }

    var missedTotal: Int {
        missedAddition + missedSubtraction + missedMultiplication + missedDivision
    }

    func missedCount(for operation: MathOperation) -> Int {
        switch operation {
        case .addition: missedAddition
        case .subtraction: missedSubtraction
        case .multiplication: missedMultiplication
        case .division: missedDivision
        }
    }
}

struct DayPracticeSummary: Identifiable {
    let dayKey: String
    let rounds: Int
    let correct: Int
    let total: Int
    let durationSeconds: Int

    var id: String { dayKey }

    var accuracyPercent: Int {
        guard total > 0 else { return 0 }
        return Int((Double(correct) / Double(total)) * 100)
    }
}

enum SessionStore {
    static func recordSession(
        profileId: UUID,
        mode: PracticeMode,
        correct: Int,
        total: Int,
        durationSeconds: Int,
        missedByOperation: [MathOperation: Int],
        operationResults: [MathOperation: (correct: Int, total: Int)],
        context: ModelContext
    ) {
        let session = PracticeSession(
            profileId: profileId,
            modeTitle: mode.title,
            correct: correct,
            total: total,
            durationSeconds: durationSeconds,
            missedByOperation: missedByOperation,
            operationResults: operationResults
        )
        context.insert(session)
        try? context.save()
    }

    static func sessions(for profileId: UUID, context: ModelContext) -> [PracticeSession] {
        let key = profileId.uuidString
        let all = (try? context.fetch(FetchDescriptor<PracticeSession>())) ?? []
        return all
            .filter { $0.profileId == key }
            .sorted { $0.completedAt > $1.completedAt }
    }

    static func totalDurationSeconds(for profileId: UUID, context: ModelContext) -> Int {
        sessions(for: profileId, context: context).reduce(0) { $0 + $1.durationSeconds }
    }

    static func daySummaries(for profileId: UUID, lastDays: Int, context: ModelContext) -> [DayPracticeSummary] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var keys: [String] = []
        for offset in 0..<lastDays {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            keys.append(ProfileStore.dayString(date))
        }

        let grouped = Dictionary(grouping: sessions(for: profileId, context: context), by: \.dayKey)
        return keys.compactMap { key in
            guard let daySessions = grouped[key], !daySessions.isEmpty else { return nil }
            return DayPracticeSummary(
                dayKey: key,
                rounds: daySessions.count,
                correct: daySessions.reduce(0) { $0 + $1.correct },
                total: daySessions.reduce(0) { $0 + $1.total },
                durationSeconds: daySessions.reduce(0) { $0 + $1.durationSeconds }
            )
        }
    }

    static func missedTotals(for profileId: UUID, context: ModelContext) -> [MathOperation: Int] {
        missedTotals(in: sessions(for: profileId, context: context))
    }

    static func missedTotals(in sessions: [PracticeSession]) -> [MathOperation: Int] {
        var totals: [MathOperation: Int] = [:]
        for operation in MathOperation.allCases {
            totals[operation] = sessions.reduce(0) { $0 + $1.missedCount(for: operation) }
        }
        return totals.filter { $0.value > 0 }
    }

    static func sessions(
        for profileId: UUID,
        since startDate: Date,
        context: ModelContext
    ) -> [PracticeSession] {
        sessions(for: profileId, context: context).filter { $0.completedAt >= startDate }
    }

    static func operationAccuracy(
        in sessions: [PracticeSession],
        for operation: MathOperation
    ) -> Int? {
        var correct = 0
        var total = 0
        for session in sessions {
            if let stats = session.operationResults()[operation] {
                correct += stats.correct
                total += stats.total
            }
        }
        guard total > 0 else { return nil }
        return Int((Double(correct) / Double(total)) * 100)
    }

    static func periodAccuracy(in sessions: [PracticeSession]) -> Int {
        let correct = sessions.reduce(0) { $0 + $1.correct }
        let total = sessions.reduce(0) { $0 + $1.total }
        guard total > 0 else { return 0 }
        return Int((Double(correct) / Double(total)) * 100)
    }

    static func uniquePracticeDays(in sessions: [PracticeSession]) -> Int {
        Set(sessions.map(\.dayKey)).count
    }

    static func deleteSessions(for profileId: UUID, context: ModelContext) {
        let key = profileId.uuidString
        let all = (try? context.fetch(FetchDescriptor<PracticeSession>())) ?? []
        for session in all where session.profileId == key {
            context.delete(session)
        }
        try? context.save()
    }

    static func formattedDuration(_ seconds: Int) -> String {
        guard seconds > 0 else { return "0 min" }
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remainder = seconds % 60
        if remainder == 0 {
            return "\(minutes) min"
        }
        return "\(minutes)m \(remainder)s"
    }

    static func formattedDayLabel(for dayKey: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dayKey) else { return dayKey }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
