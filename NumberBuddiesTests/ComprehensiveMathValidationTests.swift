import XCTest
@testable import NumberBuddies

/// Exhaustive math checks across practice, challenges, and Explore Math.
final class ComprehensiveMathValidationTests: XCTestCase {

    // MARK: - Core practice

    func testAllAgeGroupsAndOperationsProduceValidMath() {
        for ageGroup in [AgeGroup.preK, .early, .upper] {
            let generator = ProblemGenerator(ageGroup: ageGroup)
            for operation in MathOperation.allCases {
                for level in 1...ageGroup.maxDifficulty {
                    for _ in 0..<25 {
                        let problem = generator.makeProblem(for: operation, difficulty: level)
                        assertMathProblemValid(problem, ageGroup: ageGroup, level: level)
                    }
                }
            }
        }
    }

    func testPracticeRoundsHaveExpectedCounts() {
        for ageGroup in [AgeGroup.preK, .early, .upper] {
            let generator = ProblemGenerator(ageGroup: ageGroup)
            for operation in ageGroup.homeOperations {
                let round = generator.round(for: operation, difficulty: ageGroup.defaultDifficulty)
                XCTAssertEqual(round.count, ageGroup.questionsPerRound, "\(ageGroup) \(operation)")
                round.forEach { assertMathProblemValid($0, ageGroup: ageGroup, level: ageGroup.defaultDifficulty) }
            }
        }
    }

    func testMixedReviewOnlyUsesAllowedOperations() {
        for ageGroup in [AgeGroup.early, .upper] {
            let generator = ProblemGenerator(ageGroup: ageGroup)
            for level in 1...ageGroup.maxDifficulty {
                let allowed = Set(ageGroup.availableOperations(for: level))
                let round = generator.mixedRound(operations: MathOperation.allCases, difficulty: level)
                XCTAssertEqual(round.count, ageGroup.questionsPerRound)
                for problem in round {
                    XCTAssertTrue(allowed.contains(problem.operation), "Unexpected \(problem.operation) at level \(level)")
                    assertMathProblemValid(problem, ageGroup: ageGroup, level: level)
                }
            }
        }
    }

    // MARK: - Math challenges

    func testAllChallengeKindsHaveCorrectMath() {
        for operation in MathOperation.allCases {
            for table in 1...12 {
                let problems = MathChallengeGenerator.problems(for: .orderedTable(operation, table))
                XCTAssertEqual(problems.count, 12)
                for (index, problem) in problems.enumerated() {
                    assertMathProblemValid(problem, ageGroup: .upper, level: 4)
                    switch operation {
                    case .addition:
                        XCTAssertEqual(problem.operandA, table)
                        XCTAssertEqual(problem.operandB, index + 1)
                    case .subtraction:
                        XCTAssertEqual(problem.operandA, table + 11)
                        XCTAssertEqual(problem.operandB, index + 1)
                    case .multiplication:
                        XCTAssertEqual(problem.operandA, table)
                        XCTAssertEqual(problem.operandB, index + 1)
                    case .division:
                        XCTAssertEqual(problem.operandB, table)
                        XCTAssertEqual(problem.answer, index + 1)
                        XCTAssertEqual(problem.operandA, table * (index + 1))
                    }
                }
            }

            let marathon = MathChallengeGenerator.problems(for: .marathon(operation))
            XCTAssertEqual(marathon.count, 144)
            marathon.forEach { assertMathProblemValid($0, ageGroup: .upper, level: 4) }
        }

        let doubles = MathChallengeGenerator.problems(for: .doubles)
        XCTAssertTrue(doubles.allSatisfy { $0.operandA + $0.operandB == $0.answer && $0.operandA == $0.operandB })

        let makeTen = MathChallengeGenerator.problems(for: .makeTen)
        XCTAssertTrue(makeTen.allSatisfy { $0.operandA + $0.operandB == 10 })
    }

    // MARK: - Explore Math

    func testAllTopicProblemsMatchVisualAndHelperMath() {
        for ageGroup in [AgeGroup.preK, .early, .upper] {
            let generator = TopicProblemGenerator(ageGroup: ageGroup)
            for topic in MathTopic.available(for: ageGroup) {
                for _ in 0..<30 {
                    let problem = generator.makeProblem(for: topic)
                    assertTopicProblemValid(problem)
                    assertTopicAnswerGradedCorrectly(problem)
                }
                let round = generator.round(for: topic)
                XCTAssertEqual(round.count, topic.questionsPerRound, "\(topic.title) round count")
                round.forEach {
                    assertTopicProblemValid($0)
                    assertTopicAnswerGradedCorrectly($0)
                }
            }
        }
    }

