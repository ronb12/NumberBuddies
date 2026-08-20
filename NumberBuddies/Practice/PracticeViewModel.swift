import Foundation
import Observation

enum PracticePhase: Equatable {
    case playing
    case finished(stars: Int, correct: Int, total: Int)
}

@MainActor
@Observable
final class PracticeViewModel {
    let mode: PracticeMode
    private let generator: ProblemGenerator
    private let startedAt = Date()
    private var operationTally: [MathOperation: (correct: Int, total: Int, stars: Int)] = [:]
    private var missedByOperation: [MathOperation: Int] = [:]

    var problems: [MathProblem] = []
    var currentIndex = 0
    var input = ""
    var attempts = 0
    var correctCount = 0
    var starsEarned = 0
    var showVisual = false
    var showHint = false
    var shakeWrong = false
    var showCelebration = false
    var isAdvancing = false
    var phase: PracticePhase = .playing
    var feedbackMessage: String?

    init(mode: PracticeMode, ageGroup: AgeGroup, difficulty: Int, mixedOperations: [MathOperation]? = nil, mixedDifficulty: Int? = nil) {
        self.mode = mode
        self.generator = ProblemGenerator(ageGroup: ageGroup)
        self.showVisual = ageGroup == .preK

        switch mode {
        case .operation(let operation):
            problems = generator.round(for: operation, difficulty: difficulty)
        case .mixedReview:
            let level = mixedDifficulty ?? difficulty
            let operations = mixedOperations ?? ageGroup.availableOperations(for: level)
            problems = generator.mixedRound(operations: operations, difficulty: level)
        case .mathChallenge(let kind):
            problems = MathChallengeGenerator.problems(for: kind)
        }
    }

    var challengeKind: MathChallengeKind? {
        if case .mathChallenge(let kind) = mode { return kind }
        return nil
    }

    var challengeProgressLabel: String? {
        guard let kind = challengeKind, let problem = currentProblem else { return nil }
        return MathChallengeGenerator.challengeLabel(for: problem, index: currentIndex, kind: kind)
    }

    var currentProblem: MathProblem? {
        guard currentIndex < problems.count else { return nil }
        return problems[currentIndex]
    }

    var accentOperation: MathOperation {
        currentProblem?.operation ?? mode.progressOperation ?? .addition
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
            handleCorrect(problem: problem)
        } else {
            handleWrong(problem: problem)
        }
    }

    func mixedResults() -> [MathOperation: (correct: Int, total: Int, stars: Int)] {
        operationTally
    }

    func sessionDurationSeconds() -> Int {
        max(1, Int(Date().timeIntervalSince(startedAt)))
    }

    func missedCounts() -> [MathOperation: Int] {
        missedByOperation
    }

    func operationResults() -> [MathOperation: (correct: Int, total: Int)] {
        operationTally.mapValues { ($0.correct, $0.total) }
    }

    private func handleCorrect(problem: MathProblem) {
        correctCount += 1
        starsEarned += 1
        recordAttempt(for: problem, correct: true, earnedStar: true)
        showCelebration = true
        feedbackMessage = nil
        isAdvancing = true
        FeedbackService.correctAnswer()
        CheerSoundService.shared.playCheer {
            SpeechService.shared.speakEncouragement(SpeechService.randomCelebration())
        }

        Task {
            try? await Task.sleep(for: .milliseconds(1200))
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
            missedByOperation[problem.operation, default: 0] += 1
            recordAttempt(for: problem, correct: false, earnedStar: false)
            let answerWord = SpokenNumbers.word(for: problem.answer)
            if problem.operation == .division, problem.hasRemainder, let remainder = problem.remainder {
                feedbackMessage = "The answer is \(problem.answer) R \(remainder)."
                SpeechService.shared.speakHint(
                    "That's okay! Each group gets \(answerWord), with \(SpokenNumbers.word(for: remainder)) left over."
                )
            } else {
                feedbackMessage = "The answer is \(problem.answer)."
                SpeechService.shared.speakHint("That's okay! The answer is \(answerWord).")
            }
            speakHelperSteps(for: problem)
            isAdvancing = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                advanceAfterMiss()
                isAdvancing = false
            }
        } else {
            feedbackMessage = "Try again!"
            if !showVisual {
                SpeechService.shared.speakHelper("Need a clue? Turn on the picture helper!")
            } else {
                SpeechService.shared.speakRetry(SpeechService.randomRetry())
            }
            input = ""
        }
    }

    private func recordAttempt(for problem: MathProblem, correct: Bool, earnedStar: Bool) {
        var entry = operationTally[problem.operation] ?? (0, 0, 0)
        entry.total += 1
        if correct {
            entry.correct += 1
        }
        if earnedStar {
            entry.stars += 1
        }
        operationTally[problem.operation] = entry
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

    func speakHelperIntro(for problem: MathProblem) {
        guard AppSettings.readAloudEnabled else { return }
        if PaperAlgorithm.needsPaperWork(for: problem) {
            SpeechService.shared.speakHelper("Let's write it out step by step!")
        } else {
            SpeechService.shared.speakHelper(SpeechService.helperIntroPhrases.randomElement() ?? "Let's use a picture to help!")
        }
    }

    private func speakHelperSteps(for problem: MathProblem) {
        guard AppSettings.readAloudEnabled else { return }
        if let work = PaperAlgorithm.work(for: problem, revealAnswer: true),
           let firstStep = work.explanations.first?.text {
            SpeechService.shared.speakHelper(firstStep)
        } else {
            switch problem.operation {
            case .addition:
                SpeechService.shared.speakHelper("Count all the dots together to get \(SpokenNumbers.word(for: problem.answer)).")
            case .subtraction:
                SpeechService.shared.speakHelper("Cross out \(SpokenNumbers.word(for: problem.operandB)), then count what's left.")
            case .multiplication:
                SpeechService.shared.speakHelper("Count every dot in all the groups.")
            case .division:
                SpeechService.shared.speakHelper("Share equally into each group.")
            }
        }
    }
}
