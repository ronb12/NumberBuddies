import Foundation

struct TopicProblemGenerator: Sendable {
    let ageGroup: AgeGroup

    func round(for topic: MathTopic) -> [TopicProblem] {
        let count = topic.questionsPerRound
        var problems: [TopicProblem] = []
        var seen = Set<String>()
        var attempts = 0

        while problems.count < count, attempts < count * 40 {
            attempts += 1
            let problem = makeProblem(for: topic)
            let key = problemKey(problem)
            if seen.insert(key).inserted {
                problems.append(problem)
            }
        }

        if problems.count < count {
            while problems.count < count {
                problems.append(makeProblem(for: topic))
            }
        }
        return problems
    }

    func makeProblem(for topic: MathTopic) -> TopicProblem {
        switch topic {
        case .fractions: return makeFractionProblem()
        case .decimals: return makeDecimalProblem()
        case .percentages: return makePercentProblem()
        case .time: return makeTimeProblem()
        case .money: return makeMoneyProblem()
        case .measurement: return makeMeasurementProblem()
        case .geometry: return makeGeometryProblem()
        case .placeValue: return makePlaceValueProblem()
        case .graphsAndData: return makeGraphProblem()
        case .probability: return makeProbabilityProblem()
        case .wordProblems: return makeWordProblem()
        }
    }

    private func problemKey(_ problem: TopicProblem) -> String {
        "\(problem.topic.rawValue)-\(problem.prompt)-\(problem.correctDisplayAnswer)"
    }

    // MARK: - Fractions

    private func makeFractionProblem() -> TopicProblem {
        let denominator = [2, 3, 4, 6, 8].randomElement() ?? 4
        let numerator = Int.random(in: 1..<denominator)
        let correct = "\(numerator)/\(denominator)"
        var distractors = [
            "\(max(1, numerator - 1))/\(denominator)",
            "\(min(denominator - 1, numerator + 1))/\(denominator)",
            "1/\(denominator)",
            "\(numerator)/\(denominator + 1)"
        ].filter { $0 != correct }
        let options = uniqueChoices(correct: correct, distractors: distractors, count: 4)
        return TopicProblem(
            topic: .fractions,
            prompt: "What fraction is shaded?",
            answer: .text(correct),
            choices: options,
            visual: .fraction(numerator: numerator, denominator: denominator)
        )
    }

    // MARK: - Decimals

    private func makeDecimalProblem() -> TopicProblem {
        if Bool.random() {
            let tenths = Int.random(in: 1...9)
            let correct = "0.\(tenths)"
            let options = uniqueChoices(
                correct: correct,
                distractors: ["0.\(max(1, tenths - 1))", "0.\(min(9, tenths + 1))", "\(tenths).0"],
                count: 4
            )
            return TopicProblem(
                topic: .decimals,
                prompt: "What decimal is shown?",
                answer: .text(correct),
                choices: options,
                visual: .decimalGrid(tenths: tenths)
            )
        }
        let a = Int.random(in: 1...4)
        let b = Int.random(in: 1...max(1, 9 - a))
        let sumTenths = a + b
        let correct = sumTenths >= 10 ? "1.\(sumTenths - 10)" : "0.\(sumTenths)"
        var distractors = [
            sumTenths >= 10 ? "0.\(sumTenths)" : "0.\(sumTenths + 1)",
            sumTenths >= 10 ? "1.\(sumTenths - 9)" : "0.\(max(1, sumTenths - 1))",
            "\(sumTenths).0"
        ].filter { $0 != correct }
        let options = uniqueChoices(correct: correct, distractors: distractors, count: 4)
        return TopicProblem(
            topic: .decimals,
            prompt: "0.\(a) + 0.\(b) = ?",
            spokenText: "What is zero point \(a) plus zero point \(b)?",
            answer: .text(correct),
            choices: options,
            helper: .decimalTenthsSum(a: a, b: b)
        )
    }

    // MARK: - Percentages

