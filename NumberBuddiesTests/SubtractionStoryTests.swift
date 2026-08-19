import XCTest
@testable import NumberBuddies

final class SubtractionStoryTests: XCTestCase {
    func testCandyStoryLabels() {
        let story = SubtractionStory(
            itemPlural: "pieces of candy",
            itemSingular: "piece of candy",
            action: "ate",
            iconName: "gift.fill"
        )

        XCTAssertEqual(story.startLabel(count: 3), "You have 3 pieces of candy")
        XCTAssertEqual(story.actionLabel(count: 2), "You ate 2")
        XCTAssertEqual(story.leftLabel(count: 1), "1 piece of candy left")
    }

    func testStorySpokenQuestion() {
        let story = SubtractionStory.pick(for: 3, operandB: 2)
        let spoken = story.spokenQuestionShort(start: 3, remove: 2)
        XCTAssertTrue(spoken.contains("three"))
        XCTAssertTrue(spoken.contains("two"))
        XCTAssertTrue(spoken.lowercased().contains("left"))
    }

    func testSubtractionProblemsIncludeStory() {
        let problem = MathProblem(
            operation: .subtraction,
            operandA: 3,
            operandB: 2,
            answer: 1
        )
        XCTAssertNotNil(problem.subtractionStory)
        XCTAssertTrue(problem.spokenText.lowercased().contains("left"))
    }
}