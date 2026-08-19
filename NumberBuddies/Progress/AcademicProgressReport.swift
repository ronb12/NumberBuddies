import Foundation
import SwiftData

enum ProficiencyLevel: String, CaseIterable {
    case exceeds = "Exceeds Expectations"
    case meets = "Meets Expectations"
    case approaching = "Approaching Expectations"
    case beginning = "Beginning"

    var shortLabel: String {
        switch self {
        case .exceeds: "Exceeds"
        case .meets: "Meets"
        case .approaching: "Approaching"
        case .beginning: "Beginning"
        }
    }
}

struct SubjectAssessment: Identifiable {
    let operation: MathOperation
    let level: Int
    let maxLevel: Int
    let stars: Int
    let standardDescription: String
    let proficiency: ProficiencyLevel
    let letterGrade: String
    let periodAccuracy: Int?
    let missedCount: Int
    let comment: String

    var id: String { operation.rawValue }

    var levelProgressPercent: Int {
        guard maxLevel > 0 else { return 0 }
        return Int((Double(level) / Double(maxLevel)) * 100)
    }
}

struct AcademicProgressReport {
    let studentName: String
    let gradeEquivalent: String
    let curriculumBand: String
    let reportDate: Date
    let periodStart: Date
    let periodEnd: Date
    let reportingPeriodLabel: String
    let overallLetterGrade: String
    let overallProficiency: ProficiencyLevel
    let overallAccuracy: Int
    let lifetimeAccuracy: Int
    let daysPracticed: Int
    let daysInPeriod: Int
    let participationRate: Int
    let totalTimeSeconds: Int
    let periodRounds: Int
    let lifetimeRounds: Int
    let dailyStreak: Int
    let totalStars: Int
    let subjects: [SubjectAssessment]
    let weeklyLog: [DayPracticeSummary]
    let strengths: [String]
    let growthAreas: [String]
    let teacherComment: String
    let nextSteps: [String]
    let hasPeriodActivity: Bool
}

enum CurriculumStandards {
    static func gradeEquivalent(for ageGroup: AgeGroup) -> String {
        switch ageGroup {
        case .preK: "Kindergarten"
        case .early: "Grades 1–2"
        case .upper: "Grades 3–5"
        }
    }

    static func standardDescription(
        for operation: MathOperation,
        ageGroup: AgeGroup,
        level: Int
    ) -> String {
        let level = max(1, min(level, ageGroup.maxDifficulty))
        switch (ageGroup, operation) {
        case (.preK, .addition):
            return level == 1
                ? "Counts and joins sets within 5 (K.CC, K.OA)"
                : "Adds within 10 using objects and pictures (K.OA.A.2)"
        case (.preK, .subtraction):
            return level == 1
                ? "Takes away within 5 with visual models (K.OA)"
                : "Subtracts within 10 from a given total (K.OA.A.2)"
        case (.early, .addition):
            switch level {
            case 1: return "Fluently adds within 10 (1.OA.C.6)"
            case 2: return "Adds within 20 using mental strategies (1.OA.C.6, 2.OA.B.2)"
            default: return "Adds two-digit numbers with regrouping (2.NBT.B.5)"
            }
        case (.early, .subtraction):
            switch level {
            case 1: return "Fluently subtracts within 10 (1.OA.C.6)"
            case 2: return "Subtracts within 20 using mental strategies (1.OA.C.6, 2.OA.B.2)"
            default: return "Subtracts two-digit numbers with regrouping (2.NBT.B.5)"
            }
        case (.early, .multiplication):
            return level <= 3
                ? "Uses equal groups and arrays for × facts through 5 (2.OA.C.4)"
                : "Recalls multiplication facts through 10 (3.OA.C.7)"
        case (.early, .division):
            return level <= 3
                ? "Shares equally into groups (3.OA.A.2)"
                : "Relates division to multiplication facts (3.OA.C.7)"
        case (.upper, .addition):
            return level >= 3
                ? "Adds multi-digit numbers with regrouping (3.NBT.A.2, 4.NBT.B.4)"
                : "Adds within 100 using place value (2.NBT.B.5)"
        case (.upper, .subtraction):
            return level >= 3
                ? "Subtracts multi-digit numbers with regrouping (3.NBT.A.2, 4.NBT.B.4)"
                : "Subtracts within 100 using place value (2.NBT.B.5)"
        case (.upper, .multiplication):
            return level >= 4
                ? "Multiplies two-digit by one-digit numbers (4.NBT.B.5)"
                : "Fluently multiplies within 100 (3.OA.C.7)"
        case (.upper, .division):
            return level >= 3
                ? "Divides with remainders and interprets results (4.OA.A.3, 4.NBT.B.6)"
                : "Divides within 100 using fact families (3.OA.C.7)"
        default:
            return operation.title
        }
    }
}

