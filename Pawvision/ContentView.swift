//
//  ContentView.swift
//  PawvisionApp
//
//  Created by Vikrant Singh on 5/12/25.
//

import SwiftUI
import PhotosUI
import Photos

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
                    }
                )
                .ignoresSafeArea()

                // Recording UI based on current state
                VStack {
                    Spacer()
                    
                    switch recordingState {
                    case .idle:
                        // Show Start Recording and Back buttons
                        HStack(spacing: 20) {
                            Button("Back") {
                                mode = .home
                                recordingState = .idle
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
                        Text("Video Saved to Photos! 🐾")
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
                                Text("Dog Vision")
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
                                Text("Save Dogified")
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
                        onRecordingComplete: { _ in }
                    )
                    .ignoresSafeArea()
                    VStack {
                        Spacer()
                        Button(action: { captureRequested = true }) {
                            Text("Capture Pawtrait")
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
                            Text("Saved to Photos! 🐾")
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
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { mode = .home }) {
                                Text("Back")
                                    .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(8)
                            .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    .padding(.top, 30)
                    .padding(.trailing, 16)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(activityItems: ["Through my eyes | Through my dog's eyes", image]) {
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
                                Text("Dog Vision")
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
                                // No conditional needed since filteredImage is already non-optional here
                                UIImageWriteToSavedPhotosAlbum(filteredImage, nil, nil, nil)
                                showSaveSuccess = true
                            }) {
                                Text("Save Dogified")
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
                            Text("Pick a Photo to Paw-ify")
                                .font(.headline)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .foregroundColor(.blue)
                        }
                    }
                    if showSaveSuccess {
                        Text("Saved to Photos! 🐾")
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
                    ShareSheet(activityItems: ["Through my eyes | Through my dog's eyes", image]) {
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
                        filteredImage = applyDogVision(to: image)
                    }
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

                VStack(spacing: 24) {
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

                    Text("See the world through your dog's eyes")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))

                    VStack(spacing: 16) {
                        Button(action: {
                            mode = .camera
                        }) {
                            Text("Fetch the View!")
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
                            Text("Take a Pawtrait")
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
                            Text("Paw-ify a Photo")
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

                    Spacer()
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

    func applyDogVision(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let filter = CIFilter.colorMatrix()
        filter.inputImage = ciImage
        filter.rVector = CIVector(x: 0.625, y: 0,    z: 0, w: 0)
        filter.gVector = CIVector(x: 0.375, y: 0.3,  z: 0.3, w: 0)
        filter.bVector = CIVector(x: 0,     y: 0,    z: 0.7, w: 0)
        let context = CIContext()
        guard let output = filter.outputImage,
              let cgimg = context.createCGImage(output, from: output.extent)
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
