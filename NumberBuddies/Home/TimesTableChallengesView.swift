import SwiftUI

struct TimesTableChallengesView: View {
    let profileId: UUID
    let ageGroup: AgeGroup

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                marathonCard

                Text("Pick a table")
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 4)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(TimesTableChallengeKind.allTables) { challenge in
                        NavigationLink {
                            PracticeView(
                                mode: .timesTableChallenge(challenge),
                                profileId: profileId,
                                ageGroup: ageGroup
                            )
                        } label: {
                            TimesTableCard(challenge: challenge)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.cream.ignoresSafeArea())
        .navigationTitle("Times Table Challenges")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var marathonCard: some View {
        NavigationLink {
            PracticeView(
                mode: .timesTableChallenge(.marathon),
                profileId: profileId,
                ageGroup: ageGroup
            )
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tables 1–12 Marathon")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("144 facts in order · 1×1 through 12×12")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [AppTheme.sunny, AppTheme.coral.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tables 1 through 12 marathon. One hundred forty four facts in order.")
    }
}

private struct TimesTableCard: View {
    let challenge: TimesTableChallengeKind

    var body: some View {
        VStack(spacing: 6) {
            if case .table(let value) = challenge {
                Text("\(value)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("× 1–12")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(AppTheme.sunny, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
        .accessibilityLabel("\(challenge.title). \(challenge.subtitle)")
    }
}

#Preview {
    NavigationStack {
        TimesTableChallengesView(profileId: UUID(), ageGroup: .upper)
    }
}
