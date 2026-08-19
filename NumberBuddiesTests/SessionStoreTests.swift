import SwiftData
import XCTest
@testable import NumberBuddies

@MainActor
final class SessionStoreTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var profileId: UUID!

    override func setUp() async throws {
        container = try ModelContainer(
            for: KidProfile.self, KidProgress.self, PracticeSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        let profile = KidProfile(name: "Test", ageGroup: .early)
        context.insert(profile)
        try context.save()
        profileId = profile.id
    }

    func testRecordSessionAggregatesByDay() throws {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        SessionStore.recordSession(
            profileId: profileId,
            mode: .operation(.addition),
            correct: 5,
            total: 6,
            durationSeconds: 120,
            missedByOperation: [.addition: 1],
            operationResults: [.addition: (5, 6)],
            context: context
        )

        let session = PracticeSession(
            profileId: profileId,
            completedAt: yesterday,
            modeTitle: "Subtraction",
            correct: 4,
            total: 6,
            durationSeconds: 90,
            missedByOperation: [.subtraction: 2]
        )
        context.insert(session)
        try context.save()

        let summaries = SessionStore.daySummaries(for: profileId, lastDays: 7, context: context)
        XCTAssertEqual(summaries.count, 2)
        XCTAssertEqual(SessionStore.totalDurationSeconds(for: profileId, context: context), 210)

        let missed = SessionStore.missedTotals(for: profileId, context: context)
        XCTAssertEqual(missed[.addition], 1)
        XCTAssertEqual(missed[.subtraction], 2)
    }

    func testFormattedDuration() {
        XCTAssertEqual(SessionStore.formattedDuration(0), "0 min")
        XCTAssertEqual(SessionStore.formattedDuration(45), "45s")
        XCTAssertEqual(SessionStore.formattedDuration(120), "2 min")
        XCTAssertEqual(SessionStore.formattedDuration(125), "2m 5s")
    }

    func testDeleteSessionsForProfile() throws {
        SessionStore.recordSession(
            profileId: profileId,
            mode: .operation(.addition),
            correct: 6,
            total: 6,
            durationSeconds: 60,
            missedByOperation: [:],
            operationResults: [.addition: (6, 6)],
            context: context
        )
        XCTAssertEqual(SessionStore.sessions(for: profileId, context: context).count, 1)

        SessionStore.deleteSessions(for: profileId, context: context)
        XCTAssertTrue(SessionStore.sessions(for: profileId, context: context).isEmpty)
    }
}
