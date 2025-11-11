import SwiftUI

struct OutfitBuilderView: View {
    @EnvironmentObject var wardrobeManager: WardrobeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var selectedItems: [ClothingCategory: ClothingItem] = [:]
    @State private var outfitName = ""
    @State private var showingSaveSheet = false
    @State private var showingLimitAlert = false
    @State private var showingSuccessAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Your Look")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Select items from each category to build your outfit")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    // Outfit Preview
                    outfitPreview

                    // Category Sections
                    ForEach(ClothingCategory.allCases.sorted(by: { $0.displayOrder < $1.displayOrder })) { category in
                        CategorySection(
                            category: category,
                            items: wardrobeManager.items(for: category),
                            selectedItem: selectedItems[category],
                            onSelect: { item in
                                selectItem(item, for: category)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Outfit Builder")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: clearButton, trailing: saveButton)
            .sheet(isPresented: $showingSaveSheet) {
                SaveOutfitSheet(
                    outfitName: $outfitName,
                    selectedItems: Array(selectedItems.values),
                    onSave: saveOutfit
                )
            }
            .alert("Limit Reached", isPresented: $showingLimitAlert) {
                Button("OK", role: .cancel) {}
                Button("Upgrade") {
                    // Navigate to subscription
                }
            } message: {
                Text("You've reached the maximum number of outfits for your \(subscriptionManager.currentTier.displayName) plan. Upgrade to save more!")
            }
            .alert("Look Saved!", isPresented: $showingSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your outfit '\(outfitName)' has been saved successfully!")
            }
        }
    }

    private var clearButton: some View {
        Button("Clear") {
            selectedItems.removeAll()
        }
        .disabled(selectedItems.isEmpty)
    }

    private var saveButton: some View {
        Button("Save Look") {
            if subscriptionManager.canAddOutfit(currentCount: wardrobeManager.totalOutfits) {
                showingSaveSheet = true
            } else {
                showingLimitAlert = true
            }
        }
        .disabled(selectedItems.isEmpty)
    }

    private var outfitPreview: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.headline)

            if selectedItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tshirt")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No items selected")
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(selectedItems.values)) { item in
                            if let image = item.image {
                                VStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(12)

                                    Image(systemName: item.category.iconName)
                                        .font(.caption)
                                        .foregroundColor(item.category.iconColor)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 140)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
        }
    }

    private func selectItem(_ item: ClothingItem, for category: ClothingCategory) {
        if selectedItems[category]?.id == item.id {
            selectedItems.removeValue(forKey: category)
        } else {
            selectedItems[category] = item
        }
    }

    private func saveOutfit() {
        let outfit = Outfit(
            name: outfitName,
            itemIds: selectedItems.values.map { $0.id }
        )
        wardrobeManager.addOutfit(outfit)
        showingSaveSheet = false
        showingSuccessAlert = true
        selectedItems.removeAll()
        outfitName = ""
    }
}

struct CategorySection: View {
    let category: ClothingCategory
    let items: [ClothingItem]
    let selectedItem: ClothingItem?
    let onSelect: (ClothingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(category.iconColor)
                Text(category.rawValue)
                    .font(.headline)
                Spacer()
                if items.isEmpty {
                    Text("No items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { item in
                            ItemSelectionCard(
                                item: item,
                                isSelected: selectedItem?.id == item.id,
                                onTap: { onSelect(item) }
                            )
                        }
                    }
                }
            }

            Divider()
        }
    }
}

struct ItemSelectionCard: View {
    let item: ClothingItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if let image = item.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                        )
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct SaveOutfitSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var outfitName: String
    let selectedItems: [ClothingItem]
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Outfit Name") {
                    TextField("Enter outfit name", text: $outfitName)
                }

                Section("Items in This Look") {
                    ForEach(selectedItems) { item in
                        HStack {
                            if let image = item.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                            }
                            Text(item.name)
                            Spacer()
                            Image(systemName: item.category.iconName)
                                .foregroundColor(item.category.iconColor)
                        }
                    }
                }

                Section {
                    Button("Save Outfit") {
                        onSave()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(outfitName.isEmpty)
                }
            }
            .navigationTitle("Save Look")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
}

#Preview {
    OutfitBuilderView()
        .environmentObject(WardrobeManager())
        .environmentObject(SubscriptionManager())
}
