//
//  ContentView.swift
//  PawvisionApp
//
//  Created by Vikrant Singh on 5/12/25.
//

import SwiftUI
import PhotosUI
import Photos
import AVFoundation

struct DesignSystem {
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 20
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.indigo
        static let accent = Color.orange
        static let background = Color(.systemBackground)
        static let cardBackground = Color(.secondarySystemBackground)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let overlay = Color.black.opacity(0.3)
    }
    
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let caption = Font.system(size: 12, weight: .medium)
    }
    
    struct Shadows {
        static let card = Color.black.opacity(0.1)
        static let button = Color.black.opacity(0.15)
    }
}

enum VisionMode: String, CaseIterable {
    case dog = "Dog Vision"
    case bee = "Bee Vision"
    case snake = "Snake Vision"
    case bird = "Bird Vision"

    var icon: String {
        switch self {
        case .dog: return "dog"
        case .bee: return "ant"
        case .snake: return "bolt.horizontal"
        case .bird: return "bird"
        }
    }

    var subtitle: String {
        switch self {
        case .dog: return "Dichromatic simulation"
        case .bee: return "UV patterns simulated"
        case .snake: return "Infrared heat-map"
        case .bird: return "Enhanced acuity"
        }
    }

    var animalName: String {
        switch self {
        case .dog: return "dog"
        case .bee: return "bee"
        case .snake: return "snake"
        case .bird: return "bird"
        }
    }

    var liveViewButton: String {
        switch self {
        case .dog: return "Fetch the View!"
        case .bee: return "Buzz into View!"
        case .snake: return "Sense the Heat!"
        case .bird: return "Soar into View!"
        }
    }

    var captureButton: String {
        switch self {
        case .dog: return "Capture Pawtrait"
        case .bee: return "Capture Buzztrait"
        case .snake: return "Capture Heatshot"
        case .bird: return "Capture Feathertrait"
        }
    }

    var takePhotoButton: String {
        switch self {
        case .dog: return "Take a Pawtrait"
        case .bee: return "Take a Buzztrait"
        case .snake: return "Take a Heatshot"
        case .bird: return "Take a Feathertrait"
        }
    }

    var convertButton: String {
        switch self {
        case .dog: return "Paw-ify a Photo"
        case .bee: return "Buzz-ify a Photo"
        case .snake: return "Heat-ify a Photo"
        case .bird: return "Feather-ify a Photo"
        }
    }

    var photoPickerText: String {
        switch self {
        case .dog: return "Pick a Photo to Paw-ify"
        case .bee: return "Pick a Photo to Buzz-ify"
        case .snake: return "Pick a Photo to Heat-ify"
        case .bird: return "Pick a Photo to Feather-ify"
        }
    }

    var saveButtonLabel: String {
        switch self {
        case .dog: return "Save Dogified"
        case .bee: return "Save Bee-ified"
        case .snake: return "Save Snakified"
        case .bird: return "Save Birdified"
        }
    }

    var successMessage: String {
        switch self {
        case .dog: return "Saved to Photos! 🐾"
        case .bee: return "Saved to Photos! 🐝"
        case .snake: return "Saved to Photos! 🐍"
        case .bird: return "Saved to Photos! 🐦"
        }
    }

    var videoSuccessMessage: String {
        switch self {
        case .dog: return "Video Saved to Photos! 🐾"
        case .bee: return "Video Saved to Photos! 🐝"
        case .snake: return "Video Saved to Photos! 🐍"
        case .bird: return "Video Saved to Photos! 🐦"
        }
    }

    var shareMessage: String {
        switch self {
        case .dog: return "Through my eyes | Through my dog's eyes"
        case .bee: return "Through my eyes | Through a bee's eyes"
        case .snake: return "Through my eyes | Through a snake's eyes"
        case .bird: return "Through my eyes | Through a bird's eyes"
        }
    }

