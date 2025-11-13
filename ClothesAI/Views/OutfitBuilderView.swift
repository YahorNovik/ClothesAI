import SwiftUI

struct OutfitBuilderView: View {
    @EnvironmentObject var wardrobeManager: WardrobeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var selectedItems: [ClothingCategory: ClothingItem] = [:]
    @State private var outfitName = ""
    @State private var showingSaveSheet = false
    @State private var showingLimitAlert = false
    @State private var showingSuccessAlert = false
    @State private var selectedCategoryForPicker: ClothingCategory?

    // Ordered categories for mannequin display
    let mannequinOrder: [ClothingCategory] = [.headwear, .outerwear, .tops, .bottoms, .footwear, .accessories]

    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        // Mannequin-style vertical preview
                        mannequinPreview
                            .padding(.top, 20)

                        Spacer(minLength: 80)
                    }
                }

                // Action buttons at bottom
                VStack {
                    Spacer()
                    actionButtons
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 100)
                        )
                }
            }
            .navigationTitle("Look Builder")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: clearButton)
            .sheet(item: $selectedCategoryForPicker) { category in
                ItemPickerSheet(
                    category: category,
                    items: wardrobeManager.items(for: category),
                    selectedItem: selectedItems[category],
                    onSelect: { item in
                        selectItem(item, for: category)
                        selectedCategoryForPicker = nil
                    },
                    onRemove: {
                        selectedItems.removeValue(forKey: category)
                        selectedCategoryForPicker = nil
                    }
                )
            }
            .sheet(isPresented: $showingSaveSheet) {
                SaveOutfitSheet(
                    outfitName: $outfitName,
                    selectedItems: Array(selectedItems.values),
                    onSave: saveOutfit
                )
            }
            .alert("Limit Reached", isPresented: $showingLimitAlert) {
                Button("OK", role: .cancel) {}
                Button("Upgrade") {}
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
            withAnimation {
                selectedItems.removeAll()
            }
        }
        .disabled(selectedItems.isEmpty)
    }

    private var mannequinPreview: some View {
        VStack(spacing: 0) {
            ForEach(mannequinOrder, id: \.self) { category in
                MannequinSlot(
                    category: category,
                    item: selectedItems[category],
                    onTap: {
                        selectedCategoryForPicker = category
                    }
                )
            }
        }
        .frame(maxWidth: 400)
        .padding(.horizontal)
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Shuffle button
            Button {
                shuffleOutfit()
            } label: {
                HStack {
                    Image(systemName: "shuffle")
                    Text("Shuffle")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .disabled(wardrobeManager.totalItems < 2)

            // Save button
            Button {
                if subscriptionManager.canAddOutfit(currentCount: wardrobeManager.totalOutfits) {
                    showingSaveSheet = true
                } else {
                    showingLimitAlert = true
                }
            } label: {
                HStack {
                    Image(systemName: "heart.fill")
                    Text("Save Look")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedItems.isEmpty ? Color(.systemGray4) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(selectedItems.isEmpty)
        }
        .padding(.bottom, 8)
    }

    private func selectItem(_ item: ClothingItem, for category: ClothingCategory) {
        withAnimation(.spring(response: 0.3)) {
            selectedItems[category] = item
        }
    }

    private func shuffleOutfit() {
        withAnimation(.spring(response: 0.5)) {
            selectedItems.removeAll()
            for category in mannequinOrder {
                let items = wardrobeManager.items(for: category)
                if let randomItem = items.randomElement() {
                    selectedItems[category] = randomItem
                }
            }
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

// MARK: - Mannequin Slot

struct MannequinSlot: View {
    let category: ClothingCategory
    let item: ClothingItem?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(item != nil ? Color.clear : Color(.systemGray6))
                    .frame(height: slotHeight)

                if let item = item, let image = item.image {
                    // Item image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: slotHeight)
                        .cornerRadius(16)
                } else {
                    // Empty slot placeholder
                    VStack(spacing: 8) {
                        if category.isEmojiIcon {
                            Text(category.iconName)
                                .font(.system(size: 32))
                        } else {
                            Image(systemName: category.iconName)
                                .font(.system(size: 32))
                                .foregroundColor(category.iconColor)
                        }
                        Text("Add \(category.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Edit indicator
                if item != nil {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 32, height: 32)
                                )
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var slotHeight: CGFloat {
        switch category {
        case .headwear:
            return 100
        case .outerwear:
            return 160
        case .tops:
            return 160
        case .bottoms:
            return 180
        case .footwear:
            return 120
        case .accessories:
            return 80
        }
    }
}

// MARK: - Item Picker Sheet

struct ItemPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    let category: ClothingCategory
    let items: [ClothingItem]
    let selectedItem: ClothingItem?
    let onSelect: (ClothingItem) -> Void
    let onRemove: () -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(items) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            VStack(spacing: 8) {
                                if let image = item.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 120)
                                        .clipped()
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedItem?.id == item.id ? Color.blue : Color.clear, lineWidth: 3)
                                        )
                                }

                                if selectedItem?.id == item.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle(category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: selectedItem != nil ? Button("Remove") {
                    onRemove()
                } : nil
            )
        }
    }
}

// MARK: - Save Outfit Sheet

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
                            if item.category.isEmojiIcon {
                                Text(item.category.iconName)
                            } else {
                                Image(systemName: item.category.iconName)
                                    .foregroundColor(item.category.iconColor)
                            }
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