enum AcademicReportBuilder {
    static let reportingPeriodDays = 30

    static func build(profile: KidProfile, context: ModelContext) -> AcademicProgressReport {
        let calendar = Calendar.current
        let periodEnd = Date()
        let periodStart = calendar.date(byAdding: .day, value: -(reportingPeriodDays - 1), to: calendar.startOfDay(for: periodEnd)) ?? periodEnd
        let profileStart = calendar.startOfDay(for: profile.createdAt)
        let effectiveStart = max(periodStart, profileStart)
        let daysInPeriod = max(1, calendar.dateComponents([.day], from: effectiveStart, to: calendar.startOfDay(for: periodEnd)).day ?? 1) + 1

        let allSessions = SessionStore.sessions(for: profile.id, context: context)
        let periodSessions = allSessions.filter { $0.completedAt >= effectiveStart }
        let progressItems = ProgressStore.progressItems(for: profile.id, context: context)
        let unlocked = ProgressStore.unlockedOperations(for: profile, context: context)
        let missedInPeriod = SessionStore.missedTotals(in: periodSessions)

        let periodAccuracy = SessionStore.periodAccuracy(in: periodSessions)
        let lifetimeAccuracy = profile.totalQuestions > 0
            ? Int((Double(profile.totalCorrect) / Double(profile.totalQuestions)) * 100)
            : 0
        let daysPracticed = SessionStore.uniquePracticeDays(in: periodSessions)
        let participationRate = min(100, Int((Double(daysPracticed) / Double(daysInPeriod)) * 100))
        let periodTime = periodSessions.reduce(0) { $0 + $1.durationSeconds }
        let totalStars = progressItems.reduce(0) { $0 + $1.stars }

        let subjects = unlocked.map { operation in
            let item = progressItems.first { $0.operation == operation }
            let level = ProgressStore.effectiveDifficulty(
                for: operation,
                profile: profile,
                storedDifficulty: item?.difficulty ?? profile.ageGroup.defaultDifficulty
            )
            let stars = item?.stars ?? 0
            let periodAcc = SessionStore.operationAccuracy(in: periodSessions, for: operation)
            let missed = missedInPeriod[operation] ?? 0
            let proficiency = proficiency(
                level: level,
                maxLevel: profile.ageGroup.maxDifficulty,
                accuracy: periodAcc ?? lifetimeAccuracy,
                missedCount: missed
            )
            let letter = letterGrade(
                level: level,
                maxLevel: profile.ageGroup.maxDifficulty,
                accuracy: periodAcc ?? lifetimeAccuracy
            )

            return SubjectAssessment(
                operation: operation,
                level: level,
                maxLevel: profile.ageGroup.maxDifficulty,
                stars: stars,
                standardDescription: CurriculumStandards.standardDescription(
                    for: operation,
                    ageGroup: profile.ageGroup,
                    level: level
                ),
                proficiency: proficiency,
                letterGrade: letter,
                periodAccuracy: periodAcc,
                missedCount: missed,
                comment: subjectComment(
                    operation: operation,
                    proficiency: proficiency,
                    level: level,
                    maxLevel: profile.ageGroup.maxDifficulty,
                    missed: missed
                )
            )
        }

        let overallProficiency = overallProficiency(from: subjects, participation: participationRate, hasActivity: !periodSessions.isEmpty)
        let overallLetter = overallLetterGrade(from: subjects, accuracy: periodSessions.isEmpty ? lifetimeAccuracy : periodAccuracy)

        let strengths = buildStrengths(subjects: subjects, participation: participationRate, streak: profile.dailyStreak)
        let growthAreas = buildGrowthAreas(subjects: subjects, participation: participationRate, daysPracticed: daysPracticed, daysInPeriod: daysInPeriod)
        let nextSteps = buildNextSteps(subjects: subjects, ageGroup: profile.ageGroup)
        let teacherComment = buildTeacherComment(
            name: profile.name,
            gradeEquivalent: CurriculumStandards.gradeEquivalent(for: profile.ageGroup),
            daysPracticed: daysPracticed,
            daysInPeriod: daysInPeriod,
            periodRounds: periodSessions.count,
            accuracy: periodSessions.isEmpty ? lifetimeAccuracy : periodAccuracy,
            strengths: strengths,
            growthAreas: growthAreas,
            hasPeriodActivity: !periodSessions.isEmpty
        )

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let periodLabel = "\(formatter.string(from: effectiveStart)) – \(formatter.string(from: periodEnd))"

        return AcademicProgressReport(
            studentName: profile.name,
            gradeEquivalent: CurriculumStandards.gradeEquivalent(for: profile.ageGroup),
            curriculumBand: profile.ageGroup.subtitle,
            reportDate: periodEnd,
            periodStart: effectiveStart,
            periodEnd: periodEnd,
            reportingPeriodLabel: periodLabel,
            overallLetterGrade: overallLetter,
            overallProficiency: overallProficiency,
            overallAccuracy: periodSessions.isEmpty ? lifetimeAccuracy : periodAccuracy,
            lifetimeAccuracy: lifetimeAccuracy,
            daysPracticed: daysPracticed,
            daysInPeriod: daysInPeriod,
            participationRate: participationRate,
            totalTimeSeconds: periodTime,
            periodRounds: periodSessions.count,
            lifetimeRounds: profile.roundsCompleted,
            dailyStreak: profile.dailyStreak,
            totalStars: totalStars,
            subjects: subjects,
            weeklyLog: SessionStore.daySummaries(for: profile.id, lastDays: 7, context: context),
            strengths: strengths,
            growthAreas: growthAreas,
            teacherComment: teacherComment,
            nextSteps: nextSteps,
            hasPeriodActivity: !periodSessions.isEmpty
        )
    }

