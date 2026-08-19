import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var readAloud = AppSettings.readAloudEnabled
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Practice") {
                    Toggle("Read problems aloud", isOn: $readAloud)
                        .onChange(of: readAloud) { _, newValue in
                            AppSettings.readAloudEnabled = newValue
                            if !newValue {
                                SpeechService.shared.stop()
                            }
                        }
                }

                Section("Progress") {
                    Button("Reset all stars and levels", role: .destructive) {
                        showResetConfirm = true
                    }
                }

                Section {
                    Text("Number Buddies keeps all progress on this device. No accounts or ads.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                "Reset all progress?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset everything", role: .destructive, action: resetProgress)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all stars and difficulty levels. It cannot be undone.")
            }
        }
    }

    private func resetProgress() {
        let items = (try? modelContext.fetch(FetchDescriptor<KidProgress>())) ?? []
        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()
        FeedbackService.lightTap()
    }
}
