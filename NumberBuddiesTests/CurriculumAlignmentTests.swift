import XCTest
@testable import NumberBuddies

final class CurriculumAlignmentTests: XCTestCase {
    func testPreKStaysWithinTen() {
        let generator = ProblemGenerator(ageGroup: .preK)
        for level in 1...AgeGroup.preK.maxDifficulty {
            for _ in 0..<10 {
                let add = generator.makeProblem(for: .addition, difficulty: level)
                XCTAssertLessThanOrEqual(add.answer, 10)
                let sub = generator.makeProblem(for: .subtraction, difficulty: level)
                XCTAssertLessThanOrEqual(sub.operandA, 10)
            }
        }
    }

    func testEarlyUnlocksMultiplyAfterGradeOneSkills() {
        XCTAssertEqual(AgeGroup.early.initialOperations, [.addition, .subtraction])
        XCTAssertEqual(AgeGroup.early.availableOperations(for: 1), [.addition, .subtraction])
        XCTAssertEqual(AgeGroup.early.availableOperations(for: 2), [.addition, .subtraction])
        XCTAssertEqual(AgeGroup.early.availableOperations(for: 3).count, 4)
    }

    func testEarlyLevelTwoUsesTwenty() {
        let generator = ProblemGenerator(ageGroup: .early)
        for _ in 0..<20 {
            let problem = generator.makeProblem(for: .addition, difficulty: 2)
            XCTAssertLessThanOrEqual(problem.answer, 20)
        }
    }

    func testUpperAllowsRemaindersAtHigherLevels() {
        let generator = ProblemGenerator(ageGroup: .upper)
        var sawRemainder = false
        for _ in 0..<40 {
            let problem = generator.makeProblem(for: .division, difficulty: 4)
            if problem.hasRemainder {
                sawRemainder = true
                XCTAssertGreaterThan(problem.remainder ?? 0, 0)
                XCTAssertLessThan(problem.remainder ?? 0, problem.operandB)
                XCTAssertEqual(problem.operandA, problem.operandB * problem.answer + (problem.remainder ?? 0))
            }
        }
        XCTAssertTrue(sawRemainder)
    }

    func testUpperLevelFourUsesTwoDigitMultiplication() {
        let generator = ProblemGenerator(ageGroup: .upper)
        var sawTwoDigit = false
        for _ in 0..<30 {
            let problem = generator.makeProblem(for: .multiplication, difficulty: 4)
            if problem.operandA >= 10 || problem.operandB >= 10 {
                sawTwoDigit = true
            }
        }
        XCTAssertTrue(sawTwoDigit)
    }

    func testEarlyRegroupingAppearsAtGradeTwoLevel() {
        let generator = ProblemGenerator(ageGroup: .early)
        var sawRegroup = false
        for _ in 0..<30 {
            let problem = generator.makeProblem(for: .addition, difficulty: 3)
            if problem.operandA >= 10, problem.operandB >= 10,
               (problem.operandA % 10) + (problem.operandB % 10) >= 10 {
                sawRegroup = true
            }
        }
        XCTAssertTrue(sawRegroup)
    }
}