    func testTopicChoiceListsIncludeCorrectAnswer() {
        for topic in MathTopic.allCases {
            let generator = TopicProblemGenerator(ageGroup: .upper)
            for _ in 0..<20 {
                let problem = generator.makeProblem(for: topic)
                guard let choices = problem.choices else { continue }
                let correct = problem.correctDisplayAnswer
                if problem.expectsTextInput {
                    XCTAssertTrue(
                        choices.contains(where: { normalize($0) == normalize(correct) }),
                        "Missing correct choice \(correct) in \(choices) for \(topic)"
                    )
                }
                if case .choiceIndex(let index) = problem.answer {
                    XCTAssertEqual(choices[index], correct)
                }
            }
        }
    }

    // MARK: - Paper work

    func testPaperWorkMatchesOperands() {
        for _ in 0..<20 {
            let problem = ProblemGenerator(ageGroup: .upper).makeProblem(for: .addition, difficulty: 4)
            guard PaperAlgorithm.needsPaperWork(for: problem),
                  let work = PaperAlgorithm.work(for: problem, revealAnswer: true) else { continue }
            XCTAssertEqual(work.operandTop, String(problem.operandA))
            XCTAssertEqual(work.operandBottom, String(problem.operandB))
            XCTAssertEqual(work.resultLine, String(problem.answer))
        }
    }

    // MARK: - Helpers

    private func assertMathProblemValid(_ problem: MathProblem, ageGroup: AgeGroup, level: Int) {
        switch problem.operation {
        case .addition:
            XCTAssertEqual(problem.operandA + problem.operandB, problem.answer)
        case .subtraction:
            XCTAssertEqual(problem.operandA - problem.operandB, problem.answer)
            XCTAssertGreaterThanOrEqual(problem.answer, 0)
            XCTAssertGreaterThanOrEqual(problem.operandA, problem.operandB)
        case .multiplication:
            XCTAssertEqual(problem.operandA * problem.operandB, problem.answer)
        case .division:
            if let remainder = problem.remainder, remainder > 0 {
                XCTAssertEqual(problem.operandA % problem.operandB, remainder)
                XCTAssertEqual(problem.operandA / problem.operandB, problem.answer)
            } else {
                XCTAssertEqual(problem.operandA / problem.operandB, problem.answer)
                XCTAssertEqual(problem.operandA % problem.operandB, 0)
            }
        }

        let caps = ageGroup.caps(for: level)
        switch problem.operation {
        case .addition:
            XCTAssertLessThanOrEqual(problem.answer, caps.maxSum)
        case .subtraction, .multiplication:
            XCTAssertLessThanOrEqual(max(problem.operandA, problem.operandB), caps.maxValue)
        case .division:
            XCTAssertLessThanOrEqual(problem.operandB, caps.maxFactor)
        }
    }

