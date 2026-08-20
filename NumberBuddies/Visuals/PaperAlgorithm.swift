import Foundation

struct PaperDigitMark: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case carry
        case borrow
    }

    let columnFromRight: Int
    let text: String
    let kind: Kind
}

struct PaperWorkExplanation: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case carry
        case borrow
        case column
    }

    let kind: Kind
    let text: String
    let columnFromRight: Int
}

struct PaperAlgorithmWork: Equatable, Sendable {
    let operation: MathOperation
    let operandTop: String
    let operandBottom: String
    let operatorSymbol: String
    let resultLine: String?
    let marks: [PaperDigitMark]
    let explanations: [PaperWorkExplanation]
    let remainderSuffix: String?

    var columnCount: Int {
        max(operandTop.count, operandBottom.count, resultLine?.count ?? 0)
    }
}

enum PaperAlgorithm {
    static func needsPaperWork(for problem: MathProblem) -> Bool {
        switch problem.operation {
        case .addition, .subtraction:
            return problem.operandA >= 10 || problem.operandB >= 10 || problem.answer >= 10
        case .multiplication:
            return problem.operandA >= 10 || problem.operandB >= 10 || problem.answer >= 10
        case .division:
            return problem.operandA >= 10 || problem.operandB >= 10
        }
    }

    static func work(for problem: MathProblem, revealAnswer: Bool) -> PaperAlgorithmWork? {
        guard needsPaperWork(for: problem) else { return nil }

        switch problem.operation {
        case .addition:
            return additionWork(a: problem.operandA, b: problem.operandB, revealAnswer: revealAnswer)
        case .subtraction:
            return subtractionWork(a: problem.operandA, b: problem.operandB, revealAnswer: revealAnswer)
        case .multiplication:
            return multiplicationWork(a: problem.operandA, b: problem.operandB, revealAnswer: revealAnswer)
        case .division:
            return divisionWork(
                dividend: problem.operandA,
                divisor: problem.operandB,
                quotient: problem.answer,
                remainder: problem.remainder,
                revealAnswer: revealAnswer
            )
        }
    }

    private static func additionWork(a: Int, b: Int, revealAnswer: Bool) -> PaperAlgorithmWork {
        let top = String(a)
        let bottom = String(b)
        let width = max(top.count, bottom.count)
        let topDigits = paddedDigits(a, width: width)
        let bottomDigits = paddedDigits(b, width: width)

        var marks: [PaperDigitMark] = []
        var explanations: [PaperWorkExplanation] = []
        var carry = 0
        var resultDigits: [Int] = []

        for column in stride(from: width - 1, through: 0, by: -1) {
            let index = width - 1 - column
            let topDigit = topDigits[index]
            let bottomDigit = bottomDigits[index]
            let incomingCarry = carry
            let sum = topDigit + bottomDigit + carry
            resultDigits.insert(sum % 10, at: 0)

            let place = placeName(columnFromRight: column)
            if sum >= 10 {
                carry = 1
                marks.append(PaperDigitMark(columnFromRight: column + 1, text: "1", kind: .carry))
                let additionPhrase = incomingCarry > 0
                    ? "\(topDigit) + \(bottomDigit) + \(incomingCarry)"
                    : "\(topDigit) + \(bottomDigit)"
                explanations.append(
                    PaperWorkExplanation(
                        kind: .carry,
                        text: "In the \(place) place, \(additionPhrase) = \(sum). That is 10 or more, so write \(sum % 10) and carry 1 to the \(placeName(columnFromRight: column + 1)) place.",
                        columnFromRight: column
                    )
                )
            } else {
                carry = 0
                let additionPhrase: String
                if incomingCarry > 0 {
                    additionPhrase = "\(topDigit) + \(bottomDigit) + \(incomingCarry) = \(sum)"
                } else {
                    additionPhrase = "\(topDigit) + \(bottomDigit) = \(sum)"
                }
                explanations.append(
                    PaperWorkExplanation(
                        kind: .column,
                        text: "In the \(place) place, \(additionPhrase). Write \(sum).",
                        columnFromRight: column
                    )
                )
            }
        }
        if carry > 0 {
            resultDigits.insert(carry, at: 0)
        }

        let answer = a + b
        return PaperAlgorithmWork(
            operation: .addition,
            operandTop: String(a),
            operandBottom: String(b),
            operatorSymbol: "+",
            resultLine: revealAnswer ? String(answer) : nil,
            marks: marks,
            explanations: explanations.sorted { $0.columnFromRight < $1.columnFromRight },
            remainderSuffix: nil
        )
    }

