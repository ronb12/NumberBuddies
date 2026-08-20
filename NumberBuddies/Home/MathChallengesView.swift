import SwiftUI

struct MathChallengesView: View {
    let profileId: UUID
    let ageGroup: AgeGroup
    let unlockedOperations: [MathOperation]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(unlockedOperations) { operation in
                    OperationChallengeSection(
                        operation: operation,
                        profileId: profileId,
                        ageGroup: ageGroup
                    )
                }
            }
            .padding(20)
        }
        .background(AppTheme.cream.ignoresSafeArea())
        .navigationTitle("Math Challenges")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct OperationChallengeSection: View {
    let operation: MathOperation
    let profileId: UUID
    let ageGroup: AgeGroup

    private var accent: Color { AppTheme.color(for: operation) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(operation.title, systemImage: operation.iconName)
                .font(.title3.weight(.bold))
                .foregroundStyle(accent)

            NavigationLink {
                OperationChallengesView(
                    operation: operation,
                    profileId: profileId,
                    ageGroup: ageGroup
                )
            } label: {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(operation.title) Challenges")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(operationChallengeSummary)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(16)
                .background(accent, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            }
            .buttonStyle(.plain)
        }
    }

    private var operationChallengeSummary: String {
        switch operation {
        case .addition:
            "Doubles, make 10, and addends 1–12 in order"
        case .subtraction:
            "Subtract 1–12 in order for each set"
        case .multiplication:
            "Times tables 1–12 in order"
        case .division:
            "Division facts 1–12 in order"
        }
    }
}

struct OperationChallengesView: View {
    let operation: MathOperation
    let profileId: UUID
    let ageGroup: AgeGroup

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private var accent: Color { AppTheme.color(for: operation) }

    private var specialChallenges: [MathChallengeKind] {
        MathChallengeGenerator.challenges(for: operation).filter {
            if case .doubles = $0 { return true }
            if case .makeTen = $0 { return true }
            return false
        }
    }

    private var marathon: MathChallengeKind {
        .marathon(operation)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !specialChallenges.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick challenges")
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)
                        ForEach(specialChallenges) { challenge in
                            challengeLink(challenge, style: .special)
                        }
                    }
                }

                challengeLink(marathon, style: .marathon)

                Text("Pick a set")
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 4)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(OrderedTableChallenge.tableRange, id: \.self) { table in
                        let challenge = MathChallengeKind.orderedTable(operation, table)
                        NavigationLink {
                            PracticeView(
                                mode: .mathChallenge(challenge),
                                profileId: profileId,
                                ageGroup: ageGroup
                            )
                        } label: {
                            TableChallengeCard(table: table, operation: operation)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.cream.ignoresSafeArea())
        .navigationTitle("\(operation.title) Challenges")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func challengeLink(_ challenge: MathChallengeKind, style: ChallengeCardStyle) -> some View {
        NavigationLink {
            PracticeView(
                mode: .mathChallenge(challenge),
                profileId: profileId,
                ageGroup: ageGroup
            )
        } label: {
            ChallengeBanner(challenge: challenge, style: style, accent: accent)
        }
        .buttonStyle(.plain)
    }
}

private enum ChallengeCardStyle {
    case marathon
    case special
}

private struct ChallengeBanner: View {
    let challenge: MathChallengeKind
    let style: ChallengeCardStyle
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: challenge.iconName)
                .font(.system(size: style == .marathon ? 28 : 24, weight: .semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(style == .marathon ? .title3.weight(.bold) : .headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(challenge.subtitle)
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
                colors: style == .marathon
                    ? [accent, accent.opacity(0.75)]
                    : [accent.opacity(0.95), accent.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        )
        .accessibilityLabel("\(challenge.title). \(challenge.subtitle)")
    }
}

private struct TableChallengeCard: View {
    let table: Int
    let operation: MathOperation

    var body: some View {
        VStack(spacing: 6) {
            Text("\(table)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(operation.tableCardLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(AppTheme.color(for: operation), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
    }
}

private extension MathOperation {
    var tableCardLabel: String {
        switch self {
        case .addition: "+ 1–12"
        case .subtraction: "− 1–12"
        case .multiplication: "× 1–12"
        case .division: "÷ set"
        }
    }
}

#Preview {
    NavigationStack {
        MathChallengesView(
            profileId: UUID(),
            ageGroup: .upper,
            unlockedOperations: MathOperation.allCases
        )
    }
}
