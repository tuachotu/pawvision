//
//  CameraView.swift
//  PawvisionApp
//
//  Created by Vikrant Singh on 5/12/25.
//

import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins

/// `CameraView` is a SwiftUI wrapper around a UIKit view that displays
/// a live, filtered camera feed. It uses `UIViewRepresentable` to bridge
/// AVFoundation’s capture session and Core Image filtering into SwiftUI.
struct CameraView: UIViewRepresentable {
    @Binding var captureRequested: Bool
    var onCapture: (_ original: UIImage, _ filtered: UIImage) -> Void

    func makeCoordinator() -> VideoDelegate {
        VideoDelegate(captureRequested: $captureRequested, onCapture: onCapture)
    }

    /// `VideoDelegate` owns the camera session, applies a dog-vision color filter
    /// to each incoming video frame, and writes the result into a CALayer for display.
    class VideoDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var session: AVCaptureSession?
        let context = CIContext()
        let colorMatrix = CIFilter.colorMatrix()

        var captureRequested: Binding<Bool>
        var onCapture: (_ original: UIImage, _ filtered: UIImage) -> Void

        init(captureRequested: Binding<Bool>, onCapture: @escaping (_ original: UIImage, _ filtered: UIImage) -> Void) {
            self.captureRequested = captureRequested
            self.onCapture = onCapture
            super.init()
            // Dog-vision matrix: mute red/green, preserve blue/yellow
            colorMatrix.rVector = CIVector(x: 0.625, y: 0,    z: 0, w: 0)
            colorMatrix.gVector = CIVector(x: 0.375, y: 0.3,  z: 0.3, w: 0)
            colorMatrix.bVector = CIVector(x: 0,     y: 0,    z: 0.7, w: 0)
        }

        func captureOutput(_ output: AVCaptureOutput,
                           didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection) {
            //Try to extract the camera’s image buffer from this frame. If that fails (i.e.
            //it’s nil), immediately exit the function—because there’s nothing to
            //process—otherwise continue with pixelBuffer safely unwrapped.
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

            colorMatrix.inputImage = ciImage
            guard let filteredCI = colorMatrix.outputImage,
                  let cgImage = context.createCGImage(filteredCI, from: filteredCI.extent)
            else { return }

            DispatchQueue.main.async {
                self.previewLayer.contents = cgImage
                // Save filtered image if requested
                if self.captureRequested.wrappedValue {
                    self.captureRequested.wrappedValue = false
                    let filtered = UIImage(cgImage: cgImage)
                    guard let cgOriginal = self.context.createCGImage(ciImage, from: ciImage.extent) else { return }
                    let original = UIImage(cgImage: cgOriginal)
                    self.onCapture(original, filtered)
                }
            }
        }

        lazy var previewLayer: CALayer = {
            let layer = CALayer()
            layer.contentsGravity = .resizeAspectFill
            return layer
        }()
    }

    /// Creates and configures the underlying UIView exactly once.
    /// - Sets up the AVCaptureSession with the back camera as input.
    /// - Hooks VideoDataOutput to our VideoDelegate for frame-by-frame filtering.
    /// - Adds the delegate’s previewLayer to the view and starts the session.
    /// - Observes device rotation to keep the preview filling the view.
    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        let session = AVCaptureSession()
        context.coordinator.session = session
        session.sessionPreset = .high

        // Camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: camera)
        else { return view }
        session.addInput(input)

        // Video output
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(context.coordinator, queue: .global())
        session.addOutput(output)

        // Force video orientation to portrait
        if let connection = output.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        // Preview layer from delegate

        view.layer.addSublayer(context.coordinator.previewLayer)
        context.coordinator.previewLayer.frame = view.bounds
        DispatchQueue.main.async {
            context.coordinator.previewLayer.frame = view.bounds
        }
        // Ensure preview layer is oriented correctly
        let preview = context.coordinator.previewLayer
        preview.frame = view.bounds
        // session.startRunning() call onto a background queue (.userInitiated)
        // to avoid blocking the main thread
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }

        // Handle rotation/resizing
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification,
                                               object: nil, queue: .main) { _ in
            let preview = context.coordinator.previewLayer
            preview.frame = view.bounds
//            // Keep portrait transform
           preview.setAffineTransform(.identity)
//            preview.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        }
        context.coordinator.captureRequested = $captureRequested
        context.coordinator.onCapture = onCapture

        return view
    }
    /// Called whenever SwiftUI updates layout or size.
    /// Simply resizes the preview layer to match the UIView’s new bounds.
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer.frame = uiView.bounds
        context.coordinator.captureRequested = $captureRequested
        context.coordinator.onCapture = onCapture
    }
}
