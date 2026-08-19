import SwiftData
import SwiftUI

@main
struct NumberBuddiesApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: KidProgress.self)
    }
}
