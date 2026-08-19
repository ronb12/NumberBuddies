import SwiftData
import SwiftUI

struct PracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let operation: MathOperation

    @State private var viewModel: PracticeViewModel?
    @State private var didSaveRound = false

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
                Text(operation.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.color(for: operation))
            }
        }
        .task {
            if viewModel == nil {
                let difficulty = ProgressStore.difficulty(for: operation, context: modelContext)
                viewModel = PracticeViewModel(operation: operation, difficulty: difficulty)
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
            ResultView(
                operation: operation,
                stars: stars,
                correct: correct,
                total: total,
                onPlayAgain: {
                    didSaveRound = false
                    let difficulty = ProgressStore.difficulty(for: operation, context: modelContext)
                    self.viewModel = PracticeViewModel(operation: operation, difficulty: difficulty)
                },
                onHome: { dismiss() }
            )
            .onAppear {
                saveRoundIfNeeded(stars: stars, correct: correct)
            }
        }
    }

    @ViewBuilder
    private func playingView(_ viewModel: PracticeViewModel) -> some View {
        if let problem = viewModel.currentProblem {
            Group {
                if horizontalSizeClass == .regular {
                    HStack(alignment: .top, spacing: 32) {
                        visualSection(problem: problem, viewModel: viewModel)
                            .frame(maxWidth: .infinity)
                        controlSection(problem: problem, viewModel: viewModel)
                            .frame(maxWidth: 420)
                    }
                    .padding(32)
                } else {
                    VStack(spacing: 20) {
                        visualSection(problem: problem, viewModel: viewModel)
                        controlSection(problem: problem, viewModel: viewModel)
                    }
                    .padding(20)
                }
            }
            .onChange(of: viewModel.currentIndex) { _, _ in
                SpeechService.shared.speak(problem.spokenText)
            }
            .onAppear {
                SpeechService.shared.speak(problem.spokenText)
            }
        }
    }

    @ViewBuilder
    private func visualSection(problem: MathProblem, viewModel: PracticeViewModel) -> some View {
        VStack(spacing: 16) {
            Text(viewModel.progressText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink.opacity(0.6))

            Text(problem.prompt)
                .font(.system(size: horizontalSizeClass == .regular ? 48 : 40, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
                .accessibilityLabel(problem.spokenText)

            Toggle("Show picture helper", isOn: Bindable(viewModel).showVisual)
                .font(.subheadline.weight(.medium))
                .tint(AppTheme.color(for: operation))
                .padding(.horizontal, 4)

            if viewModel.showVisual || viewModel.showHint {
                ProblemVisualView(problem: problem)
                    .transition(.opacity)
            }

            if let message = viewModel.feedbackMessage {
                Text(message)
                    .font(.headline)
                    .foregroundStyle(viewModel.showHint ? AppTheme.coral : AppTheme.teal)
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func controlSection(problem: MathProblem, viewModel: PracticeViewModel) -> some View {
        NumberPadView(
            input: Bindable(viewModel).input,
            onSubmit: { viewModel.submit() },
            onClear: { viewModel.clearInput() },
            accent: AppTheme.color(for: operation)
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

    private func saveRoundIfNeeded(stars: Int, correct: Int) {
        guard !didSaveRound else { return }
        didSaveRound = true
        ProgressStore.recordRound(
            operation: operation,
            starsEarned: stars,
            correctCount: correct,
            context: modelContext
        )
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
        PracticeView(operation: .addition)
    }
    .modelContainer(for: KidProgress.self, inMemory: true)
}
