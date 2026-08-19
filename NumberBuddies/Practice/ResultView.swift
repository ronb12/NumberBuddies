import SwiftUI

struct ResultView: View {
    let title: String
    let accent: Color
    let stars: Int
    let correct: Int
    let total: Int
    let onPlayAgain: () -> Void
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            MascotView(size: 96)

            Text("Round complete!")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppTheme.ink)

            StarBurst(count: min(stars, 5))

            Text("You got \(correct) out of \(total) correct.")
                .font(.title3)
                .foregroundStyle(AppTheme.ink.opacity(0.75))
                .multilineTextAlignment(.center)

            if title != "Mixed Review" {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(accent)
            }

            VStack(spacing: 12) {
                Button(action: onPlayAgain) {
                    Text("Play again")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.minTapSize)
                        .background(accent, in: RoundedRectangle(cornerRadius: 16))
                }

                Button(action: onHome) {
                    Text("Back home")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.minTapSize)
                        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding(24)
        .onAppear {
            if correct >= total - 1 {
                FeedbackService.correctAnswer()
            } else {
                FeedbackService.lightTap()
            }
        }
    }
}
