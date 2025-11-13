import Foundation
import SwiftUI
import Combine

class WardrobeManager: ObservableObject {
    @Published var clothingItems: [ClothingItem] = []
    @Published var outfits: [Outfit] = []

    private let itemsKey = "clothingItems"
    private let outfitsKey = "outfits"

    init() {
        loadData()
    }

    // MARK: - Clothing Items Management

    func addClothingItem(_ item: ClothingItem) {
        clothingItems.append(item)
        saveData()
    }

    func deleteClothingItem(_ item: ClothingItem) {
        clothingItems.removeAll { $0.id == item.id }
        // Also remove from outfits
        outfits = outfits.map { outfit in
            var updatedOutfit = outfit
            updatedOutfit.itemIds.removeAll { $0 == item.id }
            return updatedOutfit
        }
        saveData()
    }

    func updateClothingItem(_ item: ClothingItem) {
        if let index = clothingItems.firstIndex(where: { $0.id == item.id }) {
            clothingItems[index] = item
            saveData()
        }
    }

    func items(for category: ClothingCategory) -> [ClothingItem] {
        clothingItems.filter { $0.category == category }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    func item(withId id: UUID) -> ClothingItem? {
        clothingItems.first { $0.id == id }
    }

    // MARK: - Outfits Management

    func addOutfit(_ outfit: Outfit) {
        outfits.append(outfit)
        saveData()
    }

    func deleteOutfit(_ outfit: Outfit) {
        outfits.removeAll { $0.id == outfit.id }
        saveData()
    }

    func updateOutfit(_ outfit: Outfit) {
        if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
            outfits[index] = outfit
            saveData()
        }
    }

    func getItems(for outfit: Outfit) -> [ClothingItem] {
        outfit.itemIds.compactMap { id in
            item(withId: id)
        }
    }

    // MARK: - Data Persistence

    private func saveData() {
        do {
            let itemsData = try JSONEncoder().encode(clothingItems)
            let outfitsData = try JSONEncoder().encode(outfits)

            UserDefaults.standard.set(itemsData, forKey: itemsKey)
            UserDefaults.standard.set(outfitsData, forKey: outfitsKey)
        } catch {
            print("Failed to save data: \(error)")
        }
    }

    private func loadData() {
        if let itemsData = UserDefaults.standard.data(forKey: itemsKey),
           let items = try? JSONDecoder().decode([ClothingItem].self, from: itemsData) {
            self.clothingItems = items
        }

        if let outfitsData = UserDefaults.standard.data(forKey: outfitsKey),
           let outfits = try? JSONDecoder().decode([Outfit].self, from: outfitsData) {
            self.outfits = outfits
        }
    }

    // MARK: - Statistics

    var totalItems: Int {
        clothingItems.count
    }

    var totalOutfits: Int {
        outfits.count
    }

    var itemsByCategory: [ClothingCategory: Int] {
        Dictionary(grouping: clothingItems, by: { $0.category })
            .mapValues { $0.count }
    }

    // MARK: - Mock Data for Testing

    func addMockItems() {
        // Create mock clothing items with simple colored images
        let mockItems: [(String, ClothingCategory, UIColor)] = [
            ("White T-Shirt", .tops, .white),
            ("Black T-Shirt", .tops, .black),
            ("Blue Jeans", .bottoms, .systemBlue),
            ("Black Pants", .bottoms, .darkGray),
            ("Sneakers", .footwear, .systemGray),
            ("Brown Boots", .footwear, .brown),
            ("Denim Jacket", .outerwear, .systemIndigo),
            ("Baseball Cap", .headwear, .systemRed),
        ]

        for (name, category, color) in mockItems {
            if let imageData = createMockImage(color: color) {
                let item = ClothingItem(
                    name: name,
                    category: category,
                    imageData: imageData
                )
                clothingItems.append(item)
            }
        }

        saveData()
        print("✅ Added \(mockItems.count) mock items for testing")
    }

    private func createMockImage(color: UIColor) -> Data? {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Colored rectangle in center (representing clothing item)
            color.setFill()
            let rect = CGRect(x: 50, y: 50, width: 300, height: 300)
            context.fill(rect)

            // Add a subtle border
            UIColor.gray.setStroke()
            context.stroke(rect, width: 2)
        }

        return image.jpegData(compressionQuality: 0.8)
    }

    func clearAllData() {
        clothingItems.removeAll()
        outfits.removeAll()
        saveData()
        print("🗑️ Cleared all wardrobe data")
    }
}