    private static func subtractionWork(a: Int, b: Int, revealAnswer: Bool) -> PaperAlgorithmWork {
        let width = max(String(a).count, String(b).count)
        var top = paddedDigits(a, width: width)
        let bottom = paddedDigits(b, width: width)
        var marks: [PaperDigitMark] = []
        var explanations: [PaperWorkExplanation] = []

        for index in stride(from: width - 1, through: 0, by: -1) {
            let columnFromRight = width - 1 - index
            let place = placeName(columnFromRight: columnFromRight)
            let topDigit = top[index]
            let bottomDigit = bottom[index]

            if topDigit < bottomDigit {
                var borrowFrom = index - 1
                while borrowFrom >= 0 && top[borrowFrom] == 0 {
                    top[borrowFrom] = 9
                    borrowFrom -= 1
                }
                if borrowFrom >= 0 {
                    let original = top[borrowFrom]
                    let lenderPlace = placeName(columnFromRight: width - 1 - borrowFrom)
                    top[borrowFrom] = original - 1
                    marks.append(
                        PaperDigitMark(
                            columnFromRight: width - 1 - borrowFrom,
                            text: "\(original - 1)",
                            kind: .borrow
                        )
                    )
                    let boosted = topDigit + 10
                    marks.append(
                        PaperDigitMark(
                            columnFromRight: columnFromRight,
                            text: "\(boosted)",
                            kind: .borrow
                        )
                    )
                    top[index] += 10
                    let difference = top[index] - bottomDigit
                    explanations.append(
                        PaperWorkExplanation(
                            kind: .borrow,
                            text: "In the \(place) place, we can't take \(bottomDigit) from \(topDigit). Borrow 1 from the \(lenderPlace) place. \(topDigit) becomes \(boosted), and \(boosted) − \(bottomDigit) = \(difference).",
                            columnFromRight: columnFromRight
                        )
                    )
                }
            } else {
                let difference = topDigit - bottomDigit
                explanations.append(
                    PaperWorkExplanation(
                        kind: .column,
                        text: "In the \(place) place, \(topDigit) − \(bottomDigit) = \(difference). Write \(difference).",
                        columnFromRight: columnFromRight
                    )
                )
            }
        }

        return PaperAlgorithmWork(
            operation: .subtraction,
            operandTop: String(a),
            operandBottom: String(b),
            operatorSymbol: "−",
            resultLine: revealAnswer ? String(a - b) : nil,
            marks: marks,
            explanations: explanations.sorted { $0.columnFromRight < $1.columnFromRight },
            remainderSuffix: nil
        )
    }

    private static func multiplicationWork(a: Int, b: Int, revealAnswer: Bool) -> PaperAlgorithmWork {
        let top = a
        let bottom = b
        let topText = String(top)
        let bottomText = String(bottom)
        let width = topText.count

        var marks: [PaperDigitMark] = []
        var explanations: [PaperWorkExplanation] = []
        var carry = 0
        var resultDigits: [Int] = []
        let topDigits = paddedDigits(top, width: width)

        for index in stride(from: width - 1, through: 0, by: -1) {
            let columnFromRight = width - 1 - index
            let place = placeName(columnFromRight: columnFromRight)
            let topDigit = topDigits[index]
            let incomingCarry = carry
            let product = topDigit * bottom + carry
            resultDigits.insert(product % 10, at: 0)
            if product >= 10 {
                carry = product / 10
                if index > 0 {
                    marks.append(
                        PaperDigitMark(
                            columnFromRight: width - index,
                            text: "\(carry)",
                            kind: .carry
                        )
                    )
                }
                let productPhrase = incomingCarry > 0
                    ? "\(topDigit) × \(bottom) + \(incomingCarry)"
                    : "\(topDigit) × \(bottom)"
                explanations.append(
                    PaperWorkExplanation(
                        kind: .carry,
                        text: "In the \(place) place, \(productPhrase) = \(product). Write \(product % 10) and carry \(carry) to the \(placeName(columnFromRight: columnFromRight + 1)) place.",
                        columnFromRight: columnFromRight
                    )
                )
            } else {
                carry = 0
                let productPhrase = incomingCarry > 0
                    ? "\(topDigit) × \(bottom) + \(incomingCarry) = \(product)"
                    : "\(topDigit) × \(bottom) = \(product)"
                explanations.append(
                    PaperWorkExplanation(
                        kind: .column,
                        text: "In the \(place) place, \(productPhrase). Write \(product).",
                        columnFromRight: columnFromRight
                    )
                )
            }
        }
        if carry > 0 {
            resultDigits.insert(carry, at: 0)
        }

        return PaperAlgorithmWork(
            operation: .multiplication,
            operandTop: topText,
            operandBottom: bottomText,
            operatorSymbol: "×",
            resultLine: revealAnswer ? String(top * bottom) : nil,
            marks: marks,
            explanations: explanations.sorted { $0.columnFromRight < $1.columnFromRight },
            remainderSuffix: nil
        )
    }

    private static func divisionWork(
        dividend: Int,
        divisor: Int,
        quotient: Int,
        remainder: Int?,
        revealAnswer: Bool
    ) -> PaperAlgorithmWork {
        let remainderText: String?
        if revealAnswer, let remainder, remainder > 0 {
            remainderText = "R \(remainder)"
        } else {
            remainderText = nil
        }

        var explanations: [PaperWorkExplanation] = []
        if revealAnswer {
            explanations.append(
                PaperWorkExplanation(
                    kind: .column,
                    text: "Start with \(dividend). Share into \(divisor) equal groups.",
                    columnFromRight: 0
                )
            )
            if let remainder, remainder > 0 {
                explanations.append(
                    PaperWorkExplanation(
                        kind: .column,
                        text: "Each group gets \(quotient). \(remainder) is left over.",
                        columnFromRight: 0
                    )
                )
            } else {
                explanations.append(
                    PaperWorkExplanation(
                        kind: .column,
                        text: "Each group gets \(quotient).",
                        columnFromRight: 0
                    )
                )
            }
        }

        return PaperAlgorithmWork(
            operation: .division,
            operandTop: String(dividend),
            operandBottom: String(divisor),
            operatorSymbol: "÷",
            resultLine: revealAnswer ? String(quotient) : nil,
            marks: [],
            explanations: explanations,
            remainderSuffix: remainderText
        )
    }

    private static func placeName(columnFromRight: Int) -> String {
        switch columnFromRight {
        case 0: "ones"
        case 1: "tens"
        case 2: "hundreds"
        case 3: "thousands"
        default: "next"
        }
    }

    private static func paddedDigits(_ value: Int, width: Int) -> [Int] {
        let text = String(value)
        let padding = max(0, width - text.count)
        let padded = String(repeating: "0", count: padding) + text
        return padded.map { Int(String($0)) ?? 0 }
    }
}
