import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \KidProfile.createdAt) private var profiles: [KidProfile]

    @State private var readAloud = AppSettings.readAloudEnabled
    @State private var showResetConfirm = false
    @State private var showParentReport = false
    @State private var showProfilePicker = false
    @State private var selectedAgeGroup: AgeGroup = .early

    private var activeProfile: KidProfile? {
        ProfileStore.activeProfile(context: modelContext) ?? profiles.first
    }

    var body: some View {
        NavigationStack {
            Form {
                if let profile = activeProfile {
                    Section {
                        LabeledContent("Name", value: profile.name)
                        Picker("Grade level", selection: $selectedAgeGroup) {
                            ForEach(AgeGroup.allCases) { group in
                                Text(group.title).tag(group)
                            }
                        }
                        .onChange(of: selectedAgeGroup) { _, newValue in
                            ProfileStore.updateAgeGroup(
                                for: profile,
                                to: newValue,
                                context: modelContext
                            )
                            FeedbackService.lightTap()
                        }
                        Button("Switch or add buddy") {
                            showProfilePicker = true
                        }
                    } footer: {
                        Text(selectedAgeGroup.subtitle)
                    }
                }

                Section("Practice") {
                    Toggle("Read problems aloud", isOn: $readAloud)
                        .onChange(of: readAloud) { _, newValue in
                            AppSettings.readAloudEnabled = newValue
                            if !newValue {
                                SpeechService.shared.stop()
                            }
                        }
                }

                Section("Family") {
                    Button("Progress report") {
                        showParentReport = true
                    }
                    .disabled(activeProfile == nil)
                }

                Section("Progress") {
                    Button("Reset stars and levels for this buddy", role: .destructive) {
                        showResetConfirm = true
                    }
                    .disabled(activeProfile == nil)
                }

                Section {
                    Text("Number Buddies keeps all progress on this device. No accounts or ads.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    LabeledContent("Created by", value: "Ronell Bradley")
                    LabeledContent("Property of", value: "Bradley Virtual Solutions, LLC")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Reset progress for \(activeProfile?.name ?? "this buddy")?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset progress", role: .destructive, action: resetProgress)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes stars and difficulty levels for the active buddy only.")
            }
            .sheet(isPresented: $showParentReport) {
                if let profile = activeProfile {
                    ParentReportView(profile: profile)
                }
            }
            .sheet(isPresented: $showProfilePicker) {
                ProfilePickerView()
            }
            .onAppear {
                syncSelectedAgeGroup()
            }
            .onChange(of: activeProfile?.id) { _, _ in
                syncSelectedAgeGroup()
            }
        }
    }

    private func syncSelectedAgeGroup() {
        if let profile = activeProfile {
            selectedAgeGroup = profile.ageGroup
        }
    }

    private func resetProgress() {
        guard let profile = activeProfile else { return }
        ProfileStore.resetProfileProgress(profileId: profile.id, context: modelContext)
        FeedbackService.lightTap()
    }
}
