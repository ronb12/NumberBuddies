import Foundation
import Observation

enum PracticePhase: Equatable {
    case playing
    case finished(stars: Int, correct: Int, total: Int)
}

@MainActor
@Observable
final class PracticeViewModel {
    let operation: MathOperation
    private let generator = ProblemGenerator()

    var problems: [MathProblem] = []
    var currentIndex = 0
    var input = ""
    var attempts = 0
    var correctCount = 0
    var starsEarned = 0
    var showVisual = true
    var showHint = false
    var shakeWrong = false
    var phase: PracticePhase = .playing
    var feedbackMessage: String?

    init(operation: MathOperation, difficulty: Int) {
        self.operation = operation
        self.problems = generator.round(for: operation, difficulty: difficulty)
    }

    var currentProblem: MathProblem? {
        guard currentIndex < problems.count else { return nil }
        return problems[currentIndex]
    }

    var progressText: String {
        "Question \(min(currentIndex + 1, problems.count)) of \(problems.count)"
    }

    func appendDigit(_ digit: String) {
        guard input.count < 4 else { return }
        input += digit
    }

    func clearInput() {
        input = ""
    }

    func submit() {
        guard let problem = currentProblem, let value = Int(input) else { return }

        if value == problem.answer {
            correctCount += 1
            starsEarned += 1
            feedbackMessage = "Great job!"
            advance()
        } else {
            attempts += 1
            shakeWrong = true
            if attempts >= 2 {
                showHint = true
                feedbackMessage = "The answer is \(problem.answer)."
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.advanceAfterMiss()
                }
            } else {
                feedbackMessage = "Try again!"
                input = ""
            }
        }
    }

    private func advanceAfterMiss() {
        attempts = 0
        showHint = false
        feedbackMessage = nil
        advance()
    }

    private func advance() {
        attempts = 0
        showHint = false
        feedbackMessage = nil
        input = ""
        shakeWrong = false

        if currentIndex + 1 >= problems.count {
            phase = .finished(stars: starsEarned, correct: correctCount, total: problems.count)
        } else {
            currentIndex += 1
        }
    }

    func resetShake() {
        shakeWrong = false
    }
}
