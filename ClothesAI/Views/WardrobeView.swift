import SwiftUI

struct WardrobeView: View {
    @EnvironmentObject var wardrobeManager: WardrobeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedCategory: ClothingCategory?
    @State private var showingAddItem = false
    @State private var showingLimitAlert = false
    @State private var showingDebugMenu = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Subscription status bar
                subscriptionStatusBar

                // Category selector
                categoryScrollView

                // Items grid
                itemsGrid

                Spacer()
            }
            .navigationTitle("My Wardrobe")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button(action: { showingDebugMenu = true }) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.title3)
                },
                trailing: Button(action: addItemTapped) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            )
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
            .alert("Limit Reached", isPresented: $showingLimitAlert) {
                Button("OK", role: .cancel) {}
                Button("Upgrade") {
                    // Navigate to subscription view
                }
            } message: {
                Text("You've reached the maximum number of items for your \(subscriptionManager.currentTier.displayName) plan. Upgrade to add more items!")
            }
            .confirmationDialog("Debug Menu", isPresented: $showingDebugMenu) {
                Button("Add Mock Items (8 items)") {
                    wardrobeManager.addMockItems()
                }
                Button("Clear All Data", role: .destructive) {
                    wardrobeManager.clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Testing & Development Tools")
            }
        }
    }

    private var subscriptionStatusBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(subscriptionManager.currentTier.displayName) Plan")
                    .font(.headline)
                Text("\(wardrobeManager.totalItems) / \(subscriptionManager.currentTier.maxItems == Int.max ? "∞" : "\(subscriptionManager.currentTier.maxItems)") items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private var categoryScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryButton(
                    title: "All",
                    icon: "square.grid.2x2",
                    iconColor: .gray,
                    isSelected: selectedCategory == nil,
                    count: wardrobeManager.totalItems,
                    isEmoji: false
                ) {
                    selectedCategory = nil
                }

                ForEach(ClothingCategory.allCases.sorted(by: { $0.displayOrder < $1.displayOrder })) { category in
                    CategoryButton(
                        title: category.rawValue,
                        icon: category.iconName,
                        iconColor: category.iconColor,
                        isSelected: selectedCategory == category,
                        count: wardrobeManager.items(for: category).count,
                        isEmoji: category.isEmojiIcon
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private var itemsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredItems) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ClothingItemCard(item: item)
                    }
                }
            }
            .padding()
        }
    }

    private var filteredItems: [ClothingItem] {
        if let category = selectedCategory {
            return wardrobeManager.items(for: category)
        }
        return wardrobeManager.clothingItems.sorted { $0.dateAdded > $1.dateAdded }
    }

    private func addItemTapped() {
        if subscriptionManager.canAddItem(currentCount: wardrobeManager.totalItems) {
            showingAddItem = true
        } else {
            showingLimitAlert = true
        }
    }
}

struct CategoryButton: View {
    let title: String
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    let count: Int
    let isEmoji: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    if isEmoji {
                        // Emoji
                        Text(icon)
                            .font(.system(size: 32))
                    } else {
                        // SF Symbol
                        Image(systemName: icon)
                            .font(.system(size: 28))
                            .foregroundColor(isSelected ? .white : iconColor)
                    }

                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 8, y: -8)
                    }
                }
                .frame(width: 60, height: 60)
                .background(isSelected ? iconColor : Color(.systemGray5))
                .clipShape(Circle())

                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? iconColor : .primary)
            }
        }
    }
}

struct ClothingItemCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(spacing: 8) {
            if let image = item.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 120)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }

            Text(item.name)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    WardrobeView()
        .environmentObject(WardrobeManager())
        .environmentObject(SubscriptionManager())
}
