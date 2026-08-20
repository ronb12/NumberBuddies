import XCTest
@testable import NumberBuddies

final class MathChallengeTests: XCTestCase {
    func testMultiplicationTableRunsInOrder() {
        let problems = MathChallengeGenerator.problems(for: .orderedTable(.multiplication, 4))
        XCTAssertEqual(problems.count, 12)
        XCTAssertEqual(problems.map(\.operandB), Array(1...12))
        XCTAssertTrue(problems.allSatisfy { $0.operandA == 4 })
    }

    func testAdditionTableRunsInOrder() {
        let problems = MathChallengeGenerator.problems(for: .orderedTable(.addition, 5))
        XCTAssertEqual(problems.count, 12)
        XCTAssertEqual(problems.map(\.operandA), Array(repeating: 5, count: 12))
        XCTAssertEqual(problems.map(\.operandB), Array(1...12))
        XCTAssertEqual(problems.map(\.answer), (1...12).map { 5 + $0 })
    }

    func testSubtractionTableRunsInOrder() {
        let problems = MathChallengeGenerator.problems(for: .orderedTable(.subtraction, 3))
        XCTAssertEqual(problems.count, 12)
        XCTAssertTrue(problems.allSatisfy { $0.operandA == 14 })
        XCTAssertEqual(problems.map(\.operandB), Array(1...12))
        XCTAssertEqual(problems.first?.answer, 13)
    }

    func testDivisionTableRunsInOrder() {
        let problems = MathChallengeGenerator.problems(for: .orderedTable(.division, 4))
        XCTAssertEqual(problems.count, 12)
        XCTAssertTrue(problems.allSatisfy { $0.operandB == 4 })
        XCTAssertEqual(problems.map(\.answer), Array(1...12))
    }

    func testAdditionDoublesAndMakeTen() {
        let doubles = MathChallengeGenerator.problems(for: .doubles)
        XCTAssertEqual(doubles.count, 12)
        XCTAssertTrue(doubles.allSatisfy { $0.operandA == $0.operandB })

        let makeTen = MathChallengeGenerator.problems(for: .makeTen)
        XCTAssertEqual(makeTen.count, 9)
        XCTAssertTrue(makeTen.allSatisfy { $0.operandA + $0.operandB == 10 })
    }

    func testMarathonCoversAllMultiplicationTables() {
        let problems = MathChallengeGenerator.problems(for: .marathon(.multiplication))
        XCTAssertEqual(problems.count, 144)
    }

    func testLegacyTimesTableAliasesStillWork() {
        XCTAssertEqual(MathChallengeKind.orderedTable(.multiplication, 7).title, "7s Table")
        let problems = TimesTableGenerator.problems(for: .table(4))
        XCTAssertEqual(problems.count, 12)
    }
}
