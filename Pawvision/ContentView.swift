//
//  ContentView.swift
//  PawvisionApp
//
//  Created by Vikrant Singh on 5/12/25.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    enum ScreenMode {
        case home, camera, capture, convert
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

    // Share sheet state for comparison sharing
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        switch mode {
        case .camera:
            ZStack {
                Color.black
                    .ignoresSafeArea()

                CameraView(captureRequested: .constant(false), onCapture: { _, _ in })
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    Button("Stop Camera") {
                        mode = .home
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(8)
                    .padding(.bottom, 40)
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
                                let size = CGSize(width: original.size.width + filtered.size.width,
                                                  height: max(original.size.height, filtered.size.height))
                                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                                original.draw(in: CGRect(origin: .zero, size: original.size))
                                filtered.draw(in: CGRect(origin: CGPoint(x: original.size.width, y: 0),
                                                         size: filtered.size))
                                let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                                UIGraphicsEndImageContext()
                                if let image = finalImage {
                                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
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
                                let size = CGSize(width: original.size.width + filtered.size.width,
                                                  height: max(original.size.height, filtered.size.height))
                                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                                original.draw(in: CGRect(origin: .zero, size: original.size))
                                filtered.draw(in: CGRect(origin: CGPoint(x: original.size.width, y: 0),
                                                         size: filtered.size))
                                let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                                UIGraphicsEndImageContext()
                                if let image = finalImage {
                                    shareImage = image
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
                    CameraView(captureRequested: $captureRequested, onCapture: { original, filtered in
                        capturedOriginal = original
                        capturedFiltered = filtered
                        showSaveOptions = true
                    })
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
                    ShareSheet(activityItems: [image])
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
                                let original = selectedImage
                                let size = CGSize(width: original.size.width + filteredImage.size.width,
                                                  height: max(original.size.height, filteredImage.size.height))
                                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                                original.draw(in: CGRect(origin: .zero, size: original.size))
                                filteredImage.draw(in: CGRect(origin: CGPoint(x: original.size.width, y: 0),
                                                             size: filteredImage.size))
                                let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                                UIGraphicsEndImageContext()
                                if let image = finalImage {
                                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
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
                                let original = selectedImage
                                let size = CGSize(width: original.size.width + filteredImage.size.width,
                                                  height: max(original.size.height, filteredImage.size.height))
                                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                                original.draw(in: CGRect(origin: .zero, size: original.size))
                                filteredImage.draw(in: CGRect(origin: CGPoint(x: original.size.width, y: 0),
                                                             size: filteredImage.size))
                                let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                                UIGraphicsEndImageContext()
                                if let image = finalImage {
                                    shareImage = image
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
                    ShareSheet(activityItems: [image])
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

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
