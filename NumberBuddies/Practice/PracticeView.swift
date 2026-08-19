import SwiftData
import SwiftUI

struct PracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let mode: PracticeMode
    let profileId: UUID
    let ageGroup: AgeGroup

    @State private var viewModel: PracticeViewModel?
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
                Text(toolbarTitle(for: viewModel))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(toolbarAccent(for: viewModel))
            }
        }
        .task {
            if viewModel == nil {
                viewModel = makeViewModel()
            }
        }
        .onDisappear {
            SpeechService.shared.stop()
        }
    }

    @ViewBuilder
    private func content(for viewModel: PracticeViewModel) -> some View {
        switch viewModel.phase {
        case .playing:
            playingView(viewModel)
        case let .finished(stars, correct, total):
            ScrollView {
                ResultView(
                    title: mode.title,
                    accent: toolbarAccent(for: viewModel),
                    stars: stars,
                    correct: correct,
                    total: total,
                    onPlayAgain: {
                        didSaveRound = false
                        self.viewModel = makeViewModel()
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
    private func playingView(_ viewModel: PracticeViewModel) -> some View {
        if let problem = viewModel.currentProblem {
            Group {
                if isCompactPhone {
                    VStack(spacing: 0) {
                        ScrollView {
                            visualSection(problem: problem, viewModel: viewModel)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .padding(.bottom, 12)
                        }

                        controlSection(viewModel: viewModel)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                            .background(AppTheme.cream.opacity(0.95))
                    }
                } else {
                    HStack(alignment: .top, spacing: 32) {
                        ScrollView {
                            visualSection(problem: problem, viewModel: viewModel)
                        }
                        .frame(maxWidth: .infinity)

                        controlSection(viewModel: viewModel)
                            .frame(maxWidth: 420)
                    }
                    .padding(32)
                }
            }
            .onChange(of: viewModel.currentIndex) { _, _ in
                viewModel.speakCurrentProblem()
            }
            .onAppear {
                viewModel.speakCurrentProblem()
            }
        }
    }

    @ViewBuilder
    private func visualSection(problem: MathProblem, viewModel: PracticeViewModel) -> some View {
        let accent = AppTheme.color(for: viewModel.accentOperation)

        VStack(spacing: isCompactPhone ? 10 : 16) {
            RoundProgressBar(
                current: viewModel.currentIndex + 1,
                total: viewModel.problems.count,
                accent: accent,
                subtitle: viewModel.challengeProgressLabel
            )

            Text(problem.prompt)
                .font(.system(
                    size: promptFontSize,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(AppTheme.ink)
                .minimumScaleFactor(0.5)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .accessibilityLabel(problem.spokenText)

            PictureHelperToggle(isOn: Bindable(viewModel).showVisual, accent: accent)

            if viewModel.showVisual || viewModel.showHint {
                ProblemVisualView(problem: problem, compact: isCompactPhone)
                    .transition(.opacity)
            }

            if viewModel.showCelebration {
                CorrectBurstView()
                    .transition(.scale.combined(with: .opacity))
            } else if let message = viewModel.feedbackMessage {
                Text(message)
                    .font(.headline)
                    .foregroundStyle(viewModel.showHint ? AppTheme.coral : AppTheme.teal)
            }
        }
    }

    @ViewBuilder
    private func controlSection(viewModel: PracticeViewModel) -> some View {
        NumberPadView(
            input: Bindable(viewModel).input,
            onSubmit: { viewModel.submit() },
            onClear: { viewModel.clearInput() },
            accent: AppTheme.color(for: viewModel.accentOperation),
            isDisabled: viewModel.isAdvancing,
            compact: isCompactPhone
        )
        .modifier(ShakeEffect(animating: viewModel.shakeWrong && !reduceMotion))
        .onChange(of: viewModel.shakeWrong) { _, shaking in
            if shaking {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    viewModel.resetShake()
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func toolbarTitle(for viewModel: PracticeViewModel?) -> String {
        if case .mixedReview = mode, let viewModel {
            return viewModel.accentOperation.title
        }
        return mode.title
    }

    private func toolbarAccent(for viewModel: PracticeViewModel?) -> Color {
        if case .mixedReview = mode, let viewModel {
            return AppTheme.color(for: viewModel.accentOperation)
        }
        return mode.accentColor
    }

    private var promptFontSize: CGFloat {
        if isCompactPhone {
            return dynamicTypeSize.isAccessibilitySize ? 28 : 34
        }
        return dynamicTypeSize.isAccessibilitySize ? 36 : 48
    }

    private func makeViewModel() -> PracticeViewModel {
        let profile = ProfileStore.profile(with: profileId, context: modelContext)
        let unlocked = profile.map { ProgressStore.unlockedOperations(for: $0, context: modelContext) } ?? ageGroup.homeOperations

        switch mode {
        case .operation(let operation):
            let difficulty = ProgressStore.difficulty(
                for: operation,
                profileId: profileId,
                context: modelContext
            )
            return PracticeViewModel(mode: mode, ageGroup: ageGroup, difficulty: difficulty)
        case .mixedReview:
            let average = ProgressStore.averageDifficulty(
                profileId: profileId,
                operations: unlocked,
                context: modelContext
            )
            return PracticeViewModel(
                mode: mode,
                ageGroup: ageGroup,
                difficulty: average,
                mixedOperations: unlocked,
                mixedDifficulty: average
            )
        case .timesTableChallenge:
            return PracticeViewModel(mode: mode, ageGroup: ageGroup, difficulty: 1)
        }
    }

    private func saveRoundIfNeeded(stars: Int, correct: Int, total: Int, viewModel: PracticeViewModel) {
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

        SessionStore.recordSession(
            profileId: profileId,
            mode: mode,
            correct: correct,
            total: total,
            durationSeconds: viewModel.sessionDurationSeconds(),
            missedByOperation: viewModel.missedCounts(),
            operationResults: viewModel.operationResults(),
            context: modelContext
        )

        switch mode {
        case .operation(let operation):
            ProgressStore.recordRound(
                profileId: profileId,
                operation: operation,
                starsEarned: stars,
                correctCount: correct,
                totalQuestions: total,
                context: modelContext
            )
        case .mixedReview:
            ProgressStore.recordMixedRound(
                profileId: profileId,
                results: viewModel.mixedResults(),
                context: modelContext
            )
        case .timesTableChallenge:
            ProgressStore.recordRound(
                profileId: profileId,
                operation: .multiplication,
                starsEarned: stars,
                correctCount: correct,
                totalQuestions: total,
                context: modelContext
            )
        }
    }
}

private struct PictureHelperToggle: View {
    @Binding var isOn: Bool
    let accent: Color

    var body: some View {
        Toggle(isOn: $isOn) {
            Label {
                Text("Show picture helper")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
            } icon: {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundStyle(accent)
            }
        }
        .tint(accent)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.ink.opacity(0.14), lineWidth: 1)
        )
        .colorScheme(.light)
        .accessibilityLabel("Show picture helper")
        .accessibilityValue(isOn ? "On" : "Off")
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
                withAnimation(.default) {
                    offset = -8
                }
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
        PracticeView(mode: .operation(.addition), profileId: UUID(), ageGroup: .early)
    }
    .modelContainer(for: [KidProfile.self, KidProgress.self], inMemory: true)
}
