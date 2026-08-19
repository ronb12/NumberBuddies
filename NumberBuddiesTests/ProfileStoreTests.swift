import XCTest
import SwiftData
@testable import NumberBuddies

final class ProfileStoreTests: XCTestCase {
    func testAgeGroupCapsScaleWithLevel() {
        let preK = AgeGroup.preK.caps(for: 1)
        XCTAssertLessThanOrEqual(preK.maxSum, 5)

        let upper = AgeGroup.upper.caps(for: 4)
        XCTAssertGreaterThanOrEqual(upper.maxSum, 1000)
    }

    func testPreKOnlyOffersAdditionAndSubtraction() {
        XCTAssertEqual(AgeGroup.preK.initialOperations, [.addition, .subtraction])
        XCTAssertEqual(AgeGroup.early.initialOperations, [.addition, .subtraction])
        XCTAssertEqual(AgeGroup.early.homeOperations.count, 4)
    }

    func testDayStringIsStableFormat() {
        let value = ProfileStore.dayString(Date(timeIntervalSince1970: 0))
        XCTAssertEqual(value.count, 10)
        XCTAssertTrue(value.contains("-"))
    }

    @MainActor
    func testUpdateAgeGroupReconcilesProgress() throws {
        let container = try ModelContainer(
            for: KidProfile.self, KidProgress.self, PracticeSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let profile = KidProfile(name: "Sam", ageGroup: .preK)
        context.insert(profile)
        context.insert(KidProgress(profileId: profile.id, operation: .addition, difficulty: 2))
        context.insert(KidProgress(profileId: profile.id, operation: .subtraction, difficulty: 2))
        try context.save()

        ProfileStore.updateAgeGroup(for: profile, to: .upper, context: context)

        XCTAssertEqual(profile.ageGroup, .upper)
        let items = ProgressStore.progressItems(for: profile.id, context: context)
        XCTAssertEqual(items.count, 4)
        XCTAssertTrue(items.contains { $0.operation == .multiplication })
        XCTAssertTrue(items.contains { $0.operation == .division })
    }
}
