import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KidProfile.createdAt) private var profiles: [KidProfile]
    @State private var didMigrate = false
    @State private var onboardingFinished = false

    private var showOnboarding: Bool {
        profiles.isEmpty && !onboardingFinished
    }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    onboardingFinished = true
                }
            } else {
                HomeView()
            }
        }
        .onAppear {
            guard !didMigrate else { return }
            ProfileStore.migrateLegacyProgressIfNeeded(context: modelContext)
            didMigrate = true
            if !profiles.isEmpty {
                onboardingFinished = true
            }
        }
        .onChange(of: profiles.count) { _, count in
            if count > 0 {
                onboardingFinished = true
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [KidProfile.self, KidProgress.self], inMemory: true)
}