    static func proficiency(
        level: Int,
        maxLevel: Int,
        accuracy: Int,
        missedCount: Int
    ) -> ProficiencyLevel {
        let levelRatio = Double(level) / Double(max(1, maxLevel))
        if levelRatio >= 0.75, accuracy >= 85, missedCount <= 2 {
            return .exceeds
        }
        if levelRatio >= 0.5, accuracy >= 70 {
            return .meets
        }
        if levelRatio >= 0.25 || accuracy >= 50 || missedCount <= 5 {
            return .approaching
        }
        return .beginning
    }

    static func letterGrade(level: Int, maxLevel: Int, accuracy: Int) -> String {
        let levelRatio = Double(level) / Double(max(1, maxLevel))
        if accuracy >= 90, levelRatio >= 0.75 { return "A" }
        if accuracy >= 80, levelRatio >= 0.5 { return "B" }
        if accuracy >= 70 { return "C" }
        if accuracy >= 60 { return "D" }
        return accuracy == 0 && level <= 1 ? "—" : "F"
    }

    private static func overallProficiency(
        from subjects: [SubjectAssessment],
        participation: Int,
        hasActivity: Bool
    ) -> ProficiencyLevel {
        guard hasActivity, !subjects.isEmpty else { return .beginning }
        let scores = subjects.map { proficiencyScore($0.proficiency) }
        let average = Double(scores.reduce(0, +)) / Double(scores.count)
        if average >= 3.5, participation >= 50 { return .exceeds }
        if average >= 2.5 { return .meets }
        if average >= 1.5 { return .approaching }
        return .beginning
    }

    private static func overallLetterGrade(from subjects: [SubjectAssessment], accuracy: Int) -> String {
        guard !subjects.isEmpty else { return "—" }
        let grades = subjects.map(\.letterGrade).filter { $0 != "—" }
        guard !grades.isEmpty else { return letterGrade(level: 1, maxLevel: 4, accuracy: accuracy) }
        let average = grades.map(letterScore).reduce(0, +) / grades.count
        switch average {
        case 4: return "A"
        case 3: return "B"
        case 2: return "C"
        case 1: return "D"
        default: return "F"
        }
    }

    private static func proficiencyScore(_ level: ProficiencyLevel) -> Int {
        switch level {
        case .exceeds: 4
        case .meets: 3
        case .approaching: 2
        case .beginning: 1
        }
    }

    private static func letterScore(_ grade: String) -> Int {
        switch grade {
        case "A": 4
        case "B": 3
        case "C": 2
        case "D": 1
        default: 0
        }
    }

