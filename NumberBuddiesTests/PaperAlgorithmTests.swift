import XCTest
@testable import NumberBuddies

final class PaperAlgorithmTests: XCTestCase {
    func testDetectsLargeNumbers() {
        let small = MathProblem(operation: .addition, operandA: 3, operandB: 4, answer: 7)
        let large = MathProblem(operation: .addition, operandA: 47, operandB: 38, answer: 85)
        XCTAssertFalse(PaperAlgorithm.needsPaperWork(for: small))
        XCTAssertTrue(PaperAlgorithm.needsPaperWork(for: large))
    }

    func testAdditionShowsCarryMarks() {
        let problem = MathProblem(operation: .addition, operandA: 47, operandB: 38, answer: 85)
        let work = PaperAlgorithm.work(for: problem, revealAnswer: false)
        XCTAssertNotNil(work)
        XCTAssertTrue(work?.marks.contains(where: { $0.kind == .carry }) ?? false)
        XCTAssertTrue(work?.explanations.contains(where: { $0.kind == .carry }) ?? false)
    }

    func testAdditionExplainsCarryInOnesPlace() {
        let problem = MathProblem(operation: .addition, operandA: 47, operandB: 38, answer: 85)
        let work = PaperAlgorithm.work(for: problem, revealAnswer: false)
        let onesExplanation = work?.explanations.first { $0.columnFromRight == 0 }
        XCTAssertNotNil(onesExplanation)
        XCTAssertTrue(onesExplanation?.text.contains("carry 1") ?? false)
        XCTAssertTrue(onesExplanation?.text.contains("ones") ?? false)
    }

    func testAdditionRevealAnswer() {
        let problem = MathProblem(operation: .addition, operandA: 47, operandB: 38, answer: 85)
        let work = PaperAlgorithm.work(for: problem, revealAnswer: true)
        XCTAssertEqual(work?.resultLine, "85")
    }

    func testSubtractionShowsBorrowMarks() {
        let problem = MathProblem(operation: .subtraction, operandA: 52, operandB: 27, answer: 25)
        let work = PaperAlgorithm.work(for: problem, revealAnswer: true)
        XCTAssertEqual(work?.resultLine, "25")
        XCTAssertTrue(work?.marks.contains(where: { $0.kind == .borrow }) ?? false)
        XCTAssertTrue(work?.explanations.contains(where: { $0.kind == .borrow }) ?? false)
    }

    func testSubtractionExplainsBorrow() {
        let problem = MathProblem(operation: .subtraction, operandA: 52, operandB: 27, answer: 25)
        let work = PaperAlgorithm.work(for: problem, revealAnswer: true)
        let borrowStep = work?.explanations.first { $0.kind == .borrow }
        XCTAssertTrue(borrowStep?.text.contains("Borrow 1") ?? false)
    }

    func testMultiplicationShowsCarryMarks() {
        let problem = MathProblem(operation: .multiplication, operandA: 23, operandB: 4, answer: 92)
        let work = PaperAlgorithm.work(for: problem, revealAnswer: true)
        XCTAssertEqual(work?.resultLine, "92")
        XCTAssertTrue(work?.marks.contains(where: { $0.kind == .carry }) ?? false)
    }
}