    var funFact: String {
        switch self {
        case .dog:
            return "🐕 Dogs see the world in shades of blue and yellow. They can't see red or green like we do - a red ball on green grass looks yellow to them!"
        case .bee:
            return "🐝 Bees can see ultraviolet light that's invisible to us! Flowers have secret patterns only bees can see, like arrows pointing to yummy nectar."
        case .snake:
            return "🐍 Some snakes have heat-sensing superpowers! They can 'see' warm things in the dark, like a thermal camera. That's how they find their dinner!"
        case .bird:
            return "🦅 Birds have amazing eyesight - way better than ours! They can spot a tiny bug from far away and see colors we can't even imagine."
        }
    }
}

struct ContentView: View {
    enum ScreenMode {
        case home, camera, capture, convert
    }

    enum RecordingState {
        case idle, recording, complete
    }

    @State private var mode: ScreenMode = .home
    @State private var captureRequested = false
    @State private var showCaptureSuccess = false

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var filteredImage: UIImage?
    @State private var showSaveSuccess = false

    @State private var capturedFiltered: UIImage?
    @State private var capturedOriginal: UIImage?
    @State private var showSaveOptions = false

    // Video recording state management
    @State private var recordingState: RecordingState = .idle
    @State private var recordingRequested = false
    @State private var stopRecordingRequested = false
    @State private var recordedVideoURL: URL?
    @State private var showVideoSaveOptions = false

    // Share sheet state for comparison sharing
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    // Camera switch and zoom state
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    @State private var zoomFactor: CGFloat = 1.0
    @State private var switchCameraRequested = false

    // Vision mode state
    @State private var visionMode: VisionMode = .dog

    // Convert VisionMode to VisionType for CameraView
    var visionTypeBinding: Binding<VisionType> {
        Binding(
            get: {
                switch visionMode {
                case .dog: return .dog
                case .bee: return .bee
                case .snake: return .snake
                case .bird: return .bird
                }
            },
            set: {
                switch $0 {
                case .dog: visionMode = .dog
                case .bee: visionMode = .bee
                case .snake: visionMode = .snake
                case .bird: visionMode = .bird
                }
            }
        )
    }