    private static func subjectComment(
        operation: MathOperation,
        proficiency: ProficiencyLevel,
        level: Int,
        maxLevel: Int,
        missed: Int
    ) -> String {
        switch proficiency {
        case .exceeds:
            return "Strong \(operation.title.lowercased()) skills at level \(level) of \(maxLevel)."
        case .meets:
            return "On grade level for \(operation.title.lowercased()) at level \(level)."
        case .approaching:
            if missed > 0 {
                return "Building \(operation.title.lowercased()) fluency; \(missed) problem\(missed == 1 ? "" : "s") needed extra support this period."
            }
            return "Progressing toward grade-level \(operation.title.lowercased()) goals."
        case .beginning:
            return "Needs continued practice with \(operation.title.lowercased()) foundations."
        }
    }

    private static func buildStrengths(
        subjects: [SubjectAssessment],
        participation: Int,
        streak: Int
    ) -> [String] {
        var items: [String] = []
        let strong = subjects.filter { $0.proficiency == .exceeds || $0.proficiency == .meets }
        if let best = strong.max(by: { ($0.periodAccuracy ?? 0) < ($1.periodAccuracy ?? 0) }) {
            items.append("Shows solid \(best.operation.title.lowercased()) understanding (\(best.proficiency.shortLabel)).")
        }
        if participation >= 60 {
            items.append("Consistent practice participation this reporting period.")
        }
        if streak >= 3 {
            items.append("Maintains a \(streak)-day practice streak.")
        }
        if items.isEmpty, subjects.contains(where: { $0.stars > 0 }) {
            items.append("Earned stars across multiple math skills.")
        }
        return items
    }

    private static func buildGrowthAreas(
        subjects: [SubjectAssessment],
        participation: Int,
        daysPracticed: Int,
        daysInPeriod: Int
    ) -> [String] {
        var items: [String] = []
        let weak = subjects
            .filter { $0.proficiency == .beginning || $0.proficiency == .approaching || $0.missedCount > 0 }
            .sorted { $0.missedCount > $1.missedCount }

        for subject in weak.prefix(2) where subject.missedCount > 0 {
            items.append("\(subject.operation.title): \(subject.missedCount) problem\(subject.missedCount == 1 ? "" : "s") needed a hint after two tries.")
        }
        if let lowest = weak.first, lowest.missedCount == 0, lowest.proficiency != .exceeds {
            items.append("Continue building \(lowest.operation.title.lowercased()) fluency at level \(lowest.level).")
        }
        if participation < 40, daysInPeriod > 3 {
            items.append("Practice days (\(daysPracticed) of \(daysInPeriod)) — aim for short daily sessions.")
        }
        return items
    }

    private static func buildNextSteps(subjects: [SubjectAssessment], ageGroup: AgeGroup) -> [String] {
        var steps: [String] = []
        if let focus = subjects.first(where: { $0.missedCount > 0 }) {
            steps.append("Review \(focus.operation.title.lowercased()) with visual helpers and story problems.")
        }
        if subjects.contains(where: { $0.proficiency == .meets || $0.proficiency == .exceeds }) {
            steps.append("Try Mixed Review to keep all skills sharp.")
        }
        switch ageGroup {
        case .preK:
            steps.append("Keep sessions short — 5–10 minutes of counting and adding is ideal.")
        case .early:
            steps.append("Practice daily to unlock multiplication and division when +/− reach level 2.")
        case .upper:
            steps.append("Work toward regrouping and remainder problems at higher levels.")
        }
        return Array(steps.prefix(3))
    }

    private static func buildTeacherComment(
        name: String,
        gradeEquivalent: String,
        daysPracticed: Int,
        daysInPeriod: Int,
        periodRounds: Int,
        accuracy: Int,
        strengths: [String],
        growthAreas: [String],
        hasPeriodActivity: Bool
    ) -> String {
        if !hasPeriodActivity {
            return "\(name) is enrolled in the \(gradeEquivalent) math track in Number Buddies. No completed practice rounds appear in the current reporting period yet. Short daily sessions will populate this report with grades and standards progress."
        }

        var parts: [String] = []
        parts.append("\(name) is working in the \(gradeEquivalent) math curriculum this period.")
        parts.append("They practiced on \(daysPracticed) of \(daysInPeriod) days, completing \(periodRounds) round\(periodRounds == 1 ? "" : "s") with \(accuracy)% accuracy.")
        if let strength = strengths.first {
            parts.append(strength)
        }
        if let growth = growthAreas.first {
            parts.append(growth)
        } else {
            parts.append("Keep up the steady practice to maintain progress.")
        }
        return parts.joined(separator: " ")
    }
}
