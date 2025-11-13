import SwiftUI

struct ContentView: View {
    @EnvironmentObject var wardrobeManager: WardrobeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    var body: some View {
        TabView {
            WardrobeView()
                .tabItem {
                    Label("Wardrobe", systemImage: "tshirt.fill")
                }

            EnhancedOutfitBuilderView()
                .tabItem {
                    Label("Create Look", systemImage: "sparkles")
                }

            OutfitListView()
                .tabItem {
                    Label("My Looks", systemImage: "heart.fill")
                }

            SubscriptionView()
                .tabItem {
                    Label("Subscription", systemImage: "star.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WardrobeManager())
        .environmentObject(SubscriptionManager())
}
