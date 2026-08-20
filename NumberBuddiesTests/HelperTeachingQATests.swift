import XCTest
@testable import NumberBuddies

/// Full QA: every helper / visual must teach kids toward the graded answer.
final class HelperTeachingQATests: XCTestCase {

    // MARK: - Explore Math coverage

    func testEveryExploreTopicHasUsableHelperOrVisual() {
        for ageGroup in AgeGroup.allCases {
            let generator = TopicProblemGenerator(ageGroup: ageGroup)
            for topic in MathTopic.available(for: ageGroup) {
                var withSupport = 0
                for _ in 0..<40 {
                    let problem = generator.makeProblem(for: topic)
                    if problem.hasHelper {
                        withSupport += 1
                        XCTAssertTrue(
                            problem.helper != nil || problem.visual != nil,
                            "\(topic.title) marked hasHelper but has neither helper nor visual"
                        )
                    }
                }
                XCTAssertGreaterThan(
                    withSupport,
                    0,
                    "\(ageGroup.title) \(topic.title) never exposed a helper/visual in 40 samples"
                )
            }
        }
    }

    func testExploreHelperDerivedAnswerAlwaysMatchesGradedAnswer() {
        for ageGroup in AgeGroup.allCases {
            let generator = TopicProblemGenerator(ageGroup: ageGroup)
            for topic in MathTopic.available(for: ageGroup) {
                for _ in 0..<50 {
                    let problem = generator.makeProblem(for: topic)
                    if let taught = taughtAnswer(from: problem) {
                        XCTAssertEqual(
                            normalize(taught),
                            normalize(problem.correctDisplayAnswer),
                            """
                            Helper/visual teaches '\(taught)' but graded answer is '\(problem.correctDisplayAnswer)'
                            topic=\(topic.title) age=\(ageGroup.title) prompt=\(problem.prompt)
                            helper=\(String(describing: problem.helper)) visual=\(String(describing: problem.visual))
                            """
                        )
                    }
                }
            }
        }
    }

    func testMoneyHelperPiecesAlwaysSumToAnswer() {
        let generator = TopicProblemGenerator(ageGroup: .upper)
        for _ in 0..<80 {
            let problem = generator.makeProblem(for: .money)
            guard case .money(let pieces) = problem.visual else {
                XCTFail("Money problem missing money visual")
                continue
            }
            XCTAssertFalse(pieces.isEmpty)
            let total = pieces.reduce(0) { $0 + $1.valueCents }
            XCTAssertEqual(problem.correctDisplayAnswer, "\(total)")
            XCTAssertTrue(pieces.allSatisfy { $0.valueCents > 0 })
            // Bills must be whole dollars kids can convert to cents.
            for piece in pieces where piece.kind == .bill {
                XCTAssertEqual(piece.valueCents % 100, 0)
                XCTAssertTrue([100, 500, 1000].contains(piece.valueCents))
            }
        }
    }

    func testPercentHelpersNeverTruncate() {
        let generator = TopicProblemGenerator(ageGroup: .upper)
        var sawPercentOf = 0
        var sawShaded = 0
        for _ in 0..<80 {
            let problem = generator.makeProblem(for: .percentages)
            if case .percentOf(let percent, let whole) = problem.helper {
                sawPercentOf += 1
                XCTAssertEqual(whole * percent % 100, 0)
                XCTAssertEqual(problem.correctDisplayAnswer, "\(whole * percent / 100)")
            }
            if case .percentGrid(let percent) = problem.visual {
                sawShaded += 1
                XCTAssertEqual(problem.correctDisplayAnswer, "\(percent)%")
                XCTAssertTrue([25, 50, 75, 100].contains(percent))
            }
        }
        XCTAssertGreaterThan(sawPercentOf, 0)
        XCTAssertGreaterThan(sawShaded, 0)
    }

