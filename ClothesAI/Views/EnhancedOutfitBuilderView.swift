import SwiftUI

// MARK: - Enhanced Outfit Builder with Mannequin-Style Preview

struct EnhancedOutfitBuilderView: View {
    @EnvironmentObject var wardrobeManager: WardrobeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var selectedItems: [ClothingCategory: ClothingItem] = [:]
    @State private var outfitName = ""
    @State private var outfitOccasion = "Casual"
    @State private var outfitNotes = ""
    @State private var showingSaveSheet = false
    @State private var showingLimitAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingTemplates = false
    @State private var selectedCategory: ClothingCategory?

    // View mode toggle
    @State private var viewMode: ViewMode = .preview

    enum ViewMode {
        case preview // Large preview with sidebar
        case grid    // Grid selection
    }

    private let occasions = ["Casual", "Formal", "Business", "Athletic", "Party", "Date Night", "Travel"]

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                if geometry.size.width > 700 {
                    // iPad / Wide layout - Split view
                    splitViewLayout
                } else {
                    // iPhone layout - Tabbed view
                    phoneLayout
                }
            }
            .navigationTitle("Create Your Look")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    clearButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        templatesButton
                        saveButton
                    }
                }
            }
            .sheet(isPresented: $showingSaveSheet) {
                EnhancedSaveOutfitSheet(
                    outfitName: $outfitName,
                    outfitOccasion: $outfitOccasion,
                    outfitNotes: $outfitNotes,
                    selectedItems: Array(selectedItems.values),
                    occasions: occasions,
                    onSave: saveOutfit
                )
            }
            .sheet(isPresented: $showingTemplates) {
                OutfitTemplatesSheet(
                    wardrobeManager: wardrobeManager,
                    onSelectTemplate: applyTemplate
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

    // MARK: - Split View Layout (iPad)

    private var splitViewLayout: some View {
        HStack(spacing: 0) {
            // Left: Large Mannequin-Style Preview
            mannequinPreviewPanel
                .frame(maxWidth: 400)
                .background(Color(.systemGroupedBackground))

            Divider()

            // Right: Item Selection
            itemSelectionPanel
        }
    }

    // MARK: - Phone Layout

    private var phoneLayout: some View {
        VStack(spacing: 0) {
            // Mode Picker
            Picker("View", selection: $viewMode) {
                Text("Preview").tag(ViewMode.preview)
                Text("Select Items").tag(ViewMode.grid)
            }
            .pickerStyle(.segmented)
            .padding()

            if viewMode == .preview {
                mannequinPreviewPanel
            } else {
                itemSelectionPanel
            }
        }
    }

    // MARK: - Mannequin-Style Preview Panel

    private var mannequinPreviewPanel: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)

                    Text("Your Look")
                        .font(.title2)
                        .fontWeight(.bold)

                    if !selectedItems.isEmpty {
                        Text("\(selectedItems.count) item\(selectedItems.count == 1 ? "" : "s") selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                // Mannequin-Style Outfit Display
                if selectedItems.isEmpty {
                    emptyPreview
                } else {
                    mannequinOutfitDisplay
                }

                // Quick Actions
                if !selectedItems.isEmpty {
                    quickActionsPanel
                }
            }
            .padding()
        }
    }

    private var emptyPreview: some View {
        VStack(spacing: 20) {
            ZStack {
                // Simple mannequin outline
                VStack(spacing: 4) {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 50, height: 50)

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 120, height: 140)

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 100, height: 120)

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 60)
                }
            }
            .frame(maxWidth: 300)
            .padding(.vertical, 40)

            Text("Select items to build your outfit")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                withAnimation {
                    viewMode = .grid
                }
            } label: {
                Label("Browse Wardrobe", systemImage: "square.grid.2x2")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }

    private var mannequinOutfitDisplay: some View {
        VStack(spacing: 16) {
            // Display items in wearing order (top to bottom)
            ForEach(ClothingCategory.allCases.sorted(by: { $0.displayOrder < $1.displayOrder })) { category in
                if let item = selectedItems[category] {
                    MannequinItemCard(
                        item: item,
                        category: category,
                        onRemove: {
                            withAnimation {
                                selectedItems.removeValue(forKey: category)
                            }
                        },
                        onSwap: {
                            selectedCategory = category
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Quick Actions Panel

    private var quickActionsPanel: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "arrow.2.squarepath",
                    title: "Shuffle",
                    action: shuffleOutfit
                )

                QuickActionButton(
                    icon: "wand.and.stars",
                    title: "Suggest",
                    action: suggestOutfit
                )

                QuickActionButton(
                    icon: "square.on.square",
                    title: "Duplicate",
                    action: duplicateOutfit
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Item Selection Panel

    private var itemSelectionPanel: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(ClothingCategory.allCases.sorted(by: { $0.displayOrder < $1.displayOrder })) { category in
                    CategorySelectionSection(
                        category: category,
                        items: wardrobeManager.items(for: category),
                        selectedItem: selectedItems[category],
                        onSelect: { item in
                            withAnimation {
                                selectItem(item, for: category)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Toolbar Buttons

    private var clearButton: some View {
        Button {
            withAnimation {
                selectedItems.removeAll()
            }
        } label: {
            Label("Clear", systemImage: "trash")
        }
        .disabled(selectedItems.isEmpty)
    }

    private var templatesButton: some View {
        Button {
            showingTemplates = true
        } label: {
            Image(systemName: "sparkles")
        }
    }

    private var saveButton: some View {
        Button {
            if subscriptionManager.canAddOutfit(currentCount: wardrobeManager.totalOutfits) {
                showingSaveSheet = true
            } else {
                showingLimitAlert = true
            }
        } label: {
            Label("Save", systemImage: "heart.fill")
                .fontWeight(.semibold)
        }
        .disabled(selectedItems.isEmpty)
    }

    // MARK: - Helper Functions

    private func selectItem(_ item: ClothingItem, for category: ClothingCategory) {
        if selectedItems[category]?.id == item.id {
            selectedItems.removeValue(forKey: category)
        } else {
            selectedItems[category] = item
        }

        // Auto-switch to preview after selection on phone
        if viewMode == .grid {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    viewMode = .preview
                }
            }
        }
    }

    private func saveOutfit() {
        let outfit = Outfit(
            name: outfitName,
            itemIds: selectedItems.values.map { $0.id },
            notes: outfitNotes.isEmpty ? outfitOccasion : "\(outfitOccasion): \(outfitNotes)"
        )
        wardrobeManager.addOutfit(outfit)
        showingSaveSheet = false
        showingSuccessAlert = true
        selectedItems.removeAll()
        outfitName = ""
        outfitOccasion = "Casual"
        outfitNotes = ""
    }

    private func shuffleOutfit() {
        var newSelection: [ClothingCategory: ClothingItem] = [:]

        for category in ClothingCategory.allCases {
            let items = wardrobeManager.items(for: category)
            if let randomItem = items.randomElement() {
                newSelection[category] = randomItem
            }
        }

        withAnimation {
            selectedItems = newSelection
        }
    }

    private func suggestOutfit() {
        // Smart suggestion based on color coordination
        var newSelection: [ClothingCategory: ClothingItem] = [:]

        // Start with a random top
        if let top = wardrobeManager.items(for: .tops).randomElement() {
            newSelection[.tops] = top

            // Match bottoms
            if let bottom = wardrobeManager.items(for: .bottoms).randomElement() {
                newSelection[.bottoms] = bottom
            }

            // Add shoes
            if let shoes = wardrobeManager.items(for: .footwear).randomElement() {
                newSelection[.footwear] = shoes
            }
        }

        withAnimation {
            selectedItems = newSelection
        }
    }

    private func duplicateOutfit() {
        // Keep current selection but prepare for new save
        showingSaveSheet = true
        outfitName = ""
    }

    private func applyTemplate(_ template: OutfitTemplate) {
        var newSelection: [ClothingCategory: ClothingItem] = [:]

        for category in template.requiredCategories {
            if let item = wardrobeManager.items(for: category).randomElement() {
                newSelection[category] = item
            }
        }

        withAnimation {
            selectedItems = newSelection
        }
        showingTemplates = false
    }
}

// MARK: - Mannequin Item Card

struct MannequinItemCard: View {
    let item: ClothingItem
    let category: ClothingCategory
    let onRemove: () -> Void
    let onSwap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            VStack {
                if category.isEmojiIcon {
                    Text(category.iconName)
                        .font(.title2)
                } else {
                    Image(systemName: category.iconName)
                        .font(.title2)
                        .foregroundColor(category.iconColor)
                }

                Text(category.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)

            // Item Image
            if let image = item.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }

            Spacer()

            // Actions
            VStack(spacing: 8) {
                Button {
                    onSwap()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .frame(width: 36, height: 36)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }

                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Category Selection Section

struct CategorySelectionSection: View {
    let category: ClothingCategory
    let items: [ClothingItem]
    let selectedItem: ClothingItem?
    let onSelect: (ClothingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if category.isEmojiIcon {
                    Text(category.iconName)
                        .font(.title3)
                } else {
                    Image(systemName: category.iconName)
                        .font(.title3)
                        .foregroundColor(category.iconColor)
                }

                Text(category.rawValue)
                    .font(.headline)

                Spacer()

                Text("\(items.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }

            if items.isEmpty {
                EmptyCategoryPlaceholder(category: category)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(items) { item in
                            EnhancedItemCard(
                                item: item,
                                isSelected: selectedItem?.id == item.id,
                                onTap: { onSelect(item) }
                            )
                        }
                    }
                }
                .frame(height: 120)
            }

            Divider()
        }
    }
}

// MARK: - Enhanced Item Card

struct EnhancedItemCard: View {
    let item: ClothingItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                if let image = item.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: Color.black.opacity(isSelected ? 0.2 : 0.1), radius: 5, x: 0, y: 2)
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white))
                        .font(.title3)
                        .offset(x: -4, y: 4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty Category Placeholder

struct EmptyCategoryPlaceholder: View {
    let category: ClothingCategory

    var body: some View {
        HStack {
            Image(systemName: "plus.circle")
                .foregroundColor(.secondary)

            Text("No \(category.rawValue.lowercased()) yet")
                .foregroundColor(.secondary)
                .font(.subheadline)

            Spacer()

            Button {
                // Navigate to add item
            } label: {
                Text("Add")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Save Outfit Sheet

struct EnhancedSaveOutfitSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var outfitName: String
    @Binding var outfitOccasion: String
    @Binding var outfitNotes: String
    let selectedItems: [ClothingItem]
    let occasions: [String]
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Outfit Details") {
                    TextField("Name your look", text: $outfitName)

                    Picker("Occasion", selection: $outfitOccasion) {
                        ForEach(occasions, id: \.self) { occasion in
                            Text(occasion).tag(occasion)
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $outfitNotes)
                        .frame(height: 100)
                }

                Section("Items (\(selectedItems.count))") {
                    ForEach(selectedItems) { item in
                        HStack {
                            if let image = item.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)

                                Text(item.category.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

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
                    Button {
                        onSave()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Save Look", systemImage: "heart.fill")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(outfitName.isEmpty)
                }
            }
            .navigationTitle("Save Your Look")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Outfit Templates Sheet

struct OutfitTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let requiredCategories: [ClothingCategory]
}

struct OutfitTemplatesSheet: View {
    @Environment(\.dismiss) var dismiss
    let wardrobeManager: WardrobeManager
    let onSelectTemplate: (OutfitTemplate) -> Void

    private let templates: [OutfitTemplate] = [
        OutfitTemplate(
            name: "Casual Day",
            description: "Top + Jeans + Sneakers",
            icon: "tshirt.fill",
            requiredCategories: [.tops, .bottoms, .footwear]
        ),
        OutfitTemplate(
            name: "Business Formal",
            description: "Top + Bottoms + Shoes + Outerwear",
            icon: "bag.fill",
            requiredCategories: [.tops, .bottoms, .footwear, .outerwear]
        ),
        OutfitTemplate(
            name: "Athletic",
            description: "Top + Bottoms + Sneakers",
            icon: "figure.run",
            requiredCategories: [.tops, .bottoms, .footwear]
        ),
        OutfitTemplate(
            name: "Complete Look",
            description: "Full outfit with all categories",
            icon: "person.fill",
            requiredCategories: ClothingCategory.allCases
        ),
        OutfitTemplate(
            name: "Layered",
            description: "Top + Outerwear + Bottoms + Shoes",
            icon: "square.stack.fill",
            requiredCategories: [.tops, .outerwear, .bottoms, .footwear]
        ),
        OutfitTemplate(
            name: "Summer Casual",
            description: "Top + Bottoms + Accessories",
            icon: "sun.max.fill",
            requiredCategories: [.tops, .bottoms, .accessories]
        )
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(templates) { template in
                        TemplateCard(template: template) {
                            onSelectTemplate(template)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Outfit Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TemplateCard: View {
    let template: OutfitTemplate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: template.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text("\(template.requiredCategories.count) items")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    EnhancedOutfitBuilderView()
        .environmentObject(WardrobeManager())
        .environmentObject(SubscriptionManager())
}
