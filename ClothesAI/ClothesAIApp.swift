import SwiftUI

@main
struct ClothesAIApp: App {
    @StateObject private var wardrobeManager = WardrobeManager()
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wardrobeManager)
                .environmentObject(subscriptionManager)
        }
    }
}
