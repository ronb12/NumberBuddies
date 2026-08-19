import XCTest
@testable import NumberBuddies

final class ProblemGeneratorTests: XCTestCase {
    let generator = ProblemGenerator()

    func testRoundCount() {
        let round = generator.round(for: .addition, difficulty: 1)
        XCTAssertEqual(round.count, ProblemGenerator.questionsPerRound)
    }

    func testAdditionAnswersAreCorrect() {
        for _ in 0..<20 {
            let problem = generator.makeProblem(for: .addition, difficulty: 2)
            XCTAssertEqual(problem.operandA + problem.operandB, problem.answer)
        }
    }

    func testSubtractionAnswersAreNonNegative() {
        for _ in 0..<20 {
            let problem = generator.makeProblem(for: .subtraction, difficulty: 2)
            XCTAssertEqual(problem.operandA - problem.operandB, problem.answer)
            XCTAssertGreaterThanOrEqual(problem.answer, 0)
        }
    }

    func testMultiplicationAnswersAreCorrect() {
        for _ in 0..<20 {
            let problem = generator.makeProblem(for: .multiplication, difficulty: 1)
            XCTAssertEqual(problem.operandA * problem.operandB, problem.answer)
        }
    }

    func testDivisionHasNoRemainder() {
        for _ in 0..<20 {
            let problem = generator.makeProblem(for: .division, difficulty: 2)
            XCTAssertEqual(problem.operandA / problem.operandB, problem.answer)
            XCTAssertEqual(problem.operandA % problem.operandB, 0)
        }
    }

    func testDifficultyOneUsesSmallerNumbers() {
        let easy = generator.makeProblem(for: .addition, difficulty: 1)
        XCTAssertLessThanOrEqual(easy.answer, 10)

        let mult = generator.makeProblem(for: .multiplication, difficulty: 1)
        XCTAssertLessThanOrEqual(mult.operandA, 5)
        XCTAssertLessThanOrEqual(mult.operandB, 5)
    }
}
