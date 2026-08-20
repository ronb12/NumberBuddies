
import Foundation
import Observation

@MainActor
@Observable
final class TopicPracticeViewModel {
    let topic: MathTopic
    let ageGroup: AgeGroup
    private let generator: TopicProblemGenerator
    private let startedAt = Date()

    var problems: [TopicProblem] = []
    var currentIndex = 0
    var input = ""
    var selectedChoice: Int?
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

    init(topic: MathTopic, ageGroup: AgeGroup) {
        self.topic = topic
        self.ageGroup = ageGroup
        self.generator = TopicProblemGenerator(ageGroup: ageGroup)
        self.showVisual = ageGroup == .preK
        self.problems = generator.round(for: topic)
    }

    var currentProblem: TopicProblem? {
        guard currentIndex < problems.count else { return nil }
        return problems[currentIndex]
    }

    var progressText: String {
        "Question \(min(currentIndex + 1, problems.count)) of \(problems.count)"
    }

    func submit() {
        guard !isAdvancing, let problem = currentProblem else { return }

        if problem.expectsChoiceOnlyInput {
            guard selectedChoice != nil else { return }
        } else if problem.expectsNumericInput {
            guard !input.isEmpty, Int(input) != nil else { return }
        } else if problem.expectsTextInput {
            guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        }

        if problem.isCorrect(input: input, selectedChoice: selectedChoice) {
            handleCorrect()
        } else {
            handleWrong(problem: problem)
        }
    }

    func selectChoice(_ index: Int) {
        guard !isAdvancing, let problem = currentProblem, let choices = problem.choices else { return }
        guard choices.indices.contains(index) else { return }
        selectedChoice = index
        input = choices[index]
        submit()
    }

    func clearInput() {
        input = ""
        selectedChoice = nil
    }

    func sessionDurationSeconds() -> Int {
        max(1, Int(Date().timeIntervalSince(startedAt)))
    }

    private func handleCorrect() {
        correctCount += 1
        starsEarned += 1
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

    private func handleWrong(problem: TopicProblem) {
        attempts += 1
        shakeWrong = true
        FeedbackService.wrongAnswer()

        if attempts >= 2 {
            showHint = true
            let spokenAnswer = SpokenNumbers.spokenAnswer(for: problem)
            feedbackMessage = "The answer is \(problem.correctDisplayAnswer)."
            SpeechService.shared.speakHint("That's okay! The answer is \(spokenAnswer).")
            speakHelperTip(for: problem)
            isAdvancing = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                advanceAfterMiss()
                isAdvancing = false
            }
        } else {
            feedbackMessage = "Try again!"
            if !showVisual, problem.hasHelper {
                SpeechService.shared.speakHelper("Need a clue? Turn on the picture helper!")
            } else {
                SpeechService.shared.speakRetry(SpeechService.randomRetry())
            }
            input = ""
            selectedChoice = nil
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
        selectedChoice = nil
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
        if let story = problem.story, !story.isEmpty {
            SpeechService.shared.speakSequence([story, problem.prompt])
        } else {
            SpeechService.shared.speak(problem.spokenText)
        }
    }

    func speakHelperIntro(for problem: TopicProblem) {
        guard AppSettings.readAloudEnabled else { return }
        if TopicPaperAlgorithm.needsPaperWork(for: problem) {
            SpeechService.shared.speakHelper("Let's write it out step by step!")
        } else {
            SpeechService.shared.speakHelper(SpeechService.helperIntroPhrases.randomElement() ?? "Let's use a picture to help!")
        }
    }

    private func speakHelperTip(for problem: TopicProblem) {
        guard AppSettings.readAloudEnabled else { return }
        if let work = TopicPaperAlgorithm.work(for: problem, revealAnswer: true),
           let firstStep = work.explanations.first?.text {
            SpeechService.shared.speakHelper(firstStep)
            return
        }

        if let stepHint = topicStepHint(for: problem) {
            SpeechService.shared.speakHelper(stepHint)
        }
    }

    private func topicStepHint(for problem: TopicProblem) -> String? {
        if problem.helper != nil { return nil }
        switch problem.topic {
        case .fractions:
            return "Count the shaded parts. The bottom number is all the parts."
        case .decimals:
            return "Each square is one tenth."
        case .percentages:
            return "Shaded squares show parts out of 100."
        case .time:
            return "Read the short hand for the hour and the long hand for minutes."
        case .money:
            if case .money(let pieces) = problem.visual, pieces.contains(where: { $0.kind == .bill }) {
                return "Dollar bills first. One dollar is 100 cents. Then add the coins."
            }
            return "Name each coin, then add: quarter 25 cents, dime 10 cents, nickel 5 cents."
        case .measurement:
            return "Compare the bar lengths on the ruler."
        case .geometry:
            return "Count carefully — area fills the inside, perimeter goes around."
        case .placeValue:
            return "Each column shows a place: ones, tens, or hundreds."
        case .graphsAndData:
            return "Taller bars mean more votes."
        case .probability:
            return "More red means a better chance of landing on red."
        case .wordProblems:
            return nil
        }
    }
}
