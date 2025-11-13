import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var wardrobeManager: WardrobeManager
    @StateObject private var cameraService = CameraService()

    @State private var selectedCategory: ClothingCategory = .tops
    @State private var capturedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var withoutbgImage: UIImage?
    @State private var isnetImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isProcessing = false
    @State private var showingSourceSelection = false
    @State private var showingResultSelection = false
    @State private var processingError: String?

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
                            } else if let error = processingError {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if let error = processingError {
                        Text("Note: Using original image. Make sure backend server is running on \(BackgroundRemovalService.shared.apiBaseURL)")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.vertical, 4)
                    }
                }

                Section("Category") {
                    Picker("Select Category", selection: $selectedCategory) {
                        ForEach(ClothingCategory.allCases) { category in
                            if category.isEmojiIcon {
                                Label {
                                    Text(category.rawValue)
                                } icon: {
                                    Text(category.iconName)
                                }
                                .tag(category)
                            } else {
                                Label {
                                    Text(category.rawValue)
                                } icon: {
                                    Image(systemName: category.iconName)
                                        .foregroundColor(category.iconColor)
                                }
                                .tag(category)
                            }
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
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
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
            .onChange(of: capturedImage) { newImage in
                if let image = newImage {
                    processImage(image)
                }
            }
            .sheet(isPresented: $showingResultSelection) {
                ResultSelectionView(
                    withoutbgImage: withoutbgImage,
                    isnetImage: isnetImage,
                    onSelect: { selectedImage in
                        processedImage = selectedImage
                        showingResultSelection = false
                    }
                )
            }
        }
    }

    private var canSave: Bool {
        processedImage != nil && !isProcessing
    }

    private func processImage(_ image: UIImage) {
        isProcessing = true
        processingError = nil

        BackgroundRemovalService.shared.removeBackgroundDual(from: image) { withoutbgResult, isnetResult in
            DispatchQueue.main.async {
                isProcessing = false
                self.withoutbgImage = withoutbgResult
                self.isnetImage = isnetResult

                if withoutbgResult != nil || isnetResult != nil {
                    // If we have at least one result, show selection UI
                    self.showingResultSelection = true
                    self.processingError = nil
                } else {
                    // Both failed - use original image
                    self.processedImage = image
                    self.processingError = "Server unavailable"
                    print("⚠️ Background removal failed - using original image")
                }
            }
        }
    }

    private func saveItem() {
        guard let imageToSave = processedImage,
              let imageData = imageToSave.jpegData(compressionQuality: 0.8) else {
            return
        }

        // Auto-generate name based on category and count
        let categoryItems = wardrobeManager.items(for: selectedCategory)
        let itemNumber = categoryItems.count + 1
        let autoName = "\(selectedCategory.rawValue) #\(itemNumber)"

        let newItem = ClothingItem(
            name: autoName,
            category: selectedCategory,
            imageData: imageData
        )

        wardrobeManager.addClothingItem(newItem)
        dismiss()
    }
}

// MARK: - Result Selection View

struct ResultSelectionView: View {
    let withoutbgImage: UIImage?
    let isnetImage: UIImage?
    let onSelect: (UIImage) -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose Your Preferred Result")
                    .font(.headline)
                    .padding(.top)

                Text("Compare both background removal methods and select the one you like best")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 15) {
                    // WithoutBG Result
                    if let withoutbgImage = withoutbgImage {
                        VStack {
                            Text("WithoutBG")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)

                            Image(uiImage: withoutbgImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 400)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 2)
                                )

                            Button {
                                onSelect(withoutbgImage)
                                dismiss()
                            } label: {
                                Text("Select")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                    } else {
                        VStack {
                            Text("WithoutBG")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(maxHeight: 400)
                                .overlay(
                                    Text("Not Available")
                                        .foregroundColor(.secondary)
                                )
                        }
                    }

                    // ISNet Result
                    if let isnetImage = isnetImage {
                        VStack {
                            Text("ISNet")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)

                            Image(uiImage: isnetImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 400)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, lineWidth: 2)
                                )

                            Button {
                                onSelect(isnetImage)
                                dismiss()
                            } label: {
                                Text("Select")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                        }
                    } else {
                        VStack {
                            Text("ISNet")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(maxHeight: 400)
                                .overlay(
                                    Text("Not Available")
                                        .foregroundColor(.secondary)
                                )
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Choose Result")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AddItemView()
        .environmentObject(WardrobeManager())
}
