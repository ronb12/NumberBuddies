import SwiftData
import SwiftUI

@main
struct NumberBuddiesApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .modelContainer(for: KidProgress.self)
    }
}
