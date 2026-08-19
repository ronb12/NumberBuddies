import Foundation
import SwiftData

@Model
final class KidProgress {
    var profileId: String = ""
    var operationRaw: String
    var stars: Int
    var difficulty: Int
    var streak: Int

    init(
        profileId: UUID,
        operation: MathOperation,
        stars: Int = 0,
        difficulty: Int = 1,
        streak: Int = 0
    ) {
        self.profileId = profileId.uuidString
        self.operationRaw = operation.rawValue
        self.stars = stars
        self.difficulty = difficulty
        self.streak = streak
    }

    var operation: MathOperation {
        MathOperation(rawValue: operationRaw) ?? .addition
    }
}

enum ProfileStore {
    private static let activeProfileKey = "activeProfileId"

    static var activeProfileId: UUID? {
        get {
            guard let raw = UserDefaults.standard.string(forKey: activeProfileKey) else { return nil }
            return UUID(uuidString: raw)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.uuidString, forKey: activeProfileKey)
            } else {
                UserDefaults.standard.removeObject(forKey: activeProfileKey)
            }
        }
    }

    static func activeProfile(context: ModelContext) -> KidProfile? {
        guard let id = activeProfileId else { return nil }
        return profile(with: id, context: context)
    }

    static func profile(with id: UUID, context: ModelContext) -> KidProfile? {
        let key = id.uuidString
        let all = (try? context.fetch(FetchDescriptor<KidProfile>())) ?? []
        return all.first { $0.id.uuidString == key }
    }

    static func allProfiles(context: ModelContext) -> [KidProfile] {
        let descriptor = FetchDescriptor<KidProfile>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    @discardableResult
    static func createProfile(name: String, ageGroup: AgeGroup, context: ModelContext) -> Bool {
        if attemptCreateProfile(name: name, ageGroup: ageGroup, context: context) {
            return true
        }
        recoverStore(context: context)
        return attemptCreateProfile(name: name, ageGroup: ageGroup, context: context)
    }

    @discardableResult
    private static func attemptCreateProfile(name: String, ageGroup: AgeGroup, context: ModelContext) -> Bool {
        let profile = KidProfile(name: name, ageGroup: ageGroup)
        context.insert(profile)

        for operation in ageGroup.initialOperations {
            let progress = KidProgress(
                profileId: profile.id,
                operation: operation,
                difficulty: ageGroup.defaultDifficulty
            )
            context.insert(progress)
        }

        do {
            try context.save()
            activeProfileId = profile.id
            return true
        } catch {
            context.rollback()
            return false
        }
    }

    private static func recoverStore(context: ModelContext) {
        let progress = (try? context.fetch(FetchDescriptor<KidProgress>())) ?? []
        progress.forEach { context.delete($0) }
        let profiles = (try? context.fetch(FetchDescriptor<KidProfile>())) ?? []
        profiles.forEach { context.delete($0) }
        try? context.save()
        activeProfileId = nil
    }

    static func setActive(_ profile: KidProfile) {
        activeProfileId = profile.id
    }

    static func migrateLegacyProgressIfNeeded(context: ModelContext) {
        let profiles = allProfiles(context: context)
        let allProgress = (try? context.fetch(FetchDescriptor<KidProgress>())) ?? []
        let orphanProgress = allProgress.filter { $0.profileId.isEmpty }

        if profiles.isEmpty {
            if !orphanProgress.isEmpty {
                guard createProfile(name: "My Buddy", ageGroup: .early, context: context) else { return }
                let legacyId = activeProfileId
                for item in orphanProgress {
                    item.profileId = legacyId?.uuidString ?? ""
                }
                try? context.save()
            }
            return
        }

        if activeProfileId == nil, let first = profiles.first {
            activeProfileId = first.id
        }

        attachOrphanProgress(to: activeProfileId, context: context)
        normalizeSchoolAlignedLevels(context: context)
    }

    static func normalizeSchoolAlignedLevels(context: ModelContext) {
        let profiles = allProfiles(context: context)
        let allProgress = (try? context.fetch(FetchDescriptor<KidProgress>())) ?? []

        for profile in profiles where profile.ageGroup == .early {
            let key = profile.id.uuidString
            for item in allProgress where item.profileId == key {
                if item.operation == .multiplication || item.operation == .division, item.difficulty < 3 {
                    item.difficulty = 3
                }
            }
        }
        try? context.save()
    }

    private static func attachOrphanProgress(to profileId: UUID?, context: ModelContext) {
        guard let profileId else { return }
        let allProgress = (try? context.fetch(FetchDescriptor<KidProgress>())) ?? []
        for item in allProgress where item.profileId.isEmpty {
            item.profileId = profileId.uuidString
        }
        try? context.save()
    }

    static func dayString(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func recordDailyPlay(for profile: KidProfile) {
        let today = dayString()
        guard profile.lastPlayDay != today else { return }

        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           profile.lastPlayDay == dayString(yesterday) {
            profile.dailyStreak += 1
        } else {
            profile.dailyStreak = 1
        }
        profile.lastPlayDay = today
    }

    static func recordRoundStats(
        profile: KidProfile,
        correct: Int,
        total: Int,
        context: ModelContext
    ) {
        profile.roundsCompleted += 1
        profile.totalCorrect += correct
        profile.totalQuestions += total
        recordDailyPlay(for: profile)
        try? context.save()
    }

    static func updateAgeGroup(
        for profile: KidProfile,
        to ageGroup: AgeGroup,
        context: ModelContext
    ) {
        guard profile.ageGroup != ageGroup else { return }

        profile.ageGroupRaw = ageGroup.rawValue

        let key = profile.id.uuidString
        let all = (try? context.fetch(FetchDescriptor<KidProgress>())) ?? []
        let profileProgress = all.filter { $0.profileId == key }
        let allowedOperations = Set(ageGroup.homeOperations.map(\.rawValue))

        for item in profileProgress where !allowedOperations.contains(item.operationRaw) {
            context.delete(item)
        }

        for item in profileProgress where allowedOperations.contains(item.operationRaw) {
            item.difficulty = max(1, min(item.difficulty, ageGroup.maxDifficulty))
        }

        let existingOperations = Set(
            profileProgress
                .filter { allowedOperations.contains($0.operationRaw) }
                .map(\.operationRaw)
        )
        for operation in ageGroup.initialOperations where !existingOperations.contains(operation.rawValue) {
            context.insert(KidProgress(
                profileId: profile.id,
                operation: operation,
                difficulty: ageGroup.defaultDifficulty
            ))
        }

        if ageGroup == .upper {
            ProgressStore.ensureAllOperations(for: profile.id, ageGroup: ageGroup, context: context)
        }

        normalizeSchoolAlignedLevels(context: context)
        try? context.save()
    }

    static func resetProfileProgress(profileId: UUID, context: ModelContext) {
        let key = profileId.uuidString
        let all = (try? context.fetch(FetchDescriptor<KidProgress>())) ?? []
        for item in all where item.profileId == key {
            context.delete(item)
        }

        guard let profile = profile(with: profileId, context: context) else { return }
        for operation in profile.ageGroup.initialOperations {
            context.insert(KidProgress(
                profileId: profileId,
                operation: operation,
                difficulty: profile.ageGroup.defaultDifficulty
            ))
        }

        profile.dailyStreak = 0
        profile.lastPlayDay = ""
        profile.roundsCompleted = 0
        profile.totalCorrect = 0
        profile.totalQuestions = 0
        SessionStore.deleteSessions(for: profileId, context: context)
        try? context.save()
    }

    static func deleteProfile(_ profile: KidProfile, context: ModelContext) {
        let key = profile.id.uuidString
        let all = (try? context.fetch(FetchDescriptor<KidProgress>())) ?? []
        for item in all where item.profileId == key {
            context.delete(item)
        }
        SessionStore.deleteSessions(for: profile.id, context: context)
        if activeProfileId == profile.id {
            activeProfileId = nil
        }
        context.delete(profile)
        try? context.save()
    }
}

enum ProgressStore {
    static func unlockedOperations(
        for profile: KidProfile,
        context: ModelContext
    ) -> [MathOperation] {
        let items = progressItems(for: profile.id, context: context)
        switch profile.ageGroup {
        case .preK:
            return [.addition, .subtraction]
        case .early:
            let addLevel = items.first { $0.operation == .addition }?.difficulty ?? 1
            let subLevel = items.first { $0.operation == .subtraction }?.difficulty ?? 1
            let hasMultiplyProgress = items.contains { $0.operation == .multiplication }
            let multiplyUnlocked = hasMultiplyProgress
                || (addLevel >= AgeGroup.earlyMultiplyUnlockLevel && subLevel >= AgeGroup.earlyMultiplyUnlockLevel)

            if multiplyUnlocked {
                ensureProgressExists(
                    profileId: profile.id,
                    operations: [.multiplication, .division],
                    ageGroup: profile.ageGroup,
                    context: context
                )
                return MathOperation.allCases
            }
            return [.addition, .subtraction]
        case .upper:
            return MathOperation.allCases
        }
    }

    static func isOperationUnlocked(
        _ operation: MathOperation,
        for profile: KidProfile,
        context: ModelContext
    ) -> Bool {
        unlockedOperations(for: profile, context: context).contains(operation)
    }

    private static func ensureProgressExists(
        profileId: UUID,
        operations: [MathOperation],
        ageGroup: AgeGroup,
        context: ModelContext
    ) {
        let key = profileId.uuidString
        let all = (try? context.fetch(FetchDescriptor<KidProgress>())) ?? []
        for operation in operations {
            let exists = all.contains { $0.profileId == key && $0.operationRaw == operation.rawValue }
            guard !exists else { continue }
            context.insert(KidProgress(
                profileId: profileId,
                operation: operation,
                difficulty: max(3, ageGroup.defaultDifficulty)
            ))
        }
        try? context.save()
    }

    static func ensureAllOperations(
        for profileId: UUID,
        ageGroup: AgeGroup,
        context: ModelContext
    ) {
        ensureProgressExists(
            profileId: profileId,
            operations: MathOperation.allCases,
            ageGroup: ageGroup,
            context: context
        )
    }

    static func progressItems(for profileId: UUID, context: ModelContext) -> [KidProgress] {
        let key = profileId.uuidString
        let all = (try? context.fetch(FetchDescriptor<KidProgress>())) ?? []
        return all.filter { $0.profileId == key }
    }

    static func recordRound(
        profileId: UUID,
        operation: MathOperation,
        starsEarned: Int,
        correctCount: Int,
        totalQuestions: Int,
        context: ModelContext
    ) {
        let profileKey = profileId.uuidString
        let operationKey = operation.rawValue
        let all = (try? context.fetch(FetchDescriptor<KidProgress>())) ?? []
        let existing = all.first { $0.profileId == profileKey && $0.operationRaw == operationKey }
        let profile = ProfileStore.profile(with: profileId, context: context)
        let ageGroup = profile?.ageGroup ?? .early
        let progress = existing ?? KidProgress(
            profileId: profileId,
            operation: operation,
            difficulty: ageGroup.defaultDifficulty
        )

        progress.stars += starsEarned
        if correctCount >= totalQuestions - 1 {
            progress.streak += 1
            if progress.streak >= 2, progress.difficulty < ageGroup.maxDifficulty {
                progress.difficulty += 1
                progress.streak = 0
            }
        } else {
            progress.streak = 0
        }

        if existing == nil {
            context.insert(progress)
        }

        if let profile = ProfileStore.profile(with: profileId, context: context),
           profile.ageGroup == .early,
           operation == .addition || operation == .subtraction {
            _ = unlockedOperations(for: profile, context: context)
        }

        try? context.save()
    }

    static func recordMixedRound(
        profileId: UUID,
        results: [MathOperation: (correct: Int, total: Int, stars: Int)],
        context: ModelContext
    ) {
        for (operation, result) in results {
            recordRound(
                profileId: profileId,
                operation: operation,
                starsEarned: result.stars,
                correctCount: result.correct,
                totalQuestions: result.total,
                context: context
            )
        }
    }

    static func effectiveDifficulty(
        for operation: MathOperation,
        profile: KidProfile,
        storedDifficulty: Int
    ) -> Int {
        let level = max(1, min(storedDifficulty, profile.ageGroup.maxDifficulty))
        let allowed = profile.ageGroup.availableOperations(for: level)
        if allowed.contains(operation) {
            return level
        }
        if operation == .multiplication || operation == .division, profile.ageGroup == .early {
            return max(level, 3)
        }
        return level
    }

    static func difficulty(
        for operation: MathOperation,
        profileId: UUID,
        context: ModelContext
    ) -> Int {
        let profileKey = profileId.uuidString
        let operationKey = operation.rawValue
        let all = (try? context.fetch(FetchDescriptor<KidProgress>())) ?? []
        let stored = all.first { $0.profileId == profileKey && $0.operationRaw == operationKey }?.difficulty ?? 1
        guard let profile = ProfileStore.profile(with: profileId, context: context) else { return stored }
        return effectiveDifficulty(for: operation, profile: profile, storedDifficulty: stored)
    }

    static func averageDifficulty(profileId: UUID, operations: [MathOperation], context: ModelContext) -> Int {
        let levels = operations.map { difficulty(for: $0, profileId: profileId, context: context) }
        guard !levels.isEmpty else { return 1 }
        return max(1, levels.reduce(0, +) / levels.count)
    }
}
