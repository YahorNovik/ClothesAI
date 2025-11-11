import Foundation
import SwiftUI

// 4-level category system for organizing clothing
enum ClothingCategory: String, Codable, CaseIterable, Identifiable {
    case headwear = "Headwear"
    case tops = "Tops"
    case bottoms = "Bottoms"
    case footwear = "Footwear"
    case outerwear = "Outerwear"
    case accessories = "Accessories"

    var id: String { rawValue }

    // Icon (SF Symbol name or emoji)
    var iconName: String {
        switch self {
        case .headwear: return "baseball.cap.fill"
        case .tops: return "tshirt.fill"
        case .bottoms: return "👖"
        case .footwear: return "shoe.fill"
        case .outerwear: return "jacket.fill"
        case .accessories: return "bag.fill"
        }
    }

    // Check if icon is emoji (not SF Symbol)
    var isEmojiIcon: Bool {
        switch self {
        case .bottoms: return true
        default: return false
        }
    }

    // Color for the icon
    var iconColor: Color {
        switch self {
        case .headwear: return .purple
        case .tops: return .blue
        case .bottoms: return .indigo
        case .footwear: return .brown
        case .outerwear: return .orange
        case .accessories: return .pink
        }
    }

    var displayOrder: Int {
        switch self {
        case .headwear: return 0
        case .outerwear: return 1
        case .tops: return 2
        case .bottoms: return 3
        case .footwear: return 4
        case .accessories: return 5
        }
    }
}

struct ClothingItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: ClothingCategory
    var imageData: Data
    var dateAdded: Date
    var tags: [String]
    var isFavorite: Bool

    init(id: UUID = UUID(), name: String, category: ClothingCategory, imageData: Data, dateAdded: Date = Date(), tags: [String] = [], isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.imageData = imageData
        self.dateAdded = dateAdded
        self.tags = tags
        self.isFavorite = isFavorite
    }

    var image: UIImage? {
        UIImage(data: imageData)
    }
}

struct Outfit: Identifiable, Codable {
    let id: UUID
    var name: String
    var itemIds: [UUID]  // References to clothing items
    var dateCreated: Date
    var isFavorite: Bool
    var notes: String

    init(id: UUID = UUID(), name: String, itemIds: [UUID] = [], dateCreated: Date = Date(), isFavorite: Bool = false, notes: String = "") {
        self.id = id
        self.name = name
        self.itemIds = itemIds
        self.dateCreated = dateCreated
        self.isFavorite = isFavorite
        self.notes = notes
    }
}
