import SwiftData
import SwiftUI

struct TopicPracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let topic: MathTopic
    let profileId: UUID
    let ageGroup: AgeGroup

    @State private var viewModel: TopicPracticeViewModel?
    @State private var didSaveRound = false

    private var isCompactPhone: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        ZStack {
            PlayfulBackground()

            if let viewModel {
                content(for: viewModel)
            } else {
                ProgressView("Loading...")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(topic.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(topic.accentColor)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = TopicPracticeViewModel(topic: topic, ageGroup: ageGroup)
            }
        }
        .onDisappear {
            SpeechService.shared.stop()
            CheerSoundService.shared.stop()
        }
    }

    @ViewBuilder
    private func content(for viewModel: TopicPracticeViewModel) -> some View {
        switch viewModel.phase {
        case .playing:
            playingView(viewModel)
        case let .finished(stars, correct, total):
            ScrollView {
                ResultView(
                    title: topic.title,
                    accent: topic.accentColor,
                    stars: stars,
                    correct: correct,
                    total: total,
                    onPlayAgain: {
                        didSaveRound = false
                        self.viewModel = TopicPracticeViewModel(topic: topic, ageGroup: ageGroup)
                    },
                    onHome: { dismiss() }
                )
            }
            .onAppear {
                saveRoundIfNeeded(stars: stars, correct: correct, total: total, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private func playingView(_ viewModel: TopicPracticeViewModel) -> some View {
        if let problem = viewModel.currentProblem {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: isCompactPhone ? 12 : 16) {
                        RoundProgressBar(
                            current: viewModel.currentIndex + 1,
                            total: viewModel.problems.count,
                            accent: topic.accentColor
                        )

                        if let story = problem.story {
                            Text(story)
                                .font(.body.weight(.medium))
                                .foregroundStyle(AppTheme.ink.opacity(0.85))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 14))
                        }

                        Text(problem.prompt)
                            .font(.system(size: isCompactPhone ? 24 : 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                            .multilineTextAlignment(.center)
                            .accessibilityLabel(problem.spokenText)

                        if problem.hasHelper {
                            PictureHelperToggle(
                                isOn: Bindable(viewModel).showVisual,
                                accent: topic.accentColor,
                                usesPaperWork: TopicPaperAlgorithm.needsPaperWork(for: problem)
                            )
                        }

                        if problem.hasHelper, viewModel.showVisual || viewModel.showHint {
                            if TopicPaperAlgorithm.needsPaperWork(for: problem),
                               let work = TopicPaperAlgorithm.work(for: problem, revealAnswer: viewModel.showHint) {
                                PaperWorkView(
                                    work: work,
                                    accent: topic.accentColor,
                                    compact: isCompactPhone,
                                    revealAnswer: viewModel.showHint
                                )
                                .transition(.opacity)
                            } else {
                                TopicHelperView(
                                    problem: problem,
                                    accent: topic.accentColor,
                                    compact: isCompactPhone,
                                    revealAnswer: viewModel.showHint
                                )
                                .transition(.opacity)
                            }
                        }

                        if viewModel.showCelebration {
                            CorrectBurstView()
                        } else if let message = viewModel.feedbackMessage {
                            Text(message)
                                .font(.headline)
                                .foregroundStyle(viewModel.showHint ? AppTheme.coral : AppTheme.teal)
                        }

                        if problem.hasChoiceShortcuts, problem.expectsChoiceOnlyInput, let choices = problem.choices {
                            ChoiceGrid(
                                choices: choices,
                                selected: viewModel.selectedChoice,
                                accent: topic.accentColor,
                                isDisabled: viewModel.isAdvancing,
                                onSelect: { viewModel.selectChoice($0) }
                            )
                        } else if problem.hasChoiceShortcuts, let choices = problem.choices {
                            VStack(spacing: 8) {
                                Text("Or tap an answer")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.ink.opacity(0.55))
                                ChoiceGrid(
                                    choices: choices,
                                    selected: viewModel.selectedChoice,
                                    accent: topic.accentColor,
                                    isDisabled: viewModel.isAdvancing,
                                    onSelect: { viewModel.selectChoice($0) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }

                answerInput(for: problem, viewModel: viewModel)
            }
            .onAppear { viewModel.speakCurrentProblem() }
            .onChange(of: viewModel.currentIndex) { _, _ in viewModel.speakCurrentProblem() }
            .onChange(of: viewModel.showVisual) { _, isOn in
                if isOn { viewModel.speakHelperIntro(for: problem) }
            }
        }
    }

    @ViewBuilder
    private func answerInput(for problem: TopicProblem, viewModel: TopicPracticeViewModel) -> some View {
        if problem.expectsNumericInput {
            NumberPadView(
                input: Bindable(viewModel).input,
                onSubmit: { viewModel.submit() },
                onClear: { viewModel.clearInput() },
                accent: topic.accentColor,
                isDisabled: viewModel.isAdvancing,
                compact: isCompactPhone
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppTheme.cream.opacity(0.95))
            .modifier(ShakeEffect(animating: viewModel.shakeWrong && !reduceMotion))
            .onChange(of: viewModel.shakeWrong) { _, shaking in
                if shaking {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        viewModel.resetShake()
                    }
                }
            }
        } else if problem.expectsTextInput {
            TextAnswerPadView(
                input: Bindable(viewModel).input,
                style: problem.textPadStyle,
                onSubmit: { viewModel.submit() },
                onClear: { viewModel.clearInput() },
                accent: topic.accentColor,
                isDisabled: viewModel.isAdvancing,
                compact: isCompactPhone
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppTheme.cream.opacity(0.95))
            .modifier(ShakeEffect(animating: viewModel.shakeWrong && !reduceMotion))
            .onChange(of: viewModel.shakeWrong) { _, shaking in
                if shaking {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        viewModel.resetShake()
                    }
                }
            }
        }
    }

    private func saveRoundIfNeeded(stars: Int, correct: Int, total: Int, viewModel: TopicPracticeViewModel) {
        guard !didSaveRound else { return }
        didSaveRound = true

        if let profile = ProfileStore.profile(with: profileId, context: modelContext) {
            ProfileStore.recordRoundStats(
                profile: profile,
                correct: correct,
                total: total,
                context: modelContext
            )
        }

        let session = PracticeSession(
            profileId: profileId,
            modeTitle: topic.title,
            correct: correct,
            total: total,
            durationSeconds: viewModel.sessionDurationSeconds()
        )
        modelContext.insert(session)
        try? modelContext.save()
    }
}

private struct ChoiceGrid: View {
    let choices: [String]
    let selected: Int?
    let accent: Color
    let isDisabled: Bool
    let onSelect: (Int) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                Button {
                    onSelect(index)
                } label: {
                    Text(choice)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            selected == index ? accent.opacity(0.25) : .white,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selected == index ? accent : AppTheme.ink.opacity(0.12), lineWidth: selected == index ? 2 : 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
            }
        }
    }
}

private struct ShakeEffect: ViewModifier {
    let animating: Bool
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: animating) { _, newValue in
                guard newValue else { return }
                withAnimation(.default) { offset = -8 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.default) { offset = 8 }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    withAnimation(.default) { offset = 0 }
                }
            }
    }
}

#Preview {
    NavigationStack {
        TopicPracticeView(topic: .fractions, profileId: UUID(), ageGroup: .upper)
    }
    .modelContainer(for: [KidProfile.self, KidProgress.self, PracticeSession.self], inMemory: true)
}
