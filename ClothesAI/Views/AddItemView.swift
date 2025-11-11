import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var wardrobeManager: WardrobeManager
    @StateObject private var cameraService = CameraService()

    @State private var itemName = ""
    @State private var selectedCategory: ClothingCategory = .tops
    @State private var capturedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isProcessing = false
    @State private var showingSourceSelection = false

    var body: some View {
        NavigationView {
            Form {
                Section("Photo") {
                    if let image = processedImage ?? capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                    } else {
                        Button(action: { showingSourceSelection = true }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take or Choose Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }

                    if capturedImage != nil {
                        HStack {
                            Button("Retake") {
                                capturedImage = nil
                                processedImage = nil
                                showingSourceSelection = true
                            }
                            .foregroundColor(.blue)

                            Spacer()

                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Removing background...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if processedImage != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Background removed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("Details") {
                    TextField("Item Name", text: $itemName)

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ClothingCategory.allCases) { category in
                            HStack {
                                Text(category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }

                Section {
                    Button("Save Item") {
                        saveItem()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!canSave)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $capturedImage, isPresented: $showingCamera, sourceType: .camera)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $capturedImage, isPresented: $showingImagePicker, sourceType: .photoLibrary)
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showingSourceSelection) {
                Button("Take Photo") {
                    showingCamera = true
                }
                Button("Choose from Library") {
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: capturedImage) { _, newImage in
                if let image = newImage {
                    processImage(image)
                }
            }
        }
    }

    private var canSave: Bool {
        !itemName.isEmpty && processedImage != nil && !isProcessing
    }

    private func processImage(_ image: UIImage) {
        isProcessing = true
        BackgroundRemovalService.shared.removeBackground(from: image) { result in
            DispatchQueue.main.async {
                isProcessing = false
                if let processedImage = result {
                    self.processedImage = processedImage
                } else {
                    // Fallback if background removal fails
                    self.processedImage = image
                }
            }
        }
    }

    private func saveItem() {
        guard let imageToSave = processedImage,
              let imageData = imageToSave.jpegData(compressionQuality: 0.8) else {
            return
        }

        let newItem = ClothingItem(
            name: itemName,
            category: selectedCategory,
            imageData: imageData
        )

        wardrobeManager.addClothingItem(newItem)
        dismiss()
    }
}

#Preview {
    AddItemView()
        .environmentObject(WardrobeManager())
}
