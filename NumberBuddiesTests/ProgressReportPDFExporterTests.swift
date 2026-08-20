import XCTest
@testable import NumberBuddies

final class ProgressReportPDFExporterTests: XCTestCase {
    func testGeneratesValidPDFData() {
        let report = sampleReport()
        let data = ProgressReportPDFExporter.generatePDF(from: report)
        XCTAssertFalse(data.isEmpty)
        let header = String(data: data.prefix(4), encoding: .ascii)
        XCTAssertEqual(header, "%PDF")
    }

    func testTemporaryFileURLUsesStudentName() {
        let report = sampleReport()
        let url = ProgressReportPDFExporter.temporaryFileURL(for: report)
        XCTAssertTrue(url.lastPathComponent.contains("sam"))
        XCTAssertTrue(url.pathExtension == "pdf")
    }

    private func sampleReport() -> AcademicProgressReport {
        AcademicProgressReport(
            studentName: "Sam",
            gradeEquivalent: "Grades 1–2",
            curriculumBand: "Early elementary",
            reportDate: Date(),
            periodStart: Date(),
            periodEnd: Date(),
            reportingPeriodLabel: "Jan 1, 2026 – Jan 30, 2026",
            overallLetterGrade: "B",
            overallProficiency: .meets,
            overallAccuracy: 82,
            lifetimeAccuracy: 80,
            daysPracticed: 8,
            daysInPeriod: 30,
            participationRate: 27,
            totalTimeSeconds: 900,
            periodRounds: 12,
            lifetimeRounds: 40,
            dailyStreak: 3,
            totalStars: 18,
            subjects: [
                SubjectAssessment(
                    operation: .addition,
                    level: 2,
                    maxLevel: 4,
                    stars: 8,
                    standardDescription: "Adds within 20",
                    proficiency: .meets,
                    letterGrade: "B",
                    periodAccuracy: 85,
                    missedCount: 1,
                    comment: "On grade level for addition at level 2."
                )
            ],
            weeklyLog: [],
            strengths: ["Shows solid addition understanding (Meets)."],
            growthAreas: ["Practice more days each week."],
            teacherComment: "Sam is working in the Grades 1–2 math curriculum this period.",
            nextSteps: ["Try Mixed Review to keep all skills sharp."],
            hasPeriodActivity: true
        )
    }
}
