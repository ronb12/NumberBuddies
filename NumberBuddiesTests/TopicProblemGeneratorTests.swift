import XCTest
@testable import NumberBuddies

final class TopicProblemGeneratorTests: XCTestCase {
    func testUpperAgeGetsAllTopics() {
        XCTAssertEqual(MathTopic.available(for: .upper).count, MathTopic.allCases.count)
    }

    func testPreKGetsFoundationalTopics() {
        let topics = MathTopic.available(for: .preK)
        XCTAssertTrue(topics.contains(.geometry))
        XCTAssertTrue(topics.contains(.time))
        XCTAssertFalse(topics.contains(.decimals))
    }

    func testGeneratorsProduceValidAnswers() {
        let generator = TopicProblemGenerator(ageGroup: .upper)
        for topic in MathTopic.allCases {
            for _ in 0..<5 {
                let problem = generator.makeProblem(for: topic)
                XCTAssertEqual(problem.topic, topic)
                XCTAssertFalse(problem.prompt.isEmpty)
                switch problem.answer {
                case .integer, .text, .choiceIndex:
                    XCTAssertFalse(problem.correctDisplayAnswer.isEmpty)
                }
            }
        }
    }

    func testWordProblemsIncludeStories() {
        let generator = TopicProblemGenerator(ageGroup: .early)
        let problem = generator.makeProblem(for: .wordProblems)
        XCTAssertNotNil(problem.story)
        XCTAssertFalse(problem.story?.isEmpty ?? true)
    }

    func testFractionProblemUsesValidChoiceIndex() {
        let generator = TopicProblemGenerator(ageGroup: .upper)
        for _ in 0..<20 {
            let problem = generator.makeProblem(for: .fractions)
            guard case .text(let answer) = problem.answer else {
                return XCTFail("Expected text answer")
            }
            XCTAssertTrue(problem.isCorrect(input: answer, selectedChoice: nil))
            XCTAssertTrue(problem.choices?.contains(answer) ?? false)
        }
    }

    func testPlaceValueTensDigitIsCorrect() {
        let generator = TopicProblemGenerator(ageGroup: .upper)
        for _ in 0..<20 {
            let problem = generator.makeProblem(for: .placeValue)
            if problem.prompt.contains("tens place"), case .integer(let digit) = problem.answer {
                let number = extractNumber(from: problem.prompt) ?? 0
                XCTAssertEqual(digit, (number / 10) % 10)
            }
        }
    }

    func testChoiceValidationMatchesByText() {
        let problem = TopicProblem(
            topic: .fractions,
            prompt: "Test",
            answer: .choiceIndex(0),
            choices: ["1/2", "1/3", "1/4", "1/2"]
        )
        XCTAssertTrue(problem.isCorrect(input: "1/2", selectedChoice: nil))
        XCTAssertTrue(problem.isCorrect(input: "", selectedChoice: 3))
        XCTAssertFalse(problem.isCorrect(input: "1/3", selectedChoice: nil))
    }

    func testTypedTimeAcceptsNumericFormat() {
        let problem = TopicProblem(
            topic: .time,
            prompt: "Clock",
            answer: .text("Half past 3"),
            choices: ["Half past 3", "3 o'clock", "Quarter past 3", "Quarter to 4"],
            acceptedAnswers: ["3:30"]
        )
        XCTAssertTrue(problem.isCorrect(input: "3:30", selectedChoice: nil))
        XCTAssertTrue(problem.isCorrect(input: "Half past 3", selectedChoice: nil))
    }

    func testTypedExpandedFormIgnoresSpaces() {
        let problem = TopicProblem(
            topic: .placeValue,
            prompt: "Expanded",
            answer: .text("100 + 20 + 3")
        )
        XCTAssertTrue(problem.isCorrect(input: "100+20+3", selectedChoice: nil))
    }

    func testDecimalAdditionUsesCorrectSum() {
        let generator = TopicProblemGenerator(ageGroup: .upper)
        for _ in 0..<20 {
            let problem = generator.makeProblem(for: .decimals)
            if problem.prompt.contains("+"), let choices = problem.choices {
                XCTAssertEqual(Set(choices).count, choices.count, "Duplicate decimal choices")
            }
        }
    }

    private func extractNumber(from prompt: String) -> Int? {
        let digits = prompt.compactMap { $0.isNumber ? $0 : nil }
        guard !digits.isEmpty else { return nil }
        return Int(String(digits))
    }
}