    func testDecimalSumHelperMatchesAnswerText() {
        let generator = TopicProblemGenerator(ageGroup: .upper)
        var saw = 0
        for _ in 0..<60 {
            let problem = generator.makeProblem(for: .decimals)
            guard case .decimalTenthsSum(let a, let b) = problem.helper else { continue }
            saw += 1
            let sum = a + b
            let expected = sum >= 10 ? "1.\(sum - 10)" : "0.\(sum)"
            XCTAssertEqual(problem.correctDisplayAnswer, expected)
            XCTAssertTrue(a >= 1 && b >= 1)
            XCTAssertLessThanOrEqual(a + b, 18)
        }
        XCTAssertGreaterThan(saw, 0)
    }

    func testWordProblemHelpersMatchStoryMath() {
        let generator = TopicProblemGenerator(ageGroup: .upper)
        for _ in 0..<60 {
            let problem = generator.makeProblem(for: .wordProblems)
            guard let helper = problem.helper else {
                XCTFail("Word problem without helper")
                continue
            }
            let taught = taughtAnswer(fromHelper: helper)
            XCTAssertEqual(taught, problem.correctDisplayAnswer)

            // Multi-step stories must keep the groups picture helper, not paper-only.
            if case .multiplicationThenSubtract = helper {
                XCTAssertFalse(
                    TopicPaperAlgorithm.needsPaperWork(for: problem),
                    "Multi-step helper should not collapse to paper-only subtraction"
                )
            }

            // Paper work (when used) must still equal the answer.
            if TopicPaperAlgorithm.needsPaperWork(for: problem),
               let work = TopicPaperAlgorithm.work(for: problem, revealAnswer: true) {
                XCTAssertEqual(work.resultLine, problem.correctDisplayAnswer)
            }
        }
    }

    func testFractionAndClockVisualsMatchChoices() {
        let generator = TopicProblemGenerator(ageGroup: .upper)
        for _ in 0..<40 {
            let fraction = generator.makeProblem(for: .fractions)
            if case .fraction(let n, let d) = fraction.visual {
                XCTAssertEqual(fraction.correctDisplayAnswer, "\(n)/\(d)")
                XCTAssertTrue(fraction.choices?.contains("\(n)/\(d)") == true)
            }

            let time = generator.makeProblem(for: .time)
            if case .clock(let hour, let minute) = time.visual {
                let numeric = "\(hour):\(String(format: "%02d", minute))"
                XCTAssertTrue(time.isCorrect(input: time.correctDisplayAnswer, selectedChoice: nil))
                XCTAssertTrue(time.isCorrect(input: numeric, selectedChoice: nil))
            }
        }
    }

    // MARK: - Core practice helpers / paper work

    func testCorePracticeVisualMathMatchesAnswer() {
        for ageGroup in AgeGroup.allCases {
            let generator = ProblemGenerator(ageGroup: ageGroup)
            for level in 1...ageGroup.maxDifficulty {
                for operation in ageGroup.availableOperations(for: level) {
                    for _ in 0..<20 {
                        let problem = generator.makeProblem(for: operation, difficulty: level)
                        XCTAssertEqual(problem.operation, operation)
                        switch problem.operation {
                        case .addition:
                            XCTAssertEqual(problem.operandA + problem.operandB, problem.answer)
                        case .subtraction:
                            XCTAssertEqual(problem.operandA - problem.operandB, problem.answer)
                        case .multiplication:
                            XCTAssertEqual(problem.operandA * problem.operandB, problem.answer)
                        case .division:
                            XCTAssertEqual(problem.operandA / problem.operandB, problem.answer)
                            if let rem = problem.remainder {
                                XCTAssertEqual(problem.operandA % problem.operandB, rem)
                            } else {
                                XCTAssertEqual(problem.operandA % problem.operandB, 0)
                            }
                        }

                        if PaperAlgorithm.needsPaperWork(for: problem),
                           let work = PaperAlgorithm.work(for: problem, revealAnswer: true) {
                            XCTAssertEqual(work.operandTop, String(problem.operandA))
                            XCTAssertEqual(work.operandBottom, String(problem.operandB))
                            XCTAssertEqual(work.resultLine, String(problem.answer))
                            if problem.operation == .division {
                                XCTAssertFalse(work.explanations.isEmpty, "Division paper work should explain sharing")
                            } else {
                                XCTAssertFalse(work.explanations.isEmpty, "Paper work should explain carries/borrows")
                            }
                        }
                    }
                }
            }
        }
    }

