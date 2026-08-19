import SwiftData
import XCTest
@testable import NumberBuddies

@MainActor
final class AcademicReportBuilderTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        container = try ModelContainer(
            for: KidProfile.self, KidProgress.self, PracticeSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    func testBuildsSchoolStyleReportFromSessions() throws {
        let profile = KidProfile(name: "Jordan", ageGroup: .early)
        context.insert(profile)
        context.insert(KidProgress(profileId: profile.id, operation: .addition, stars: 12, difficulty: 2))
        context.insert(KidProgress(profileId: profile.id, operation: .subtraction, stars: 8, difficulty: 2))
        try context.save()

        SessionStore.recordSession(
            profileId: profile.id,
            mode: .operation(.addition),
            correct: 8,
            total: 9,
            durationSeconds: 300,
            missedByOperation: [.addition: 1],
            operationResults: [.addition: (8, 9)],
            context: context
        )

        let report = AcademicReportBuilder.build(profile: profile, context: context)

        XCTAssertEqual(report.studentName, "Jordan")
        XCTAssertEqual(report.gradeEquivalent, "Grades 1–2")
        XCTAssertFalse(report.subjects.isEmpty)
        XCTAssertTrue(report.hasPeriodActivity)
        XCTAssertGreaterThan(report.overallAccuracy, 0)
        XCTAssertFalse(report.teacherComment.isEmpty)
        XCTAssertFalse(report.nextSteps.isEmpty)
        XCTAssertEqual(report.subjects.first?.operation, .addition)
    }

    func testProficiencyLevelsFollowAccuracyAndLevel() {
        XCTAssertEqual(
            AcademicReportBuilder.proficiency(level: 4, maxLevel: 4, accuracy: 90, missedCount: 0),
            .exceeds
        )
        XCTAssertEqual(
            AcademicReportBuilder.proficiency(level: 2, maxLevel: 4, accuracy: 75, missedCount: 1),
            .meets
        )
        XCTAssertEqual(
            AcademicReportBuilder.proficiency(level: 1, maxLevel: 4, accuracy: 40, missedCount: 4),
            .approaching
        )
    }

    func testStandardsTextReferencesGradeSkills() {
        let text = CurriculumStandards.standardDescription(for: .addition, ageGroup: .early, level: 2)
        XCTAssertTrue(text.contains("20"))
        let upper = CurriculumStandards.standardDescription(for: .division, ageGroup: .upper, level: 4)
        XCTAssertTrue(upper.lowercased().contains("remainder"))
    }

    func testEmptyPeriodShowsBeginningProficiency() throws {
        let profile = KidProfile(name: "Avery", ageGroup: .preK)
        context.insert(profile)
        context.insert(KidProgress(profileId: profile.id, operation: .addition))
        try context.save()

        let report = AcademicReportBuilder.build(profile: profile, context: context)
        XCTAssertFalse(report.hasPeriodActivity)
        XCTAssertEqual(report.overallProficiency, .beginning)
        XCTAssertTrue(report.teacherComment.contains("No completed practice rounds"))
    }
}
