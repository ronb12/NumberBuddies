import SwiftData
import SwiftUI

struct ProfilePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \KidProfile.createdAt) private var profiles: [KidProfile]

    @State private var showAddProfile = false

    var body: some View {
        NavigationStack {
            List {
                Section("Switch buddy") {
                    ForEach(profiles, id: \.id) { profile in
                        Button {
                            ProfileStore.setActive(profile)
                            FeedbackService.lightTap()
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.ink)
                                    Text(profile.ageGroup.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if ProfileStore.activeProfileId == profile.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.teal)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showAddProfile = true
                    } label: {
                        Label("Add another buddy", systemImage: "person.badge.plus")
                    }
                }
            }
            .navigationTitle("Buddies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddProfile) {
                AddProfileSheet()
            }
        }
    }
}

struct AddProfileSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedAgeGroup: AgeGroup = .early

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Buddy name", text: $name)
                }

                Section("Age group") {
                    Picker("Age group", selection: $selectedAgeGroup) {
                        ForEach(AgeGroup.allCases) { group in
                            Text(group.title).tag(group)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("New buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addProfile() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addProfile() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ProfileStore.createProfile(name: trimmed, ageGroup: selectedAgeGroup, context: modelContext)
        FeedbackService.lightTap()
        dismiss()
    }
}

#Preview {
    ProfilePickerView()
        .modelContainer(for: [KidProfile.self, KidProgress.self], inMemory: true)
}
