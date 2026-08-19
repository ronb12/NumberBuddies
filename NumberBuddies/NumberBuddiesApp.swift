import SwiftData
import SwiftUI

@main
struct NumberBuddiesApp: App {
    private let container: ModelContainer

    init() {
        container = Self.makeModelContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .modelContainer(container)
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([KidProfile.self, KidProgress.self, PracticeSession.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            resetPersistentStore()
            do {
                return try ModelContainer(for: schema, configurations: configuration)
            } catch {
                let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: fallback)
            }
        }
    }

    private static func resetPersistentStore() {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let storeNames = ["default.store", "default.store-shm", "default.store-wal"]
        for name in storeNames {
            let url = support.appendingPathComponent(name)
            try? FileManager.default.removeItem(at: url)
        }
    }
}