    func testDivisionPaperWorkExplainsSharing() {
        let generator = ProblemGenerator(ageGroup: .upper)
        var checked = 0
        for level in 1...4 {
            for _ in 0..<20 {
                let problem = generator.makeProblem(for: .division, difficulty: level)
                guard PaperAlgorithm.needsPaperWork(for: problem),
                      let work = PaperAlgorithm.work(for: problem, revealAnswer: true) else { continue }
                checked += 1
                XCTAssertEqual(work.resultLine, String(problem.answer))
                XCTAssertFalse(work.explanations.isEmpty)
                XCTAssertTrue(work.explanations.contains(where: { $0.text.contains("Share") || $0.text.contains("group") }))
            }
        }
        XCTAssertGreaterThan(checked, 0)
    }

    // MARK: - Teaching derivation (what kids can compute from the helper)

    /// Answer a careful kid would reach by following the helper/visual alone.
    private func taughtAnswer(from problem: TopicProblem) -> String? {
        if let helper = problem.helper {
            return taughtAnswer(fromHelper: helper)
        }
        guard let visual = problem.visual else { return nil }
        switch visual {
        case .fraction(let n, let d):
            return "\(n)/\(d)"
        case .decimalGrid(let tenths):
            return "0.\(tenths)"
        case .percentGrid(let percent):
            return "\(percent)%"
        case .money(let pieces):
            return "\(pieces.reduce(0) { $0 + $1.valueCents })"
        case .ruler(let a, let b, _) where problem.prompt.contains("longer"):
            return "\(a - b)"
        case .shape(let kind, let width, let height):
            if problem.prompt.contains("sides") {
                return "\(expectedSides(kind))"
            }
            if problem.prompt.contains("area") {
                return "\(width * height)"
            }
            if problem.prompt.contains("perimeter") {
                return "\(2 * (width + height))"
            }
            return nil
        case .barGraph(let items):
            if problem.prompt.contains("How many") {
                let color = problem.prompt
                    .replacingOccurrences(of: "How many ", with: "")
                    .replacingOccurrences(of: " votes?", with: "")
                return items.first { $0.label.lowercased() == color }.map { "\($0.value)" }
            }
            if case .choiceIndex = problem.answer {
                let maxValue = items.map(\.value).max() ?? 0
                return items.first { $0.value == maxValue }?.label
            }
            return nil
        case .placeValue(let number):
            if problem.prompt.contains("tens place") {
                return "\((number / 10) % 10)"
            }
            if problem.prompt.contains("Round") {
                return "\(((number + 5) / 10) * 10)"
            }
            return nil
        case .spinner(let red, let total):
            let ratio = Double(red) / Double(total)
            if red == total { return "Certain" }
            if ratio >= 0.5 { return "Likely" }
            if red > 0 { return "Unlikely" }
            return "Impossible"
        case .clock:
            // Clock visual teaches the time; graded answer may be words or numeric.
            return problem.correctDisplayAnswer
        case .ruler, .shape:
            return nil
        }
    }

    private func taughtAnswer(fromHelper helper: TopicHelper) -> String {
        switch helper {
        case .addition(let a, let b):
            return "\(a + b)"
        case .subtraction(let total, let remove):
            return "\(total - remove)"
        case .multiplicationThenSubtract(let groups, let perGroup, let remove):
            return "\(groups * perGroup - remove)"
        case .difference(let larger, let smaller):
            return "\(larger - smaller)"
        case .percentOf(let percent, let whole):
            return "\(whole * percent / 100)"
        case .decimalTenthsSum(let a, let b):
            let sum = a + b
            return sum >= 10 ? "1.\(sum - 10)" : "0.\(sum)"
        }
    }

    private func expectedSides(_ shape: GeometryShape) -> Int {
        switch shape {
        case .triangle: 3
        case .square, .rectangle: 4
        case .circle: 0
        case .hexagon: 6
        }
    }

    private func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
