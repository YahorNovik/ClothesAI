import SwiftUI

struct ItemDetailView: View {
    @EnvironmentObject var wardrobeManager: WardrobeManager
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false

    let item: ClothingItem

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image
                if let image = item.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(16)
                        .shadow(radius: 5)
                }

                // Details
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            HStack {
                                Text(item.category.icon)
                                Text(item.category.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button(action: toggleFavorite) {
                            Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(item.isFavorite ? .red : .gray)
                        }
                    }

                    Divider()

                    // Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            Text("Added:")
                            Text(item.dateAdded, style: .date)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }

                    Divider()

                    // Actions
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Item")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }

    private func toggleFavorite() {
        var updatedItem = item
        updatedItem.isFavorite.toggle()
        wardrobeManager.updateClothingItem(updatedItem)
    }

    private func deleteItem() {
        wardrobeManager.deleteClothingItem(item)
        dismiss()
    }
}
