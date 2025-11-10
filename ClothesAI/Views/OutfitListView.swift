import SwiftUI

struct OutfitListView: View {
    @EnvironmentObject var wardrobeManager: WardrobeManager
    @State private var selectedOutfit: Outfit?
    @State private var showingDetail = false

    var body: some View {
        NavigationView {
            Group {
                if wardrobeManager.outfits.isEmpty {
                    emptyState
                } else {
                    outfitsList
                }
            }
            .navigationTitle("My Looks")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedOutfit) { outfit in
            OutfitDetailView(outfit: outfit)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Saved Looks Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first outfit by going to the 'Create Look' tab")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var outfitsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(wardrobeManager.outfits.sorted(by: { $0.dateCreated > $1.dateCreated })) { outfit in
                    OutfitCard(outfit: outfit)
                        .onTapGesture {
                            selectedOutfit = outfit
                        }
                }
            }
            .padding()
        }
    }
}

struct OutfitCard: View {
    @EnvironmentObject var wardrobeManager: WardrobeManager
    let outfit: Outfit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(outfit.name)
                        .font(.headline)

                    Text("\(outfit.itemIds.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: outfit.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(outfit.isFavorite ? .red : .gray)
            }

            // Preview of items
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(wardrobeManager.getItems(for: outfit)) { item in
                        if let image = item.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(8)
                        }
                    }
                }
            }

            HStack {
                Text(outfit.dateCreated, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct OutfitDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var wardrobeManager: WardrobeManager
    @State private var showingDeleteAlert = false

    let outfit: Outfit

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Outfit Preview
                    VStack(spacing: 16) {
                        Text("Your Look")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(wardrobeManager.getItems(for: outfit)) { item in
                                VStack {
                                    if let image = item.image {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 150)
                                            .cornerRadius(12)
                                    }

                                    HStack {
                                        Text(item.category.icon)
                                        Text(item.name)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)

                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(outfit.name)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.secondary)
                                    Text(outfit.dateCreated, style: .date)
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                            }

                            Spacer()

                            Button(action: toggleFavorite) {
                                Image(systemName: outfit.isFavorite ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(outfit.isFavorite ? .red : .gray)
                            }
                        }

                        if !outfit.notes.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.headline)
                                Text(outfit.notes)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        // Actions
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Look")
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
            .navigationTitle("Outfit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Look", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteOutfit()
                }
            } message: {
                Text("Are you sure you want to delete this look? This action cannot be undone.")
            }
        }
    }

    private func toggleFavorite() {
        var updatedOutfit = outfit
        updatedOutfit.isFavorite.toggle()
        wardrobeManager.updateOutfit(updatedOutfit)
    }

    private func deleteOutfit() {
        wardrobeManager.deleteOutfit(outfit)
        dismiss()
    }
}

#Preview {
    OutfitListView()
        .environmentObject(WardrobeManager())
}
