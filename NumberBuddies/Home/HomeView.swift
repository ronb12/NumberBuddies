import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \KidProgress.operationRaw) private var progressItems: [KidProgress]
    @Query(sort: \KidProfile.createdAt) private var profiles: [KidProfile]

    @State private var showSettings = false
    @State private var showProfilePicker = false
    @AppStorage("activeProfileId") private var activeProfileIdRaw = ""

    private var activeProfile: KidProfile? {
        if let id = UUID(uuidString: activeProfileIdRaw) {
            return ProfileStore.profile(with: id, context: modelContext) ?? profiles.first
        }
        return ProfileStore.activeProfile(context: modelContext) ?? profiles.first
    }

    private var profileProgress: [KidProgress] {
        guard let profile = activeProfile else { return [] }
        let key = profile.id.uuidString
        return progressItems.filter { $0.profileId == key }
    }

    private var totalStars: Int {
        profileProgress.reduce(0) { $0 + $1.stars }
    }

    private var unlockedOperations: [MathOperation] {
        guard let profile = activeProfile else { return MathOperation.allCases }
        return ProgressStore.unlockedOperations(for: profile, context: modelContext)
    }

    private var homeOperations: [MathOperation] {
        activeProfile?.ageGroup.homeOperations ?? MathOperation.allCases
    }

    private var showsMixedReview: Bool {
        unlockedOperations.count >= 3
    }

    private var showsTimesTableChallenges: Bool {
        unlockedOperations.contains(.multiplication)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PlayfulBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        if showsMixedReview {
                            mixedReviewCard
                        }
                        if showsTimesTableChallenges {
                            timesTableChallengesCard
                        }
                        operationGrid
                    }
                    .padding(.horizontal, horizontalSizeClass == .regular ? 48 : 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showProfilePicker) {
                ProfilePickerView()
            }
            .onAppear {
                ProfileStore.migrateLegacyProgressIfNeeded(context: modelContext)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                MascotView(size: horizontalSizeClass == .regular ? 88 : 56)
                Spacer(minLength: 0)
                headerActions
            }

            Text("Number Buddies")
                .font(.system(size: horizontalSizeClass == .regular ? 40 : 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let profile = activeProfile {
                Text("Hi, \(profile.name)!")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.ink.opacity(0.7))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Text(profile.ageGroup.subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.ink.opacity(0.55))
                    .lineLimit(2)
            } else {
                Text("Let's practice math!")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.ink.opacity(0.7))
                    .minimumScaleFactor(0.8)
            }

            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(AppTheme.sunny)
                    Text("\(totalStars) stars")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.white.opacity(0.85), in: Capsule())

                if let profile = activeProfile, profile.dailyStreak > 0 {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(AppTheme.coral)
                        Text("\(profile.dailyStreak) day streak")
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.85), in: Capsule())
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var headerActions: some View {
        HStack(spacing: 6) {
            Button {
                showProfilePicker = true
            } label: {
                Image(systemName: "person.2.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.ink.opacity(0.65))
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.9), in: Circle())
            }
            .accessibilityLabel("Switch buddy")

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.ink.opacity(0.65))
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.9), in: Circle())
            }
            .accessibilityLabel("Settings")
        }
    }

    private var timesTableChallengesCard: some View {
        Group {
            if let profile = activeProfile {
                NavigationLink {
                    TimesTableChallengesView(
                        profileId: profile.id,
                        ageGroup: profile.ageGroup
                    )
                } label: {
                    TimesTableChallengeHomeCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var mixedReviewCard: some View {
        Group {
            if let profile = activeProfile {
                NavigationLink {
                    PracticeView(
                        mode: .mixedReview,
                        profileId: profile.id,
                        ageGroup: profile.ageGroup
                    )
                } label: {
                    MixedReviewCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var operationGrid: some View {
        let columns = horizontalSizeClass == .regular
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(homeOperations) { operation in
                if let profile = activeProfile {
                    let isUnlocked = unlockedOperations.contains(operation)
                    Group {
                        if isUnlocked {
                            NavigationLink {
                                PracticeView(
                                    mode: .operation(operation),
                                    profileId: profile.id,
                                    ageGroup: profile.ageGroup
                                )
                            } label: {
                                OperationCard(
                                    operation: operation,
                                    stars: stars(for: operation),
                                    difficulty: difficulty(for: operation)
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            OperationCard(
                                operation: operation,
                                stars: 0,
                                difficulty: 1,
                                isLocked: true,
                                lockMessage: "Master +/− within 20 first"
                            )
                        }
                    }
                }
            }
        }
    }

    private func stars(for operation: MathOperation) -> Int {
        profileProgress.first(where: { $0.operationRaw == operation.rawValue })?.stars ?? 0
    }

    private func difficulty(for operation: MathOperation) -> Int {
        profileProgress.first(where: { $0.operationRaw == operation.rawValue })?.difficulty ?? 1
    }
}

struct TimesTableChallengeHomeCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "tablecells")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Times Table Challenges")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Tables 1–12 in order")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize * 1.5, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppTheme.sunny, AppTheme.coral.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        )
        .shadow(color: AppTheme.sunny.opacity(0.25), radius: 8, y: 4)
        .accessibilityLabel("Times Table Challenges. Practice multiplication tables 1 through 12 in order.")
    }
}

struct MixedReviewCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "shuffle")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Mixed Review")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("All operations in one round")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize * 1.5, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppTheme.purple, AppTheme.teal.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        )
        .shadow(color: AppTheme.purple.opacity(0.25), radius: 8, y: 4)
        .accessibilityLabel("Mixed Review. All operations in one round.")
        .accessibilityHint("Starts a practice round with addition, subtraction, multiplication, and division.")
    }
}

struct OperationCard: View {
    let operation: MathOperation
    let stars: Int
    let difficulty: Int
    var isLocked: Bool = false
    var lockMessage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isLocked ? "lock.fill" : operation.iconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white.opacity(isLocked ? 0.75 : 1))
                    .accessibilityHidden(true)
                Spacer()
                if !isLocked {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(AppTheme.sunny)
                                .font(.caption)
                            Text("\(stars)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.95))
                        }
                        Text("Level \(difficulty)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.2), in: Capsule())
                    }
                }
            }

            Text(operation.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white.opacity(isLocked ? 0.85 : 1))
                .minimumScaleFactor(0.8)

            Text(isLocked ? lockMessage : "Tap to play")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: AppTheme.minTapSize * 2, alignment: .leading)
        .background(
            AppTheme.color(for: operation).opacity(isLocked ? 0.45 : 1),
            in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        )
        .shadow(color: AppTheme.color(for: operation).opacity(isLocked ? 0.1 : 0.25), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isLocked ? "\(operation.title). Locked. \(lockMessage)" : "\(operation.title). Level \(difficulty). \(stars) stars earned.")
        .accessibilityHint(isLocked ? "Complete addition and subtraction practice first." : operation.accessibilityHint)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [KidProfile.self, KidProgress.self], inMemory: true)
}