    private func assertTopicProblemValid(_ problem: TopicProblem) {
        XCTAssertFalse(problem.prompt.isEmpty)
        XCTAssertFalse(problem.correctDisplayAnswer.isEmpty)

        if let visual = problem.visual {
            switch visual {
            case .fraction(let numerator, let denominator):
                if case .text(let answer) = problem.answer {
                    XCTAssertEqual(answer, "\(numerator)/\(denominator)")
                }
            case .decimalGrid(let tenths):
                if case .text(let answer) = problem.answer {
                    XCTAssertEqual(answer, "0.\(tenths)")
                }
            case .percentGrid(let percent):
                if case .text(let answer) = problem.answer {
                    XCTAssertEqual(answer, "\(percent)%")
                }
            case .clock(let hour, let minute):
                if case .text(let answer) = problem.answer {
                    XCTAssertTrue(problem.isCorrect(input: answer, selectedChoice: nil))
                    let numeric = "\(hour):\(String(format: "%02d", minute))"
                    XCTAssertTrue(problem.isCorrect(input: numeric, selectedChoice: nil))
                }
            case .money(let pieces):
                if case .integer(let answer) = problem.answer {
                    let total = pieces.reduce(0) { $0 + $1.valueCents }
                    XCTAssertEqual(answer, total)
                    XCTAssertFalse(pieces.isEmpty)
                }
            case .ruler(let lengthA, let lengthB, _):
                if problem.prompt.contains("longer"), case .integer(let answer) = problem.answer {
                    XCTAssertEqual(answer, lengthA - lengthB)
                }
            case .shape(let kind, let width, let height):
                if problem.prompt.contains("sides"), case .integer(let answer) = problem.answer {
                    XCTAssertEqual(answer, expectedSides(for: kind))
                } else if problem.prompt.contains("area"), case .integer(let answer) = problem.answer {
                    XCTAssertEqual(answer, width * height)
                } else if problem.prompt.contains("perimeter"), case .integer(let answer) = problem.answer {
                    XCTAssertEqual(answer, 2 * (width + height))
                }
            case .barGraph(let items):
                if problem.prompt.contains("How many"), case .integer(let answer) = problem.answer {
                    let color = problem.prompt
                        .replacingOccurrences(of: "How many ", with: "")
                        .replacingOccurrences(of: " votes?", with: "")
                    let match = items.first { $0.label.lowercased() == color }
                    XCTAssertEqual(answer, match?.value)
                } else if case .choiceIndex(let index) = problem.answer, let choices = problem.choices {
                    let values = items.map(\.value)
                    let maxValue = values.max() ?? 0
                    XCTAssertEqual(values.filter { $0 == maxValue }.count, 1, "Graph tie for max")
                    XCTAssertEqual(choices[index], items[index].label)
                    XCTAssertEqual(items[index].value, maxValue)
                }
            case .placeValue(let number):
                if problem.prompt.contains("tens place"), case .integer(let answer) = problem.answer {
                    XCTAssertEqual(answer, (number / 10) % 10)
                } else if problem.prompt.contains("Round"), case .integer(let answer) = problem.answer {
                    XCTAssertEqual(answer, ((number + 5) / 10) * 10)
                }
            case .spinner(let redSections, let totalSections):
                if case .choiceIndex(let index) = problem.answer, let choices = problem.choices {
                    let ratio = Double(redSections) / Double(totalSections)
                    let expected: Int
                    if redSections == totalSections { expected = 0 }
                    else if ratio >= 0.5 { expected = 1 }
                    else if redSections > 0 { expected = 2 }
                    else { expected = 3 }
                    XCTAssertEqual(index, expected)
                    XCTAssertEqual(choices[index], ["Certain", "Likely", "Unlikely", "Impossible"][expected])
                }
            }
        }

        if let helper = problem.helper {
            switch helper {
            case .addition(let a, let b):
                if case .integer(let answer) = problem.answer { XCTAssertEqual(answer, a + b) }
            case .subtraction(let total, let remove):
                if case .integer(let answer) = problem.answer { XCTAssertEqual(answer, total - remove) }
            case .multiplicationThenSubtract(let groups, let perGroup, let remove):
                if case .integer(let answer) = problem.answer {
                    XCTAssertEqual(answer, groups * perGroup - remove)
                }
            case .difference(let larger, let smaller):
                if case .integer(let answer) = problem.answer { XCTAssertEqual(answer, larger - smaller) }
            case .percentOf(let percent, let whole):
                if case .integer(let answer) = problem.answer {
                    XCTAssertEqual(
                        whole * percent % 100,
                        0,
                        "Percent of whole must be exact: \(percent)% of \(whole)"
                    )
                    XCTAssertEqual(answer, whole * percent / 100)
                }
            case .decimalTenthsSum(let a, let b):
                if case .text(let answer) = problem.answer {
                    let sum = a + b
                    let expected = sum >= 10 ? "1.\(sum - 10)" : "0.\(sum)"
                    XCTAssertEqual(answer, expected)
                }
            }
        }

        if problem.prompt.contains("0."), problem.prompt.contains("+"), case .text(let answer) = problem.answer {
            let parts = problem.prompt
                .replacingOccurrences(of: "0.", with: "")
                .replacingOccurrences(of: " = ?", with: "")
                .split(separator: "+")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            if parts.count == 2 {
                let sum = parts[0] + parts[1]
                let expected = sum >= 10 ? "1.\(sum - 10)" : "0.\(sum)"
                XCTAssertEqual(answer, expected)
            }
        }

        if problem.prompt.contains("% of "), case .integer(let answer) = problem.answer {
            let tokens = problem.prompt.split(separator: " ")
            if tokens.count >= 4, let percent = Int(tokens[0].replacingOccurrences(of: "%", with: "")),
               let whole = Int(tokens[2]) {
                XCTAssertEqual(answer, whole * percent / 100)
            }
        }
    }

    private func assertTopicAnswerGradedCorrectly(_ problem: TopicProblem) {
        let correct = problem.correctDisplayAnswer
        switch problem.answer {
        case .integer:
            XCTAssertTrue(problem.isCorrect(input: correct, selectedChoice: nil))
            XCTAssertFalse(problem.isCorrect(input: "99999", selectedChoice: nil))
        case .text:
            XCTAssertTrue(problem.isCorrect(input: correct, selectedChoice: nil))
            if let choices = problem.choices, let index = choices.firstIndex(of: correct) {
                XCTAssertTrue(problem.isCorrect(input: "", selectedChoice: index))
            }
        case .choiceIndex(let index):
            XCTAssertTrue(problem.isCorrect(input: "", selectedChoice: index))
            if let choices = problem.choices {
                XCTAssertTrue(problem.isCorrect(input: choices[index], selectedChoice: nil))
            }
        }
    }

    private func expectedSides(for shape: GeometryShape) -> Int {
        switch shape {
        case .triangle: 3
        case .square, .rectangle: 4
        case .circle: 0
        case .hexagon: 6
        }
    }

    private func normalize(_ text: String) -> String {
        text.lowercased().replacingOccurrences(of: " ", with: "")
    }
}
