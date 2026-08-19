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
    var showCelebration = false
    var isAdvancing = false
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

    func clearInput() {
        input = ""
    }

    func submit() {
        guard !isAdvancing, let problem = currentProblem, let value = Int(input), !input.isEmpty else { return }

        if value == problem.answer {
            handleCorrect()
        } else {
            handleWrong(problem: problem)
        }
    }

    private func handleCorrect() {
        correctCount += 1
        starsEarned += 1
        showCelebration = true
        feedbackMessage = nil
        isAdvancing = true
        FeedbackService.correctAnswer()

        Task {
            try? await Task.sleep(for: .milliseconds(700))
            showCelebration = false
            advance()
            isAdvancing = false
        }
    }

    private func handleWrong(problem: MathProblem) {
        attempts += 1
        shakeWrong = true
        FeedbackService.wrongAnswer()

        if attempts >= 2 {
            showHint = true
            feedbackMessage = "The answer is \(problem.answer)."
            isAdvancing = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                advanceAfterMiss()
                isAdvancing = false
            }
        } else {
            feedbackMessage = "Try again!"
            input = ""
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
        showCelebration = false
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

    func speakCurrentProblem() {
        guard let problem = currentProblem, AppSettings.readAloudEnabled else { return }
        SpeechService.shared.speak(problem.spokenText)
    }
}
