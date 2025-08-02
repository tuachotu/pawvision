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
    
    // Video recording properties
    @Binding var recordingRequested: Bool
    @Binding var stopRecordingRequested: Bool
    var onRecordingComplete: (URL) -> Void

    func makeCoordinator() -> VideoDelegate {
        VideoDelegate(
            captureRequested: $captureRequested, 
            onCapture: onCapture,
            recordingRequested: $recordingRequested,
            stopRecordingRequested: $stopRecordingRequested,
            onRecordingComplete: onRecordingComplete
        )
    }

    /// `VideoDelegate` owns the camera session, applies a dog-vision color filter
    /// to each incoming video frame, and writes the result into a CALayer for display.
    class VideoDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
        var session: AVCaptureSession?
        let context = CIContext()
        let colorMatrix = CIFilter.colorMatrix()
        
        // Video recording components
        var movieOutput: AVCaptureMovieFileOutput?
        var assetWriter: AVAssetWriter?
        var assetWriterVideoInput: AVAssetWriterInput?
        var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
        var outputURL: URL?
        var isRecording = false
        var recordingStartTime: CMTime?
        var videoDimensions: (width: Int, height: Int) = (1080, 1920)

        var captureRequested: Binding<Bool>
        var onCapture: (_ original: UIImage, _ filtered: UIImage) -> Void
        
        // Video recording bindings
        var recordingRequested: Binding<Bool>
        var stopRecordingRequested: Binding<Bool>
        var onRecordingComplete: (URL) -> Void

        init(captureRequested: Binding<Bool>, 
             onCapture: @escaping (_ original: UIImage, _ filtered: UIImage) -> Void,
             recordingRequested: Binding<Bool>,
             stopRecordingRequested: Binding<Bool>,
             onRecordingComplete: @escaping (URL) -> Void) {
            self.captureRequested = captureRequested
            self.onCapture = onCapture
            self.recordingRequested = recordingRequested
            self.stopRecordingRequested = stopRecordingRequested
            self.onRecordingComplete = onRecordingComplete
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
            
            // Set video dimensions from camera input on first frame
            if videoDimensions.width == 1080 && videoDimensions.height == 1920 {
                let extent = ciImage.extent
                videoDimensions = (width: Int(extent.width), height: Int(extent.height))
            }

            colorMatrix.inputImage = ciImage
            guard let filteredCI = colorMatrix.outputImage,
                  let cgImage = context.createCGImage(filteredCI, from: filteredCI.extent)
            else { return }

            DispatchQueue.main.async {
                self.previewLayer.contents = cgImage
                
                // Handle video recording start/stop
                if self.recordingRequested.wrappedValue && !self.isRecording {
                    self.recordingRequested.wrappedValue = false
                    self.startRecording()
                }
                
                if self.stopRecordingRequested.wrappedValue && self.isRecording {
                    self.stopRecordingRequested.wrappedValue = false
                    self.stopRecording()
                }
                
                // Save filtered image if requested
                if self.captureRequested.wrappedValue {
                    self.captureRequested.wrappedValue = false
                    let filtered = UIImage(cgImage: cgImage)
                    guard let cgOriginal = self.context.createCGImage(ciImage, from: ciImage.extent) else { return }
                    let original = UIImage(cgImage: cgOriginal)
                    self.onCapture(original, filtered)
                }
            }
            
            // If recording, write the filtered frame to video
            if isRecording {
                writeFilteredFrameToVideo(filteredCI, originalTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            }
        }

        lazy var previewLayer: CALayer = {
            let layer = CALayer()
            layer.contentsGravity = .resizeAspectFill
            return layer
        }()
        
        // MARK: - Video Recording Methods
        
        func startRecording() {
            guard !isRecording else { return }
            
            // Create output URL
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            outputURL = documentsPath.appendingPathComponent("filtered_video_\(Date().timeIntervalSince1970).mov")
            
            guard let outputURL = outputURL else { return }
            
            do {
                // Set up asset writer
                assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
                
                // Video settings for filtered output
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: videoDimensions.width,
                    AVVideoHeightKey: videoDimensions.height,
                    AVVideoCompressionPropertiesKey: [
                        AVVideoAverageBitRateKey: 6000000
                    ]
                ]
                
                assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                assetWriterVideoInput?.expectsMediaDataInRealTime = true
                
                // Pixel buffer attributes
                let pixelBufferAttributes: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                    kCVPixelBufferWidthKey as String: videoDimensions.width,
                    kCVPixelBufferHeightKey as String: videoDimensions.height
                ]
                
                guard let videoInput = assetWriterVideoInput,
                      let writer = assetWriter else { return }
                
                assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: videoInput,
                    sourcePixelBufferAttributes: pixelBufferAttributes
                )
                
                if writer.canAdd(videoInput) {
                    writer.add(videoInput)
                }
                
                writer.startWriting()
                recordingStartTime = nil // Will be set on first frame
                isRecording = true
                
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
        
        func stopRecording() {
            guard isRecording else { return }
            
            isRecording = false
            
            assetWriterVideoInput?.markAsFinished()
            assetWriter?.finishWriting { [weak self] in
                guard let self = self, let outputURL = self.outputURL else { return }
                
                DispatchQueue.main.async {
                    self.onRecordingComplete(outputURL)
                    
                    // Clean up
                    self.assetWriter = nil
                    self.assetWriterVideoInput = nil
                    self.assetWriterPixelBufferInput = nil
                    self.recordingStartTime = nil
                    self.outputURL = nil
                }
            }
        }
        
        func writeFilteredFrameToVideo(_ filteredImage: CIImage, originalTime: CMTime) {
            guard isRecording,
                  let assetWriterVideoInput = assetWriterVideoInput,
                  let pixelBufferInput = assetWriterPixelBufferInput,
                  assetWriterVideoInput.isReadyForMoreMediaData else { return }
            
            // Set recording start time on first frame
            if recordingStartTime == nil {
                recordingStartTime = originalTime
                assetWriter?.startSession(atSourceTime: originalTime)
            }
            
            var pixelBuffer: CVPixelBuffer?
            let attributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: videoDimensions.width,
                kCVPixelBufferHeightKey as String: videoDimensions.height
            ]
            
            let status = CVPixelBufferCreate(kCFAllocatorDefault, videoDimensions.width, videoDimensions.height, kCVPixelFormatType_32BGRA, attributes as CFDictionary, &pixelBuffer)
            
            guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return }
            
            context.render(filteredImage, to: buffer)
            pixelBufferInput.append(buffer, withPresentationTime: originalTime)
        }
        
        // MARK: - AVCaptureFileOutputRecordingDelegate
        
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            // This delegate method is for AVCaptureMovieFileOutput, which we're not using
            // We're using custom AVAssetWriter for filtered video recording
        }
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
        context.coordinator.recordingRequested = $recordingRequested
        context.coordinator.stopRecordingRequested = $stopRecordingRequested
        context.coordinator.onRecordingComplete = onRecordingComplete

        return view
    }
    /// Called whenever SwiftUI updates layout or size.
    /// Simply resizes the preview layer to match the UIView’s new bounds.
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer.frame = uiView.bounds
        context.coordinator.captureRequested = $captureRequested
        context.coordinator.onCapture = onCapture
        context.coordinator.recordingRequested = $recordingRequested
        context.coordinator.stopRecordingRequested = $stopRecordingRequested
        context.coordinator.onRecordingComplete = onRecordingComplete
    }
}
