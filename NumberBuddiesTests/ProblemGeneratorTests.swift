import XCTest
@testable import NumberBuddies

final class ProblemGeneratorTests: XCTestCase {
    let earlyGenerator = ProblemGenerator(ageGroup: .early)
    let preKGenerator = ProblemGenerator(ageGroup: .preK)
    let upperGenerator = ProblemGenerator(ageGroup: .upper)

    func testEarlyRoundCount() {
        let round = earlyGenerator.round(for: .addition, difficulty: 1)
        XCTAssertEqual(round.count, AgeGroup.early.questionsPerRound)
    }

    func testPreKRoundCount() {
        let round = preKGenerator.round(for: .addition, difficulty: 1)
        XCTAssertEqual(round.count, AgeGroup.preK.questionsPerRound)
    }

    func testMixedRoundIncludesMultipleOperations() {
        let round = earlyGenerator.mixedRound(operations: MathOperation.allCases, difficulty: 2)
        let operations = Set(round.map(\.operation))
        XCTAssertEqual(round.count, AgeGroup.early.questionsPerRound)
        XCTAssertGreaterThan(operations.count, 1)
    }

    func testAdditionAnswersAreCorrect() {
        for _ in 0..<20 {
            let problem = earlyGenerator.makeProblem(for: .addition, difficulty: 2)
            XCTAssertEqual(problem.operandA + problem.operandB, problem.answer)
        }
    }

    func testSubtractionAnswersAreNonNegative() {
        for _ in 0..<20 {
            let problem = earlyGenerator.makeProblem(for: .subtraction, difficulty: 2)
            XCTAssertEqual(problem.operandA - problem.operandB, problem.answer)
            XCTAssertGreaterThanOrEqual(problem.answer, 0)
        }
    }

    func testMultiplicationAnswersAreCorrect() {
        for _ in 0..<20 {
            let problem = earlyGenerator.makeProblem(for: .multiplication, difficulty: 3)
            XCTAssertEqual(problem.operandA * problem.operandB, problem.answer)
        }
    }

    func testDivisionHasNoRemainder() {
        for _ in 0..<20 {
            let problem = earlyGenerator.makeProblem(for: .division, difficulty: 3)
            if problem.hasRemainder {
                XCTAssertEqual(problem.operandA % problem.operandB, problem.remainder)
            } else {
                XCTAssertEqual(problem.operandA / problem.operandB, problem.answer)
                XCTAssertEqual(problem.operandA % problem.operandB, 0)
            }
        }
    }

    func testPreKUsesSmallerNumbers() {
        let easy = preKGenerator.makeProblem(for: .addition, difficulty: 1)
        XCTAssertLessThanOrEqual(easy.answer, 5)

        let mult = preKGenerator.makeProblem(for: .multiplication, difficulty: 1)
        XCTAssertLessThanOrEqual(mult.operandA, 3)
        XCTAssertLessThanOrEqual(mult.operandB, 3)
    }

    func testUpperUsesLargerNumbersAtHighDifficulty() {
        for _ in 0..<20 {
            let problem = upperGenerator.makeProblem(for: .addition, difficulty: 4)
            XCTAssertLessThanOrEqual(problem.answer, 1000)
        }
    }
}