    var body: some View {
        switch mode {
        case .camera:
            ZStack {
                Color.black
                    .ignoresSafeArea()

                // Camera view with recording capabilities
                CameraView(
                    captureRequested: .constant(false),
                    onCapture: { _, _ in },
                    recordingRequested: $recordingRequested,
                    stopRecordingRequested: $stopRecordingRequested,
                    onRecordingComplete: { videoURL in
                        recordedVideoURL = videoURL
                        recordingState = .complete
                        showVideoSaveOptions = true
                    },
                    cameraPosition: $cameraPosition,
                    zoomFactor: $zoomFactor,
                    switchCameraRequested: $switchCameraRequested,
                    visionMode: visionTypeBinding
                )
                .ignoresSafeArea()

                // Recording UI based on current state
                VStack {
                    // Top controls: Vision mode toggle and camera flip
                    HStack {
                        // Vision mode dropdown
                        Menu {
                            ForEach(VisionMode.allCases, id: \.self) { mode in
                                Button(action: { visionMode = mode }) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(mode.rawValue)
                                            if visionMode == mode {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                        Text(mode.subtitle)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: visionMode.icon)
                                Text(visionMode.rawValue)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                        }
                        .padding(.leading, 16)

                        Spacer()

                        Button(action: {
                            switchCameraRequested = true
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 50)

                    Spacer()

                    // Zoom slider
                    if recordingState != .complete {
                        VStack(spacing: 4) {
                            Text(String(format: "%.1fx", zoomFactor))
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)

                            HStack {
                                Text("1x")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Slider(value: $zoomFactor, in: 1.0...5.0, step: 0.1)
                                    .accentColor(.white)
                                Text("5x")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 40)
                        }
                        .padding(.bottom, 10)
                    }

                    switch recordingState {
                    case .idle:
                        // Show Start Recording and Back buttons
                        HStack(spacing: 20) {
                            Button("Back") {
                                mode = .home
                                recordingState = .idle
                                zoomFactor = 1.0
                            }
                            .font(.headline)
                            .padding()
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(8)
                            .foregroundColor(.blue)

                            Button("Start Recording") {
                                recordingState = .recording
                                recordingRequested = true
                            }
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        }
                        .padding(.bottom, 40)

                    case .recording:
                        // Show only Stop Recording button with recording indicator
                        VStack(spacing: 10) {
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 12, height: 12)
                                Text("Recording...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }

                            Button("Stop Recording") {
                                recordingState = .idle
                                stopRecordingRequested = true
                            }
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.gray.opacity(0.8))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        }
                        .padding(.bottom, 40)

                    case .complete:
                        // This state is handled by showVideoSaveOptions overlay
                        EmptyView()
                    }
                }
                
                // Video save options overlay
                if showVideoSaveOptions {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("Recording Complete!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 40)
                        
                        Spacer()
                        
                        VStack(spacing: 16) {
                            Button("Save to Photos") {
                                if let videoURL = recordedVideoURL {
                                    saveVideoToPhotos(videoURL)
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            
                            Button("Go Back") {
                                // Discard recording and reset state
                                if let videoURL = recordedVideoURL {
                                    try? FileManager.default.removeItem(at: videoURL)
                                }
                                recordedVideoURL = nil
                                showVideoSaveOptions = false
                                recordingState = .idle
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.8))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                        }
                        .padding(.bottom, 40)
                    }
                }
                
                // Success message for video save
                if showSaveSuccess {
                    VStack {
                        Spacer()
                        Text(visionMode.videoSuccessMessage)
                            .font(.headline)
                            .padding()
                            .background(Color.green.opacity(0.85))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .padding(.bottom, 120)
                    }
                    .transition(.opacity)
                }
            }

        case .capture:
            ZStack {
                if showSaveOptions, let original = capturedOriginal, let filtered = capturedFiltered {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 0) {
                        Spacer()
                        HStack(spacing: 10) {
                            VStack {
                                Text("Original")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Image(uiImage: original)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(10)
                            }
                            VStack {
                                Text(visionMode.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Image(uiImage: filtered)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        .frame(maxHeight: .infinity)

                        VStack(spacing: 20) {
                            Button(action: {
                                UIImageWriteToSavedPhotosAlbum(filtered, nil, nil, nil)
                                showSaveOptions = false
                                showCaptureSuccess = true
                            }) {
                                Text(visionMode.saveButtonLabel)
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.headline)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .padding(.horizontal)

                            Button(action: {
                                if let comparisonImage = createShareableComparisonImage(original: original, filtered: filtered) {
                                    UIImageWriteToSavedPhotosAlbum(comparisonImage, nil, nil, nil)
                                }
                                showSaveOptions = false
                                showCaptureSuccess = true
                            }) {
                                Text("Save Comparison")
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.headline)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .padding(.horizontal)

                            // Share Comparison button
                            Button(action: {
                                if let comparisonImage = createShareableComparisonImage(original: original, filtered: filtered) {
                                    shareImage = comparisonImage
                                }
                            }) {
                                Text("Share Comparison")
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.headline)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .padding(.horizontal)

                            Button(action: {
                                mode = .home
                                showSaveOptions = false
                            }) {
                                Text("Home")
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.headline)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding()
                } else {
                    Color.black.ignoresSafeArea()
                    CameraView(
                        captureRequested: $captureRequested,
                        onCapture: { original, filtered in
                            capturedOriginal = original
                            capturedFiltered = filtered
                            showSaveOptions = true
                        },
                        recordingRequested: .constant(false),
                        stopRecordingRequested: .constant(false),
                        onRecordingComplete: { _ in },
                        cameraPosition: $cameraPosition,
                        zoomFactor: $zoomFactor,
                        switchCameraRequested: $switchCameraRequested,
                        visionMode: visionTypeBinding
                    )
                    .ignoresSafeArea()
                    VStack {
                        // Top controls: Back button, Vision mode toggle, and Camera flip
                        HStack {
                            Button(action: {
                                mode = .home
                                zoomFactor = 1.0
                            }) {
                                Text("Back")
                                    .padding()
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(8)
                                    .foregroundColor(.blue)
                            }
                            .padding(.leading, 16)

                            Spacer()

                            // Vision mode dropdown
                            Menu {
                                ForEach(VisionMode.allCases, id: \.self) { mode in
                                    Button(action: { visionMode = mode }) {
                                        VStack(alignment: .leading) {
                                            HStack {
                                                Text(mode.rawValue)
                                                if visionMode == mode {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                            Text(mode.subtitle)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: visionMode.icon)
                                    Text(visionMode.rawValue)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(10)
                            }

                            Spacer()

                            Button(action: {
                                switchCameraRequested = true
                            }) {
                                Image(systemName: "camera.rotate")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 16)
                        }
                        .padding(.top, 50)

                        Spacer()

                        // Zoom slider
                        VStack(spacing: 4) {
                            Text(String(format: "%.1fx", zoomFactor))
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)

                            HStack {
                                Text("1x")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Slider(value: $zoomFactor, in: 1.0...5.0, step: 0.1)
                                    .accentColor(.white)
                                Text("5x")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 40)
                        }
                        .padding(.bottom, 10)

                        // Capture button
                        Button(action: { captureRequested = true }) {
                            Text(visionMode.captureButton)
                                .frame(maxWidth: .infinity)
                        }
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 50)
                    }
                    if showCaptureSuccess {
                        VStack {
                            Spacer()
                            Text(visionMode.successMessage)
                                .font(.headline)
                                .padding()
                                .background(Color.green.opacity(0.85))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .padding(.bottom, 120)
                        }
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCaptureSuccess = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(activityItems: [visionMode.shareMessage, image, "Download Pawvision here - https://apps.apple.com/us/app/pawvision/id6746367830"]) {
                        // Reset share state when sheet is dismissed
                        shareImage = nil
                        showShareSheet = false
                    }
                }
            }
            .onChange(of: shareImage) { image in
                if image != nil {
                    showShareSheet = true
                }
            }

        case .convert:
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 18) {
                    // Vision mode dropdown at top
                    Menu {
                        ForEach(VisionMode.allCases, id: \.self) { mode in
                            Button(action: { visionMode = mode }) {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(mode.rawValue)
                                        if visionMode == mode {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    Text(mode.subtitle)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: visionMode.icon)
                            Text(visionMode.rawValue)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .padding(.top, 60)

                    Spacer()
                    if let selectedImage = selectedImage, let filteredImage = filteredImage {
                        HStack(spacing: 10) {
                            VStack {
                                Text("Original")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(10)
                            }
                            VStack {
                                Text(visionMode.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Image(uiImage: filteredImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(10)
                            }
                        }
                        VStack(spacing: 20) {
                            Button(action: {
                                UIImageWriteToSavedPhotosAlbum(filteredImage, nil, nil, nil)
                                showSaveSuccess = true
                            }) {
                                Text(visionMode.saveButtonLabel)
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.headline)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .padding(.horizontal)

                            Button(action: {
                                // Compose and save comparison image
                                if let comparisonImage = createShareableComparisonImage(original: selectedImage, filtered: filteredImage) {
                                    UIImageWriteToSavedPhotosAlbum(comparisonImage, nil, nil, nil)
                                    showSaveSuccess = true
                                }
                            }) {
                                Text("Save Comparison")
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.headline)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .padding(.horizontal)

                            Button(action: {
                                // Compose and share comparison image
                                if let comparisonImage = createShareableComparisonImage(original: selectedImage, filtered: filteredImage) {
                                    shareImage = comparisonImage
                                }
                            }) {
                                Text("Share Comparison")
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.headline)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    } else {
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Text(visionMode.photoPickerText)
                                .font(.headline)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .foregroundColor(.blue)
                        }
                    }
                    if showSaveSuccess {
                        Text(visionMode.successMessage)
                            .font(.headline)
                            .padding()
                            .background(Color.green.opacity(0.85))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button(action: {
                        selectedImage = nil
                        filteredImage = nil
                        selectedPhotoItem = nil
                        showSaveSuccess = false
                        mode = .home
                    }) {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(10)
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(activityItems: [visionMode.shareMessage, image, "Download Pawvision here - https://apps.apple.com/us/app/pawvision/id6746367830"]) {
                        // Reset share state when sheet is dismissed
                        shareImage = nil
                        showShareSheet = false
                    }
                }
            }
            .onChange(of: shareImage) { image in
                if image != nil {
                    showShareSheet = true
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                guard let item = newItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        filteredImage = applyVisionFilter(to: image, mode: visionMode)
                    }
                }
            }
            .onChange(of: visionMode) { newMode in
                // Re-apply filter when vision mode changes
                if let image = selectedImage {
                    filteredImage = applyVisionFilter(to: image, mode: newMode)
                }
            }

        case .home:
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()
                    Image("Homepage")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(radius: 10)

                    Text("Pawvision")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                    Text("See the world through animal eyes")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))

                    VStack(spacing: 16) {
                        Button(action: {
                            mode = .camera
                        }) {
                            Text(visionMode.liveViewButton)
                                .frame(maxWidth: .infinity)
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.white.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .padding(.horizontal, 40)

                        Button(action: {
                            mode = .capture
                        }) {
                            Text(visionMode.takePhotoButton)
                                .frame(maxWidth: .infinity)
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .padding(.horizontal, 40)

                        Button(action: {
                            mode = .convert
                        }) {
                            Text(visionMode.convertButton)
                                .frame(maxWidth: .infinity)
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .padding(.horizontal, 40)
                    }

                    // Vision mode selector on home page
                    Menu {
                        ForEach(VisionMode.allCases, id: \.self) { mode in
                            Button(action: { visionMode = mode }) {
                                HStack {
                                    Text(mode.rawValue)
                                    if visionMode == mode {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: visionMode.icon)
                            Text(visionMode.rawValue)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .padding(.top, 8)

                    // Fun fact about selected vision mode
                    Text(visionMode.funFact)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    Spacer()

                    // Disclaimer
                    Text("For entertainment purposes only.\nNot scientifically accurate.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)
                }
                .padding()
            }
        }
    }
    
    func createShareableComparisonImage(original: UIImage, filtered: UIImage) -> UIImage? {
        // Resize images to reasonable sharing size (max 1200px width for composite)
        let maxWidth: CGFloat = 600 // Each image max 600px, so composite will be 1200px
        
        let originalResized = resizeImageForSharing(original, maxWidth: maxWidth)
        let filteredResized = resizeImageForSharing(filtered, maxWidth: maxWidth)
        
        // Create composite with fixed scale to avoid memory issues
        let totalWidth = originalResized.size.width + filteredResized.size.width
        let maxHeight = max(originalResized.size.height, filteredResized.size.height)
        let size = CGSize(width: totalWidth, height: maxHeight)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0) // Fixed 1.0 scale
        defer { UIGraphicsEndImageContext() }
        
        // Draw original image
        originalResized.draw(in: CGRect(origin: .zero, size: originalResized.size))
        
        // Draw filtered image next to it
        filteredResized.draw(in: CGRect(
            origin: CGPoint(x: originalResized.size.width, y: 0),
            size: filteredResized.size
        ))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func resizeImageForSharing(_ image: UIImage, maxWidth: CGFloat) -> UIImage {
        let aspectRatio = image.size.height / image.size.width
        let newWidth = min(image.size.width, maxWidth)
        let newHeight = newWidth * aspectRatio
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    func saveVideoToPhotos(_ videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        // Clean up temporary file
                        try? FileManager.default.removeItem(at: videoURL)
                        
                        // Reset state and show success
                        recordedVideoURL = nil
                        showVideoSaveOptions = false
                        recordingState = .idle
                        showSaveSuccess = true
                        
                        // Hide success message after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showSaveSuccess = false
                        }
                    } else {
                        // Handle error - you could show an error message here
                        print("Failed to save video: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
    }

    func applyVisionFilter(to image: UIImage, mode: VisionMode) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let context = CIContext()

        let filteredCI: CIImage

        switch mode {
        case .dog:
            // Dog Vision – Dichromatic simulation
            let colorFilter = CIFilter.colorMatrix()
            colorFilter.inputImage = ciImage
            colorFilter.rVector = CIVector(x: 0.625, y: 0,    z: 0, w: 0)
            colorFilter.gVector = CIVector(x: 0.375, y: 0.3,  z: 0.3, w: 0)
            colorFilter.bVector = CIVector(x: 0,     y: 0,    z: 0.7, w: 0)
            guard let output = colorFilter.outputImage else { return nil }
            filteredCI = output
        case .bee:
            // Bee Vision – UV patterns simulated
            guard let beeOutput = applyBeeVisionFilter(to: ciImage, context: context) else { return nil }
            filteredCI = beeOutput
        case .snake:
            // Snake Vision – Infrared heat-map
            guard let snakeOutput = applySnakeVisionFilter(to: ciImage, context: context) else { return nil }
            filteredCI = snakeOutput
        case .bird:
            // Bird Vision – Enhanced acuity
            guard let birdOutput = applyBirdVisionFilter(to: ciImage, context: context) else { return nil }
            filteredCI = birdOutput
        }

        guard let cgimg = context.createCGImage(filteredCI, from: filteredCI.extent)
        else { return nil }
        let filteredUIImage = UIImage(cgImage: cgimg)

        // Rotate 90 degrees clockwise
        let size = CGSize(width: filteredUIImage.size.height, height: filteredUIImage.size.width)
        UIGraphicsBeginImageContext(size)
        if let ctx = UIGraphicsGetCurrentContext() {
            ctx.translateBy(x: size.width / 2, y: size.height / 2)
            ctx.rotate(by: .pi / 2)
            filteredUIImage.draw(in: CGRect(x: -filteredUIImage.size.width / 2,
                                            y: -filteredUIImage.size.height / 2,
                                            width: filteredUIImage.size.width,
                                            height: filteredUIImage.size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return rotatedImage
        } else {
            return filteredUIImage
        }
    }

    // Bee Vision – UV patterns simulated
    // Suppresses red, emphasizes blue-green, reveals hidden patterns via edge enhancement
    // Simulates how bees see "nectar guides" - UV patterns invisible to humans
    func applyBeeVisionFilter(to ciImage: CIImage, context: CIContext) -> CIImage? {
        // Step 1: Apply color matrix - suppress red channel, emphasize blue-green
        let colorFilter = CIFilter.colorMatrix()
        colorFilter.inputImage = ciImage
        colorFilter.rVector = CIVector(x: 0.1,  y: 0.35, z: 0.05, w: 0)
        colorFilter.gVector = CIVector(x: 0.05, y: 0.8,  z: 0.2,  w: 0)
        colorFilter.bVector = CIVector(x: 0.05, y: 0.15, z: 0.85, w: 0)
        guard let colorShifted = colorFilter.outputImage else { return nil }

        // Step 2: Blend color-shifted with original (70% color shift, 30% original)
        let blendedColor = colorShifted.applyingFilter("CIColorMatrix", parameters: [
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.7)
        ]).composited(over: ciImage.applyingFilter("CIColorMatrix", parameters: [
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.3)
        ]))

        // Step 3: Strong unsharp mask for structure/pattern enhancement
        let unsharpMask = CIFilter.unsharpMask()
        unsharpMask.inputImage = blendedColor
        unsharpMask.radius = 6.0
        unsharpMask.intensity = 2.0
        guard let patternEnhanced = unsharpMask.outputImage else { return blendedColor }

        // Step 4: Second pass with smaller radius for fine detail
        let fineDetail = patternEnhanced.applyingFilter("CIUnsharpMask", parameters: [
            "inputRadius": 2.5,
            "inputIntensity": 1.8
        ])

        // Step 5: Strong luminance sharpening for crisp texture
        let luminanceSharpen = CIFilter.sharpenLuminance()
        luminanceSharpen.inputImage = fineDetail
        luminanceSharpen.sharpness = 1.2
        guard let sharpened = luminanceSharpen.outputImage else { return fineDetail }

        // Step 6: Boost local contrast via highlight/shadow adjustment
        let contrastBoosted = sharpened.applyingFilter("CIHighlightShadowAdjust", parameters: [
            "inputHighlightAmount": 0.8,
            "inputShadowAmount": 0.6
        ])

        // Step 7: Final saturation and contrast boost
        let final = contrastBoosted.applyingFilter("CIColorControls", parameters: [
            "inputSaturation": 1.35,
            "inputContrast": 1.15
        ])

        return final
    }

    // Snake Vision – Infrared heat-map simulation
    // Rainbow thermal palette: blue → cyan → green → yellow → orange → red
    func applySnakeVisionFilter(to ciImage: CIImage, context: CIContext) -> CIImage? {
        let cubeSize = 64
        let cubeData = createThermalCubeData(size: cubeSize)

        // Step 1: Moderate blur to simulate thermal sensor diffusion
        let blurred = ciImage.applyingFilter("CIGaussianBlur", parameters: [
            "inputRadius": 8.0
        ])

        // Step 2: Adjust contrast to spread luminance values
        let adjusted = blurred.applyingFilter("CIColorControls", parameters: [
            "inputContrast": 1.2,
            "inputBrightness": 0.0,
            "inputSaturation": 0.0  // Desaturate to prepare for thermal mapping
        ])

        // Step 3: Apply thermal rainbow gradient using CIColorCube LUT
        let thermalColored = adjusted.applyingFilter("CIColorCube", parameters: [
            "inputCubeDimension": cubeSize,
            "inputCubeData": cubeData
        ])

        // Step 4: Boost saturation of the thermal colors for vivid effect
        let vibrant = thermalColored.applyingFilter("CIColorControls", parameters: [
            "inputSaturation": 1.4,
            "inputContrast": 1.05
        ])

        return vibrant
    }

    // Create thermal rainbow lookup table for CIColorCube
    // Maps luminance (0-1) to rainbow: blue → cyan → green → yellow → orange → red
    func createThermalCubeData(size: Int) -> Data {
        var cubeData = [Float]()
        cubeData.reserveCapacity(size * size * size * 4)

        for b in 0..<size {
            for g in 0..<size {
                for r in 0..<size {
                    // Calculate luminance from input RGB
                    let rf = Float(r) / Float(size - 1)
                    let gf = Float(g) / Float(size - 1)
                    let bf = Float(b) / Float(size - 1)

                    // Luminance calculation (Rec. 709)
                    let luminance = 0.2126 * rf + 0.7152 * gf + 0.0722 * bf

                    // Map luminance to thermal rainbow color
                    let (outR, outG, outB) = thermalGradientColor(luminance)

                    cubeData.append(outR)
                    cubeData.append(outG)
                    cubeData.append(outB)
                    cubeData.append(1.0) // Alpha
                }
            }
        }

        return Data(bytes: cubeData, count: cubeData.count * MemoryLayout<Float>.size)
    }

    // Map a luminance value (0-1) to thermal rainbow color
    // Gradient: blue → cyan → green → yellow → orange → red
    func thermalGradientColor(_ t: Float) -> (Float, Float, Float) {
        // Define gradient stops (luminance -> RGB)
        // 0.00: Deep blue (cold)
        // 0.15: Blue
        // 0.30: Cyan
        // 0.45: Green
        // 0.60: Yellow
        // 0.75: Orange
        // 1.00: Red (hot)

        let r: Float
        let g: Float
        let b: Float

        if t < 0.15 {
            // Deep blue to blue
            let s = t / 0.15
            r = 0.0
            g = 0.0
            b = 0.3 + 0.7 * s  // 0.3 -> 1.0
        } else if t < 0.30 {
            // Blue to cyan
            let s = (t - 0.15) / 0.15
            r = 0.0
            g = s * 0.9  // 0 -> 0.9
            b = 1.0
        } else if t < 0.45 {
            // Cyan to green
            let s = (t - 0.30) / 0.15
            r = 0.0
            g = 0.9 + s * 0.1  // 0.9 -> 1.0
            b = 1.0 - s  // 1.0 -> 0.0
        } else if t < 0.60 {
            // Green to yellow
            let s = (t - 0.45) / 0.15
            r = s  // 0 -> 1.0
            g = 1.0
            b = 0.0
        } else if t < 0.75 {
            // Yellow to orange
            let s = (t - 0.60) / 0.15
            r = 1.0
            g = 1.0 - s * 0.4  // 1.0 -> 0.6
            b = 0.0
        } else {
            // Orange to red
            let s = (t - 0.75) / 0.25
            r = 1.0
            g = 0.6 - s * 0.6  // 0.6 -> 0.0
            b = 0.0
        }

        return (r, g, b)
    }

    // Bird Vision – Enhanced visual acuity simulation
    // High local contrast, micro-detail separation, no color tint, no edge halos
    func applyBirdVisionFilter(to ciImage: CIImage, context: CIContext) -> CIImage? {
        // Step 1: Boost overall contrast (+8%)
        let contrastBoosted = ciImage.applyingFilter("CIColorControls", parameters: [
            "inputContrast": 1.08,
            "inputSaturation": 1.0  // Keep saturation neutral
        ])

        // Step 2: Micro-detail unsharp mask (small radius avoids halos)
        let microDetail = contrastBoosted.applyingFilter("CIUnsharpMask", parameters: [
            "inputRadius": 0.8,
            "inputIntensity": 0.9
        ])

        // Step 3: Luminance sharpening for edge acuity
        let sharpenFilter = CIFilter.sharpenLuminance()
        sharpenFilter.inputImage = microDetail
        sharpenFilter.sharpness = 0.6
        guard let sharpened = sharpenFilter.outputImage else { return microDetail }

        // Step 4: High-frequency texture enhancement (very small radius)
        let textureEnhanced = sharpened.applyingFilter("CIUnsharpMask", parameters: [
            "inputRadius": 0.4,
            "inputIntensity": 0.7
        ])

        // Step 5: Local contrast via highlight/shadow adjustment
        let finalEnhanced = textureEnhanced.applyingFilter("CIHighlightShadowAdjust", parameters: [
            "inputHighlightAmount": 0.95,  // Slight highlight reduction
            "inputShadowAmount": 0.3       // Open up shadows for detail
        ])

        return finalEnhanced
    }
}

// ShareSheet struct for presenting UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        
        // Handle completion (success or cancellation)
        activityVC.completionWithItemsHandler = { _, completed, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Share error: \(error.localizedDescription)")
                }
                // Always call onDismiss to reset state
                onDismiss?()
            }
        }
        
        return activityVC
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
