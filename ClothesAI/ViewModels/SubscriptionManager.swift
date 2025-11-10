import Foundation
import SwiftUI

class SubscriptionManager: ObservableObject {
    @Published var currentTier: SubscriptionTier = .free

    private let tierKey = "subscriptionTier"

    init() {
        loadTier()
    }

    func canAddItem(currentCount: Int) -> Bool {
        currentCount < currentTier.maxItems
    }

    func canAddOutfit(currentCount: Int) -> Bool {
        currentCount < currentTier.maxOutfits
    }

    func upgradeTier(to tier: SubscriptionTier) {
        currentTier = tier
        saveTier()
    }

    func getRemainingItems(currentCount: Int) -> Int {
        if currentTier.maxItems == Int.max {
            return Int.max
        }
        return max(0, currentTier.maxItems - currentCount)
    }

    func getRemainingOutfits(currentCount: Int) -> Int {
        if currentTier.maxOutfits == Int.max {
            return Int.max
        }
        return max(0, currentTier.maxOutfits - currentCount)
    }

    private func saveTier() {
        UserDefaults.standard.set(currentTier.rawValue, forKey: tierKey)
    }

    private func loadTier() {
        if let tierString = UserDefaults.standard.string(forKey: tierKey),
           let tier = SubscriptionTier(rawValue: tierString) {
            currentTier = tier
        }
    }
}
