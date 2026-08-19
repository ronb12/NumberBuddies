import XCTest
@testable import NumberBuddies

final class TimesTableChallengeTests: XCTestCase {
    func testSingleTableRunsInOrder() {
        let problems = TimesTableGenerator.problems(for: .table(4))
        XCTAssertEqual(problems.count, 12)
        XCTAssertEqual(problems.map(\.operandB), Array(1...12))
        XCTAssertTrue(problems.allSatisfy { $0.operandA == 4 })
        for (index, problem) in problems.enumerated() {
            XCTAssertEqual(problem.answer, 4 * (index + 1))
        }
    }

    func testMarathonCoversAllTablesInOrder() {
        let problems = TimesTableGenerator.problems(for: .marathon)
        XCTAssertEqual(problems.count, 144)

        var index = 0
        for table in 1...12 {
            for multiplier in 1...12 {
                let problem = problems[index]
                XCTAssertEqual(problem.operandA, table)
                XCTAssertEqual(problem.operandB, multiplier)
                XCTAssertEqual(problem.answer, table * multiplier)
                index += 1
            }
        }
    }

    func testChallengeTitles() {
        XCTAssertEqual(TimesTableChallengeKind.table(7).title, "7s Table")
        XCTAssertEqual(TimesTableChallengeKind.marathon.title, "Tables 1–12 Marathon")
    }
}
