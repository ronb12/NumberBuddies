import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let onComplete: () -> Void

    @State private var name = ""
    @State private var selectedAgeGroup: AgeGroup = .early
    @State private var saveError: String?
    @State private var isSaving = false
    @FocusState private var nameFocused: Bool

    var body: some View {
        ZStack {
            PlayfulBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 28) {
                        MascotView(size: horizontalSizeClass == .regular ? 96 : 80)

                        VStack(spacing: 8) {
                            Text("Welcome to Number Buddies!")
                                .font(.system(size: horizontalSizeClass == .regular ? 36 : 28, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.ink)
                                .multilineTextAlignment(.center)

                            Text("Who is practicing today?")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(AppTheme.ink.opacity(0.7))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Buddy name")
                                .font(.headline)
                                .foregroundStyle(AppTheme.ink)

                            TextField(
                                "",
                                text: $name,
                                prompt: Text("Enter a name")
                                    .foregroundStyle(AppTheme.ink.opacity(0.45))
                            )
                            .font(.title3)
                            .foregroundStyle(AppTheme.ink)
                            .tint(AppTheme.teal)
                            .padding(14)
                            .background(.white, in: RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.ink.opacity(0.15), lineWidth: 1)
                            }
                            .focused($nameFocused)
                            .submitLabel(.go)
                            .onSubmit(submitProfile)
                        }
                        .padding(.horizontal, 4)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Age group")
                                .font(.headline)
                                .foregroundStyle(AppTheme.ink)

                            ForEach(AgeGroup.allCases) { group in
                                AgeGroupRow(
                                    group: group,
                                    isSelected: selectedAgeGroup == group
                                ) {
                                    selectedAgeGroup = group
                                    saveError = nil
                                    FeedbackService.lightTap()
                                }
                            }
                        }

                        if let saveError {
                            Text(saveError)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.coral)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                    }
                    .padding(.horizontal, horizontalSizeClass == .regular ? 48 : 24)
                    .padding(.top, 32)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)

                Button(action: submitProfile) {
                    Group {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Start practicing")
                                .font(.title3.weight(.bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.minTapSize)
                    .background(canCreate ? AppTheme.coral : AppTheme.coral.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!canCreate || isSaving)
                .padding(.horizontal, horizontalSizeClass == .regular ? 48 : 24)
                .padding(.vertical, 16)
                .background(AppTheme.cream.opacity(0.95))
            }
        }
        .preferredColorScheme(.light)
    }

    private var canCreate: Bool {
        !trimmedName.isEmpty
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func submitProfile() {
        guard canCreate, !isSaving else { return }
        nameFocused = false
        saveError = nil
        isSaving = true

        let saved = ProfileStore.createProfile(
            name: trimmedName,
            ageGroup: selectedAgeGroup,
            context: modelContext
        )

        isSaving = false

        if saved {
            FeedbackService.correctAnswer()
            onComplete()
        } else {
            saveError = "Could not save your buddy. Please try again."
            FeedbackService.wrongAnswer()
        }
    }
}

private struct AgeGroupRow: View {
    let group: AgeGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? AppTheme.teal : AppTheme.ink.opacity(0.35))

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(group.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.ink.opacity(0.65))
                }

                Spacer()
            }
            .padding(16)
            .background(.white.opacity(isSelected ? 0.95 : 0.75), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppTheme.teal : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: [KidProfile.self, KidProgress.self], inMemory: true)
}
