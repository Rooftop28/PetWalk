# Project Context: PetWalk (iOS & WatchOS)

I am developing an iOS and WatchOS app called "PetWalk". It is a companion app for dog walking that features a user's real pet photo as a sticker.

## 1. Tech Stack & Architecture
- **Language**: Swift 5.0+
- **Framework**: SwiftUI (iOS & WatchOS)
- **Architecture**: MVVM
- **Key Frameworks**: 
  - `Vision` (iOS 17+ `VNGenerateForegroundInstanceMaskRequest` for background removal)
  - `HealthKit` (Reading steps & walking distance)
  - `WatchConnectivity` (Syncing images from Phone to Watch)
  - `PhotosUI` (Image selection)
  - `Codable` / `JSON` (Local data persistence)

## 2. Current Project Status
We have implemented the MVP structure with the following components:

### A. Core Features (iOS)
1.  **HomeView**: 
    - Displays a "Sticker" of the dog with a spring animation.
    - Uses `PhotosPicker` to allow users to select a photo, which is processed by `ImageProcessor` to remove the background.
    - Displays a Green Progress Ring showing real-time distance fetched via `HealthManager` (HealthKit).
    - Contains a "GO" button (currently prints to console).
2.  **HistoryView**:
    - Displays a "Calendar Heatmap" (Green paws for walks, Photos if uploaded).
    - Shows summary stats (Total Distance, Total Time).
    - Lists recent walk records.
    - Supports tapping a calendar photo to view it in full screen (Overlay).
3.  **Data Persistence**:
    - Uses `DataManager` to save/load `WalkRecord` items to a local JSON file in the Documents directory.
4.  **Design System**:
    - Colors: Cream background (`FFF9F0`), Green accents (`8BC34A`), Brown text (`4A3021`).
    - Assets: Default dog image named "tongtong".

### B. WatchOS Features
1.  **Watch Target**: Created `PetWalkWatch`.
2.  **Connectivity**:
    - iOS side (`WatchConnector`): Sends processed images via `WCSession.default.transferFile`.
    - Watch side (`PhoneConnector`): Receives images and updates the UI.
    - **Current Status**: Code is implemented, but testing failed due to environment mismatch (Real iPhone + Simulator Watch). Code uses `transferFile` without `isReachable` check to allow background transfer.

## 3. Project File Structure
- **Models/**
  - `WalkRecord.swift` (Identifiable, Codable struct for walk history)
- **ViewModels/**
  - `PetViewModel.swift` (Handles image picking, processing via Vision, and saving)
  - `HealthManager.swift` (Handles HealthKit auth and fetching today's stats)
  - `DataManager.swift` (Handles JSON read/write for WalkRecords)
- **Views/**
  - `HomeView.swift` (Main dashboard)
  - `HistoryView.swift` (Calendar and list)
  - **Components/**
    - `BlobBackgroundView.swift`, `SpeechBubbleView.swift`, `CustomTabBar.swift`
- **Utils/**
  - `ImageProcessor.swift` (Vision framework logic)
  - `WatchConnector.swift` (iOS WCSession logic)
  - `Color+Extensions.swift` (Hex color support)

## 4. Latest Code Context (Reference)

**WalkRecord.swift**:
```swift
struct WalkRecord: Identifiable, Codable {
    var id = UUID(); let day: Int; let date: String; let time: String;
    let distance: Double; let duration: Int; let mood: String; let imageName: String?
}