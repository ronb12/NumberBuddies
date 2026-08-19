import SwiftData
import XCTest
@testable import NumberBuddies

@MainActor
final class OnboardingFlowTests: XCTestCase {
    func testCreateProfilePersistsAndSetsActive() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: KidProfile.self, KidProgress.self, configurations: config)
        let context = container.mainContext

        let saved = ProfileStore.createProfile(name: "Sam", ageGroup: .preK, context: context)
        XCTAssertTrue(saved)

        let profiles = ProfileStore.allProfiles(context: context)
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.name, "Sam")
        XCTAssertEqual(profiles.first?.ageGroup, .preK)
        XCTAssertEqual(ProfileStore.activeProfileId, profiles.first?.id)

        let progress = ProgressStore.progressItems(for: profiles.first!.id, context: context)
        XCTAssertEqual(progress.count, 2)
        XCTAssertEqual(ProgressStore.unlockedOperations(for: profiles.first!, context: context).count, 2)
    }
}