    private func makePercentProblem() -> TopicProblem {
        if Bool.random() {
            let percent = [25, 50, 75, 100].randomElement() ?? 50
            let correct = "\(percent)%"
            let options = uniqueChoices(
                correct: correct,
                distractors: ["\(max(10, percent - 25))%", "\(min(100, percent + 10))%", "10%"],
                count: 4
            )
            return TopicProblem(
                topic: .percentages,
                prompt: "What percent is shaded?",
                answer: .text(correct),
                choices: options,
                visual: .percentGrid(percent: percent)
            )
        }
        let percent = [10, 20, 25, 50].randomElement() ?? 50
        // Keep wholes exact so 25% never truncates (e.g. 25% of 30 → 7.5).
        let candidates = (2...12).map { $0 * 10 }.filter { $0 * percent % 100 == 0 }
        let whole = candidates.randomElement() ?? 40
        let answer = whole * percent / 100
        return TopicProblem(
            topic: .percentages,
            prompt: "\(percent)% of \(whole) = ?",
            spokenText: "What is \(percent) percent of \(whole)?",
            answer: .integer(answer),
            helper: .percentOf(percent: percent, whole: whole)
        )
    }

    // MARK: - Time

    private func makeTimeProblem() -> TopicProblem {
        let hour = Int.random(in: 1...12)
        let minuteOptions: [Int] = ageGroup == .preK ? [0] : (ageGroup == .early ? [0, 30] : [0, 15, 30, 45])
        let minute = minuteOptions.randomElement() ?? 0
        let display = formattedTime(hour: hour, minute: minute)
        var wrong = [
            formattedTime(hour: hour, minute: alternateMinute(for: minute)),
            formattedTime(hour: adjustedHour(hour, delta: -1), minute: minute),
            formattedTime(hour: adjustedHour(hour, delta: 1), minute: minute)
        ].filter { normalizedChoice($0) != normalizedChoice(display) }
        let options = uniqueChoices(correct: display, distractors: wrong, count: 4)
        let numericTime = "\(hour):\(String(format: "%02d", minute))"
        return TopicProblem(
            topic: .time,
            prompt: "What time does the clock show?",
            answer: .text(display),
            choices: options,
            acceptedAnswers: [numericTime],
            visual: .clock(hour: hour, minute: minute)
        )
    }

    private func alternateMinute(for minute: Int) -> Int {
        switch minute {
        case 0: return 30
        case 30: return 0
        case 15: return 45
        case 45: return 15
        default: return (minute + 15) % 60
        }
    }

    private func adjustedHour(_ hour: Int, delta: Int) -> Int {
        var value = hour + delta
        if value < 1 { value = 12 }
        if value > 12 { value = 1 }
        return value
    }

