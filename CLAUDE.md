# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PawVision is an iOS app built with SwiftUI that simulates how dogs perceive the world through their eyes. The app uses Core Image filters and real-time camera input to provide a live "dog vision" filter, allowing users to see the world through different color perception.

## Architecture

The app follows a simple SwiftUI architecture with three main components:

### Core Files
- **PawvisionApp.swift**: Main app entry point with WindowGroup containing ContentView
- **ContentView.swift**: Main view controller handling all screen modes and state management
- **CameraView.swift**: UIViewRepresentable wrapper around AVFoundation camera functionality

### App Structure
The app operates in four distinct modes managed by `ContentView.ScreenMode`:
- `.home`: Landing screen with navigation options
- `.camera`: Live camera preview with dog vision filter and video recording capabilities
- `.capture`: Camera with capture functionality for taking photos
- `.convert`: Photo picker interface for converting existing photos

### Video Recording Feature
The camera mode (accessible via "Fetch the View") includes a complete video recording flow:
- **Recording States**: `.idle` (start recording + back buttons), `.recording` (stop recording button), `.complete` (save/discard options) 
- **Real-time Filtering**: Video frames are processed with dog vision filter during recording using `AVAssetWriter`
- **Custom Video Processing**: Uses `AVAssetWriter` with `CVPixelBuffer` rendering for filtered video output
- **Save Integration**: Recorded videos are saved to Photos Library with proper permissions

### Core Technology Stack
- **SwiftUI**: Primary UI framework
- **AVFoundation**: Camera capture and video processing
- **Core Image**: Real-time image filtering with custom color matrix
- **PhotosUI**: Photo picker integration for existing image conversion

### Dog Vision Filter Implementation
The core filter uses a color matrix transformation to simulate canine color perception:
- Dogs see primarily in blue-yellow spectrum with limited red-green perception
- Matrix values: R(0.625,0,0), G(0.375,0.3,0.3), B(0,0,0.7)
- Applied in real-time via `CIFilter.colorMatrix()` in both camera and photo modes

## Development Commands

### Building and Running
```bash
# Open project in Xcode
open Pawvision.xcodeproj

# Build from command line (requires Xcode command line tools)
xcodebuild -project Pawvision.xcodeproj -scheme Pawvision -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -project Pawvision.xcodeproj -scheme Pawvision -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Requirements
- Xcode 15+
- iOS 17+ (deployment target: iOS 18.4)
- Swift 5.0+
- macOS Ventura or later for development

## Key Implementation Details

### Camera Session Management
- `CameraView` uses `UIViewRepresentable` to bridge AVFoundation into SwiftUI
- `VideoDelegate` handles frame-by-frame processing via `AVCaptureVideoDataOutputSampleBufferDelegate`
- Real-time filtering applied to each video frame using Core Image context

### State Management
- All app state managed through `@State` properties in `ContentView`
- Image capture handled through binding and callback pattern
- Photo library integration via `PhotosPicker` and async/await pattern

### Image Processing Pipeline
1. Camera input → CVPixelBuffer → CIImage
2. Apply color matrix filter for dog vision simulation
3. Convert back to CGImage/UIImage for display and saving
4. Support for both live preview and photo capture modes

### Photo Management
- Automatic saving to Photos library via `UIImageWriteToSavedPhotosAlbum`
- Support for saving original, filtered, and side-by-side comparison images
- Share functionality through `UIActivityViewController` wrapper

## Testing Structure
- **PawvisionTests**: Unit tests (basic template)
- **PawvisionUITests**: UI tests (basic template)

Test files are currently minimal template implementations and would benefit from expansion for camera functionality, image processing, and UI interactions.