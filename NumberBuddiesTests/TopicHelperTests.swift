import XCTest
@testable import NumberBuddies

final class TopicHelperTests: XCTestCase {
    func testExploreTopicsExposeHelpers() {
        let generator = TopicProblemGenerator(ageGroup: .upper)
        for topic in MathTopic.allCases {
            var sawHelper = false
            for _ in 0..<12 {
                let problem = generator.makeProblem(for: topic)
                if problem.hasHelper {
                    sawHelper = true
                    break
                }
            }
            XCTAssertTrue(sawHelper, "Expected helper support for \(topic.title)")
        }
    }

    func testWordProblemsIncludeStepHelper() {
        let generator = TopicProblemGenerator(ageGroup: .upper)
        for _ in 0..<10 {
            let problem = generator.makeProblem(for: .wordProblems)
            XCTAssertNotNil(problem.helper)
        }
    }

    func testLargeWordProblemCanUsePaperWork() {
        let problem = TopicProblem(
            topic: .wordProblems,
            prompt: "How many in all?",
            story: "Story",
            answer: .integer(42),
            helper: .addition(a: 27, b: 15)
        )
        XCTAssertTrue(TopicPaperAlgorithm.needsPaperWork(for: problem))
        XCTAssertNotNil(TopicPaperAlgorithm.work(for: problem, revealAnswer: false))
    }

    func testMultiStepHelperKeepsPictureHelperNotPaperOnly() {
        let problem = TopicProblem(
            topic: .wordProblems,
            prompt: "How many left?",
            story: "3 boxes of 5, give away 2",
            answer: .integer(13),
            helper: .multiplicationThenSubtract(groups: 3, perGroup: 5, remove: 2)
        )
        XCTAssertFalse(
            TopicPaperAlgorithm.needsPaperWork(for: problem),
            "Multi-step stories should keep the groups + take-away helper"
        )
    }

    func testPercentOfProblemsAreExactIntegers() {
        let generator = TopicProblemGenerator(ageGroup: .upper)
        var sawPercentOf = false
        for _ in 0..<40 {
            let problem = generator.makeProblem(for: .percentages)
            guard case .percentOf(let percent, let whole) = problem.helper else { continue }
            sawPercentOf = true
            XCTAssertEqual(whole * percent % 100, 0)
            if case .integer(let answer) = problem.answer {
                XCTAssertEqual(answer, whole * percent / 100)
            }
        }
        XCTAssertTrue(sawPercentOf)
    }
}
