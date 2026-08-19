import XCTest
@testable import NumberBuddies

final class VisualHelperTests: XCTestCase {
    let generator = ProblemGenerator(ageGroup: .early)

    func testAdditionVisualPartsSumToAnswer() {
        for _ in 0..<30 {
            let problem = generator.makeProblem(for: .addition, difficulty: 2)
            XCTAssertEqual(problem.operandA + problem.operandB, problem.answer)
        }
    }

    func testSubtractionVisualPartsMatchAnswer() {
        for _ in 0..<30 {
            let problem = generator.makeProblem(for: .subtraction, difficulty: 2)
            XCTAssertEqual(problem.operandA - problem.operandB, problem.answer)
            XCTAssertGreaterThan(problem.operandB, 0)
        }
    }

    func testMultiplicationArrayDimensionsMatchAnswer() {
        for _ in 0..<30 {
            let problem = generator.makeProblem(for: .multiplication, difficulty: 3)
            XCTAssertEqual(problem.operandA * problem.operandB, problem.answer)
        }
    }

    func testDivisionSharingGroupsMatchDividend() {
        for _ in 0..<30 {
            let problem = generator.makeProblem(for: .division, difficulty: 3)
            XCTAssertEqual(problem.operandA / problem.operandB, problem.answer)
            if problem.hasRemainder {
                XCTAssertEqual(problem.operandA % problem.operandB, problem.remainder)
            } else {
                XCTAssertEqual(problem.operandB * problem.answer, problem.operandA)
            }
        }
    }
}
