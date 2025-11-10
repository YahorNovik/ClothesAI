import Foundation

enum SubscriptionTier: String, Codable {
    case free = "Free"
    case basic = "Basic"
    case premium = "Premium"
    case unlimited = "Unlimited"

    var maxItems: Int {
        switch self {
        case .free: return 10
        case .basic: return 50
        case .premium: return 200
        case .unlimited: return Int.max
        }
    }

    var maxOutfits: Int {
        switch self {
        case .free: return 5
        case .basic: return 25
        case .premium: return 100
        case .unlimited: return Int.max
        }
    }

    var displayName: String {
        rawValue
    }

    var price: String {
        switch self {
        case .free: return "Free"
        case .basic: return "$2.99/month"
        case .premium: return "$7.99/month"
        case .unlimited: return "$14.99/month"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "Up to \(maxItems) clothing items",
                "Up to \(maxOutfits) outfits",
                "Basic background removal",
                "Photo capture"
            ]
        case .basic:
            return [
                "Up to \(maxItems) clothing items",
                "Up to \(maxOutfits) outfits",
                "Advanced background removal",
                "Cloud backup"
            ]
        case .premium:
            return [
                "Up to \(maxItems) clothing items",
                "Up to \(maxOutfits) outfits",
                "AI-powered outfit suggestions",
                "Weather-based recommendations",
                "Cloud backup"
            ]
        case .unlimited:
            return [
                "Unlimited clothing items",
                "Unlimited outfits",
                "All Premium features",
                "Priority support"
            ]
        }
    }
}