    private func normalizedChoice(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func formattedTime(hour: Int, minute: Int) -> String {
        switch minute {
        case 0: return "\(hour) o'clock"
        case 15: return "Quarter past \(hour)"
        case 30: return "Half past \(hour)"
        case 45: return "Quarter to \(hour == 12 ? 1 : hour + 1)"
        default: return "\(hour):\(String(format: "%02d", minute))"
        }
    }

    // MARK: - Money

    private func makeMoneyProblem() -> TopicProblem {
        struct Combo {
            let label: String
            let pieces: [MoneyPiece]
            var cents: Int { pieces.reduce(0) { $0 + $1.valueCents } }
        }

        let coinCombos: [Combo] = [
            Combo(label: "1 nickel", pieces: [.coin(5)]),
            Combo(label: "1 dime", pieces: [.coin(10)]),
            Combo(label: "1 quarter", pieces: [.coin(25)]),
            Combo(label: "1 dime and 1 nickel", pieces: [.coin(10), .coin(5)]),
            Combo(label: "3 dimes", pieces: [.coin(10), .coin(10), .coin(10)]),
            Combo(label: "1 quarter and 1 dime", pieces: [.coin(25), .coin(10)]),
            Combo(label: "1 quarter, 1 dime, and 1 nickel", pieces: [.coin(25), .coin(10), .coin(5)]),
            Combo(label: "2 quarters", pieces: [.coin(25), .coin(25)]),
            Combo(label: "3 quarters", pieces: [.coin(25), .coin(25), .coin(25)]),
        ]

        let billCombos: [Combo] = [
            Combo(label: "1 dollar bill", pieces: [.bill(1)]),
            Combo(label: "1 dollar bill and 1 quarter", pieces: [.bill(1), .coin(25)]),
            Combo(label: "1 dollar bill and 1 dime", pieces: [.bill(1), .coin(10)]),
            Combo(label: "1 dollar bill and 2 quarters", pieces: [.bill(1), .coin(25), .coin(25)]),
            Combo(label: "1 dollar bill, 1 quarter, and 1 nickel", pieces: [.bill(1), .coin(25), .coin(5)]),
            Combo(label: "2 dollar bills", pieces: [.bill(1), .bill(1)]),
            Combo(label: "1 five-dollar bill", pieces: [.bill(5)]),
            Combo(label: "1 five-dollar bill and 1 dollar bill", pieces: [.bill(5), .bill(1)]),
            Combo(label: "1 five-dollar bill and 2 quarters", pieces: [.bill(5), .coin(25), .coin(25)]),
        ]

        let combos: [Combo]
        switch ageGroup {
        case .preK:
            // Coins first, plus simple $1 bill counting.
            combos = coinCombos.filter { $0.cents <= 25 } + [
                Combo(label: "1 dollar bill", pieces: [.bill(1)]),
                Combo(label: "1 dollar bill and 1 nickel", pieces: [.bill(1), .coin(5)]),
            ]
        case .early:
            combos = coinCombos.filter { $0.cents <= 75 } + billCombos.filter {
                $0.pieces.allSatisfy { $0.kind != .bill || $0.valueCents == 100 }
            }
        case .upper:
            combos = coinCombos + billCombos
        }

        let pick = combos.randomElement() ?? coinCombos[0]
        return TopicProblem(
            topic: .money,
            prompt: "How many cents in all?",
            spokenText: "How many cents is \(pick.label)? A dollar bill is 100 cents. A quarter is 25 cents. A dime is 10 cents. A nickel is 5 cents.",
            story: "Count this money: \(pick.label).",
            answer: .integer(pick.cents),
            visual: .money(pieces: pick.pieces)
        )
    }

    // MARK: - Measurement

    private func makeMeasurementProblem() -> TopicProblem {
        if Bool.random() {
            let a = Int.random(in: 3...12)
            let b = Int.random(in: 1..<a)
            return TopicProblem(
                topic: .measurement,
                prompt: "How much longer is bar A than bar B?",
                answer: .integer(a - b),
                visual: .ruler(lengthA: a, lengthB: b, unit: "units")
            )
        }
        let total = Int.random(in: 4...20)
        let part = Int.random(in: 1..<total)
        return TopicProblem(
            topic: .measurement,
            prompt: "A ribbon is \(total) cm. You cut off \(part) cm. How many cm are left?",
            answer: .integer(total - part),
            helper: .subtraction(total: total, remove: part)
        )
    }

    // MARK: - Geometry

    private func makeGeometryProblem() -> TopicProblem {
        switch Int.random(in: 0...2) {
        case 0:
            let shape = [GeometryShape.triangle, .square, .rectangle, .hexagon].randomElement() ?? .square
            let sides = sideCount(for: shape)
            return TopicProblem(
                topic: .geometry,
                prompt: "How many sides does this shape have?",
                answer: .integer(sides),
                visual: .shape(kind: shape, width: 1, height: 1)
            )
        case 1:
            let width = Int.random(in: 2...5)
            let height = Int.random(in: 2...4)
            return TopicProblem(
                topic: .geometry,
                prompt: "What is the area? (count the unit squares)",
                answer: .integer(width * height),
                visual: .shape(kind: .rectangle, width: width, height: height)
            )
        default:
            let width = Int.random(in: 2...6)
            let height = Int.random(in: 2...5)
            return TopicProblem(
                topic: .geometry,
                prompt: "What is the perimeter? (count units around)",
                answer: .integer(2 * (width + height)),
                visual: .shape(kind: .rectangle, width: width, height: height)
            )
        }
    }

    private func sideCount(for shape: GeometryShape) -> Int {
        switch shape {
        case .triangle: 3
        case .square, .rectangle: 4
        case .circle: 0
        case .hexagon: 6
        }
    }

    // MARK: - Place Value

    private func makePlaceValueProblem() -> TopicProblem {
        let number = Int.random(in: 11...999)
        if ageGroup == .upper, Bool.random() {
            let rounded = ((number + 5) / 10) * 10
            return TopicProblem(
                topic: .placeValue,
                prompt: "Round \(number) to the nearest 10.",
                answer: .integer(rounded),
                visual: .placeValue(number: number)
            )
        }
        if Bool.random() {
            let correct = expandedForm(for: number)
            var distractors = [
                expandedForm(for: number + 10),
                expandedForm(for: max(10, number - 10)),
                "\(number)"
            ].filter { $0 != correct }
            let options = uniqueChoices(correct: correct, distractors: distractors, count: 4)
            return TopicProblem(
                topic: .placeValue,
                prompt: "What is \(number) in expanded form?",
                answer: .text(correct),
                choices: options,
                visual: .placeValue(number: number)
            )
        }
        let tensDigit = (number / 10) % 10
        return TopicProblem(
            topic: .placeValue,
            prompt: "In \(number), what digit is in the tens place?",
            answer: .integer(tensDigit),
            visual: .placeValue(number: number)
        )
    }

    private func expandedForm(for number: Int) -> String {
        let parts = [100, 10, 1].compactMap { place -> String? in
            let digit = (number / place) % 10
            guard digit > 0 else { return nil }
            return "\(digit * place)"
        }
        return parts.joined(separator: " + ")
    }

    private func uniqueChoices(correct: String, distractors: [String], count: Int) -> [String] {
        var options = [correct]
        for distractor in distractors where options.count < count {
            if !options.contains(where: { normalizedChoice($0) == normalizedChoice(distractor) }) {
                options.append(distractor)
            }
        }
        while options.count < count {
            let filler = "\(options.count + 1)"
            if !options.contains(filler) {
                options.append(filler)
            } else {
                break
            }
        }
        return options.shuffled()
    }

    // MARK: - Graphs & Data

    private func makeGraphProblem() -> TopicProblem {
        let labels = ["Red", "Blue", "Green", "Yellow"]
        let maxIndex = Int.random(in: 0..<labels.count)
        let maxValue = Int.random(in: 3...6)
        var values = (0..<labels.count).map { index in
            index == maxIndex ? maxValue : Int.random(in: 1...max(1, maxValue - 1))
        }
        // Safety: re-roll non-winners if random chance duplicated the max.
        while values.enumerated().contains(where: { $0.offset != maxIndex && $0.element >= maxValue }) {
            values = (0..<labels.count).map { index in
                index == maxIndex ? maxValue : Int.random(in: 1...max(1, maxValue - 1))
            }
        }
        let items = zip(labels, values).map { BarGraphItem(label: $0, value: $1) }
        if Bool.random() {
            let targetIndex = Int.random(in: 0..<items.count)
            let target = items[targetIndex]
            return TopicProblem(
                topic: .graphsAndData,
                prompt: "How many \(target.label.lowercased()) votes?",
                answer: .integer(target.value),
                visual: .barGraph(items: items)
            )
        }
        let choices = labels
        return TopicProblem(
            topic: .graphsAndData,
            prompt: "Which color has the most votes?",
            answer: .choiceIndex(maxIndex),
            choices: choices,
            visual: .barGraph(items: items)
        )
    }

    // MARK: - Probability

    private func makeProbabilityProblem() -> TopicProblem {
        if Bool.random() {
            let red = Int.random(in: 1...3)
            let total = red + Int.random(in: 1...3)
            let choices = ["Certain", "Likely", "Unlikely", "Impossible"]
            let redRatio = Double(red) / Double(total)
            let answerIndex: Int
            if red == total { answerIndex = 0 }
            else if redRatio >= 0.5 { answerIndex = 1 }
            else if red > 0 { answerIndex = 2 }
            else { answerIndex = 3 }
            return TopicProblem(
                topic: .probability,
                prompt: "If you spin once, landing on red is…",
                answer: .choiceIndex(answerIndex),
                choices: choices,
                visual: .spinner(redSections: red, totalSections: total)
            )
        }
        let red = Int.random(in: 2...5)
        let blue = Int.random(in: 1...3)
        return TopicProblem(
            topic: .probability,
            prompt: "A bag has \(red) red and \(blue) blue marbles. You pick one without looking. How many marbles in all?",
            answer: .integer(red + blue),
            helper: .addition(a: red, b: blue)
        )
    }

    // MARK: - Word Problems

    private func makeWordProblem() -> TopicProblem {
        let templates: [(story: String, prompt: String, answer: Int, helper: TopicHelper)] = [
            wordAddStory(),
            wordSubtractStory(),
            wordMultiStepStory(),
            wordCompareStory()
        ].compactMap { $0 }
        let pick = templates.randomElement() ?? wordAddStory()!
        return TopicProblem(
            topic: .wordProblems,
            prompt: pick.prompt,
            story: pick.story,
            answer: .integer(pick.answer),
            helper: pick.helper
        )
    }

    private func wordAddStory() -> (story: String, prompt: String, answer: Int, helper: TopicHelper)? {
        let a = Int.random(in: 2...20)
        let b = Int.random(in: 2...15)
        let names = ["Sam", "Jordan", "Riley", "Casey"]
        let name = names.randomElement() ?? "Sam"
        let items = ["stickers", "marbles", "books", "apples"]
        let item = items.randomElement() ?? "stickers"
        return (
            "\(name) has \(a) \(item). A friend gives \(name) \(b) more. Read carefully before you answer.",
            "How many \(item) does \(name) have now?",
            a + b,
            .addition(a: a, b: b)
        )
    }

    private func wordSubtractStory() -> (story: String, prompt: String, answer: Int, helper: TopicHelper)? {
        let total = Int.random(in: 10...30)
        let used = Int.random(in: 2..<total)
        return (
            "A baker made \(total) cookies. Customers bought \(used) cookies before lunch. Think about what is left.",
            "How many cookies are left?",
            total - used,
            .subtraction(total: total, remove: used)
        )
    }

    private func wordMultiStepStory() -> (story: String, prompt: String, answer: Int, helper: TopicHelper)? {
        guard ageGroup != .preK else { return wordAddStory() }
        let packs = Int.random(in: 2...5)
        let perPack = Int.random(in: 3...6)
        let given = Int.random(in: 1...3)
        return (
            "A teacher has \(packs) boxes with \(perPack) pencils in each box. She gives away \(given) pencils. Read the whole story first.",
            "How many pencils are left?",
            packs * perPack - given,
            .multiplicationThenSubtract(groups: packs, perGroup: perPack, remove: given)
        )
    }

    private func wordCompareStory() -> (story: String, prompt: String, answer: Int, helper: TopicHelper)? {
        let a = Int.random(in: 5...20)
        let b = a + Int.random(in: 3...8)
        return (
            "Team A scored \(a) points. Team B scored \(b) points. Compare the scores carefully.",
            "How many more points did Team B score?",
            b - a,
            .difference(larger: b, smaller: a)
        )
    }
}

private extension GeometryShape {
    static var allCases: [GeometryShape] {
        [.triangle, .square, .rectangle, .circle, .hexagon]
    }
}
