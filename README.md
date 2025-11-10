# ClothesAI - Virtual Wardrobe & Outfit Builder

A SwiftUI-based iOS application that allows users to photograph their clothing items, remove backgrounds automatically, and create stylish outfit combinations.

## Features

### 📸 Photo Capture & Processing
- Take photos of clothing items directly from your camera
- Choose existing photos from your library
- Automatic background removal with white background application
- AI-powered image processing using Vision framework

### 👔 Smart Wardrobe Organization
- 4-level category system:
  - **Headwear** (hats, caps, beanies)
  - **Outerwear** (jackets, coats)
  - **Tops** (shirts, t-shirts, blouses)
  - **Bottoms** (pants, jeans, skirts)
  - **Footwear** (shoes, sneakers, boots)
  - **Accessories** (belts, bags, jewelry)
- Visual category browsing with item counts
- Item favoriting and management
- Search and filter capabilities

### ✨ Outfit Creator
- Interactive outfit builder interface
- Select items from each category to create complete looks
- Visual outfit preview
- Save unlimited outfit combinations (subscription-dependent)
- Name and organize your favorite looks

### 💎 Subscription Tiers
Four subscription levels to match your needs:

#### Free Plan
- Up to 10 clothing items
- Up to 5 outfits
- Basic background removal
- Photo capture

#### Basic Plan ($2.99/month)
- Up to 50 clothing items
- Up to 25 outfits
- Advanced background removal
- Cloud backup

#### Premium Plan ($7.99/month)
- Up to 200 clothing items
- Up to 100 outfits
- AI-powered outfit suggestions
- Weather-based recommendations
- Cloud backup

#### Unlimited Plan ($14.99/month)
- Unlimited clothing items
- Unlimited outfits
- All Premium features
- Priority support

## Technical Stack

### Frameworks & Technologies
- **SwiftUI** - Modern declarative UI framework
- **Vision Framework** - AI-powered background removal and image segmentation
- **Core Image** - Image processing and manipulation
- **AVFoundation** - Camera access and photo capture
- **Combine** - Reactive programming for state management

### Architecture
- **MVVM Pattern** (Model-View-ViewModel)
- **Data Persistence** - UserDefaults for local storage
- **Modular Design** - Separated concerns for Models, Views, ViewModels, and Services

### Requirements
- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Project Structure

```
ClothesAI/
├── ClothesAI/
│   ├── ClothesAIApp.swift          # Main app entry point
│   ├── Models/
│   │   ├── ClothingItem.swift      # Clothing item data model
│   │   └── SubscriptionTier.swift  # Subscription tier definitions
│   ├── ViewModels/
│   │   ├── WardrobeManager.swift   # Wardrobe state management
│   │   └── SubscriptionManager.swift # Subscription state management
│   ├── Views/
│   │   ├── ContentView.swift       # Main tab navigation
│   │   ├── WardrobeView.swift      # Wardrobe gallery
│   │   ├── AddItemView.swift       # Photo capture & item creation
│   │   ├── ItemDetailView.swift    # Individual item details
│   │   ├── OutfitBuilderView.swift # Outfit creation interface
│   │   ├── OutfitListView.swift    # Saved outfits list
│   │   └── SubscriptionView.swift  # Subscription management
│   ├── Services/
│   │   ├── CameraService.swift     # Camera permission & access
│   │   └── BackgroundRemovalService.swift # AI background removal
│   ├── Assets.xcassets/
│   └── Info.plist
└── ClothesAI.xcodeproj/
```

## Key Features Implementation

### Background Removal
The app uses Apple's Vision framework (`VNGeneratePersonSegmentationRequest`) to intelligently identify and segment people/objects from photos, then composites them onto a clean white background. This ensures all wardrobe items have a consistent, professional appearance.

### Data Persistence
Clothing items and outfits are stored locally using `UserDefaults` with `Codable` protocols for easy serialization. Images are stored as JPEG data with compression for optimal storage.

### Subscription Management
The app implements a flexible subscription system with tiered limits on items and outfits. The system checks limits before allowing new additions and prompts users to upgrade when limits are reached.

### Category System
Items are organized into six main categories with distinct visual identifiers (emoji icons) and customizable ordering. The category system makes it easy to browse and select items when building outfits.

## Installation & Setup

1. Clone the repository:
```bash
git clone https://github.com/YahorNovik/ClothesAI.git
cd ClothesAI
```

2. Open the project in Xcode:
```bash
open ClothesAI.xcodeproj
```

3. Select your development team in project settings

4. Build and run on your iOS device or simulator

## Usage

### Adding Clothing Items
1. Tap the "+" button in the Wardrobe tab
2. Choose to take a photo or select from library
3. Wait for automatic background removal
4. Name your item and select a category
5. Save to your wardrobe

### Creating Outfits
1. Go to the "Create Look" tab
2. Browse items by category
3. Tap items to add them to your outfit
4. Preview your complete look
5. Save with a custom name

### Managing Your Wardrobe
- View items by category or see all at once
- Tap any item to see details and options
- Favorite items for quick access
- Delete items you no longer need

## Future Enhancements

- [ ] iCloud sync for backup and multi-device support
- [ ] AI-powered outfit recommendations
- [ ] Weather-based outfit suggestions
- [ ] Calendar integration for outfit planning
- [ ] Style analytics and insights
- [ ] Social sharing features
- [ ] AR try-on capabilities
- [ ] Seasonal wardrobe organization
- [ ] Color palette matching
- [ ] Laundry tracking

## Privacy

ClothesAI respects your privacy:
- All photos are processed locally on your device
- No data is sent to external servers (in free/basic tiers)
- Camera and photo library permissions are only requested when needed
- You maintain full control over your wardrobe data

## License

Copyright © 2025 ClothesAI. All rights reserved.

## Support

For questions, issues, or feature requests, please open an issue on GitHub.

---

Built with ❤️ using SwiftUI
