import XCTest
@testable import NumberBuddies

final class MathStoryTests: XCTestCase {
    func testAdditionStoryLabels() {
        let story = AdditionStory(
            item: StoryItem(itemPlural: "stickers", itemSingular: "sticker", iconName: "star.fill"),
            giver: "Your friend"
        )

        XCTAssertEqual(story.startLabel(count: 2), "You have 2 stickers")
        XCTAssertEqual(story.addLabel(count: 3), "Your friend gives you 3 more")
        XCTAssertEqual(story.totalLabel(count: 5), "5 stickers altogether")
    }

    func testMultiplicationStoryLabels() {
        let story = MultiplicationStory(
            item: StoryItem(itemPlural: "apples", itemSingular: "apple", iconName: "leaf.fill"),
            containerPlural: "bags",
            containerSingular: "bag"
        )

        XCTAssertTrue(story.introLabel(groups: 3, perGroup: 4).contains("3 bags"))
        XCTAssertTrue(story.introLabel(groups: 3, perGroup: 4).contains("4 apples"))
    }

    func testDivisionStoryLabels() {
        let story = DivisionStory(
            item: StoryItem(itemPlural: "cookies", itemSingular: "cookie", iconName: "fork.knife"),
            receiverPlural: "friends",
            receiverSingular: "friend"
        )

        XCTAssertEqual(story.startLabel(total: 12), "You have 12 cookies to share")
        XCTAssertEqual(story.shareLabel(friends: 3), "Share equally with 3 friends")
        XCTAssertEqual(story.eachLabel(count: 4), "Each gets 4 cookies")
    }

    func testAllOperationsIncludeStory() {
        let ops: [(MathOperation, Int, Int, Int)] = [
            (.addition, 2, 3, 5),
            (.subtraction, 5, 2, 3),
            (.multiplication, 3, 4, 12),
            (.division, 12, 3, 4)
        ]

        for (op, a, b, answer) in ops {
            let problem = MathProblem(operation: op, operandA: a, operandB: b, answer: answer)
            XCTAssertFalse(problem.spokenText.isEmpty)
            XCTAssertTrue(problem.spokenText.lowercased().contains("how many") || problem.spokenText.lowercased().contains("each"))
        }
    }
}
