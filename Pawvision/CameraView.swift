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

enum VisionType: String {
    case dog = "Dog Vision"
    case bee = "Bee Vision"
    case snake = "Snake Vision"
    case bird = "Bird Vision"
}

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

    // Camera switch and zoom properties
    @Binding var cameraPosition: AVCaptureDevice.Position
    @Binding var zoomFactor: CGFloat
    @Binding var switchCameraRequested: Bool

    // Vision mode
    @Binding var visionMode: VisionType

    func makeCoordinator() -> VideoDelegate {
        VideoDelegate(
            captureRequested: $captureRequested,
            onCapture: onCapture,
            recordingRequested: $recordingRequested,
            stopRecordingRequested: $stopRecordingRequested,
            onRecordingComplete: onRecordingComplete,
            cameraPosition: $cameraPosition,
            zoomFactor: $zoomFactor,
            switchCameraRequested: $switchCameraRequested,
            visionMode: $visionMode
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

        // Camera switch and zoom
        var cameraPosition: Binding<AVCaptureDevice.Position>
        var zoomFactor: Binding<CGFloat>
        var switchCameraRequested: Binding<Bool>
        var currentDevice: AVCaptureDevice?
        var videoOutput: AVCaptureVideoDataOutput?

        // Vision mode
        var visionMode: Binding<VisionType>

        // Bee Vision filters - pattern and texture enhancement
        let luminanceSharpen = CIFilter.sharpenLuminance()
        let unsharpMask = CIFilter.unsharpMask()
        let beeColorMatrix = CIFilter.colorMatrix()

        // Snake Vision filters - thermal/infrared simulation
        let thermalBlur = CIFilter.gaussianBlur()
        let falseColor = CIFilter.falseColor()
        var thermalCubeData: Data?
        let thermalCubeSize = 64

        // Bird Vision filters - enhanced acuity
        let birdSharpen = CIFilter.sharpenLuminance()
        let birdUnsharp = CIFilter.unsharpMask()
        let birdColorMatrix = CIFilter.colorMatrix()

        init(captureRequested: Binding<Bool>,
             onCapture: @escaping (_ original: UIImage, _ filtered: UIImage) -> Void,
             recordingRequested: Binding<Bool>,
             stopRecordingRequested: Binding<Bool>,
             onRecordingComplete: @escaping (URL) -> Void,
             cameraPosition: Binding<AVCaptureDevice.Position>,
             zoomFactor: Binding<CGFloat>,
             switchCameraRequested: Binding<Bool>,
             visionMode: Binding<VisionType>) {
            self.captureRequested = captureRequested
            self.onCapture = onCapture
            self.recordingRequested = recordingRequested
            self.stopRecordingRequested = stopRecordingRequested
            self.onRecordingComplete = onRecordingComplete
            self.cameraPosition = cameraPosition
            self.zoomFactor = zoomFactor
            self.switchCameraRequested = switchCameraRequested
            self.visionMode = visionMode
            super.init()

            // Bee Vision color matrix: suppress red channel, emphasize blue-green
            // Red channel suppressed (bees cannot see red)
            // Blue-green emphasized (bees see UV, blue, green spectrum)
            beeColorMatrix.rVector = CIVector(x: 0.1,  y: 0.35, z: 0.05, w: 0)  // Red heavily suppressed -> shifts to green
            beeColorMatrix.gVector = CIVector(x: 0.05, y: 0.8,  z: 0.2,  w: 0)  // Green emphasized with blue tint
            beeColorMatrix.bVector = CIVector(x: 0.05, y: 0.15, z: 0.85, w: 0)  // Blue emphasized
            beeColorMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)

            // Luminance sharpening for texture detail
            luminanceSharpen.sharpness = 0.5

            // Unsharp mask for local contrast (reveals patterns)
            unsharpMask.radius = 2.0
            unsharpMask.intensity = 0.6

            // Snake Vision - moderate blur to simulate thermal sensor
            thermalBlur.radius = 7.0

            // Snake Vision - thermal palette base (will be blended for rainbow effect)
            falseColor.color0 = CIColor(red: 0.0, green: 0.0, blue: 0.8)   // Cold: blue
            falseColor.color1 = CIColor(red: 1.0, green: 0.2, blue: 0.0)   // Hot: red/orange

            // Create thermal rainbow LUT for CIColorCube
            thermalCubeData = createThermalCubeData(size: thermalCubeSize)

            // Bird Vision - extreme sharpness for acuity
            birdSharpen.sharpness = 0.6

            // Bird Vision - micro-detail separation (small radius to avoid halos)
            birdUnsharp.radius = 0.8
            birdUnsharp.intensity = 0.9

            // Bird Vision - neutral color (no tint)
            birdColorMatrix.rVector = CIVector(x: 1.0, y: 0.0, z: 0.0, w: 0)
            birdColorMatrix.gVector = CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0)
            birdColorMatrix.bVector = CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0)
            birdColorMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
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

        // Configure dog vision color matrix
        func configureDogVisionMatrix() {
            // Dog-vision matrix: mute red/green, preserve blue/yellow (original from main)
            colorMatrix.rVector = CIVector(x: 0.625, y: 0,    z: 0, w: 0)
            colorMatrix.gVector = CIVector(x: 0.375, y: 0.3,  z: 0.3, w: 0)
            colorMatrix.bVector = CIVector(x: 0,     y: 0,    z: 0.7, w: 0)
        }

        // Bee Vision – UV patterns simulated
        // Suppresses red, emphasizes blue-green, reveals hidden patterns via edge enhancement
        // Simulates how bees see "nectar guides" - UV patterns invisible to humans
        func applyBeeVisionFilter(to image: CIImage) -> CIImage? {
            // Step 1: Apply color shift (suppress red, emphasize blue-green)
            beeColorMatrix.inputImage = image
            guard let colorShifted = beeColorMatrix.outputImage else { return nil }

            // Step 2: Blend color-shifted with original (70% color shift, 30% original)
            let blendedColor = colorShifted.applyingFilter("CIColorMatrix", parameters: [
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.7)
            ]).composited(over: image.applyingFilter("CIColorMatrix", parameters: [
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.3)
            ]))

            // Step 3: Strong unsharp mask for structure/pattern enhancement
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
        func applySnakeVisionFilter(to image: CIImage) -> CIImage? {
            guard let cubeData = thermalCubeData else { return nil }

            // Step 1: Moderate blur to simulate thermal sensor diffusion
            thermalBlur.inputImage = image
            thermalBlur.radius = 8.0
            guard let blurred = thermalBlur.outputImage else { return image }

            // Step 2: Adjust contrast to spread luminance values
            let adjusted = blurred.applyingFilter("CIColorControls", parameters: [
                "inputContrast": 1.2,
                "inputBrightness": 0.0,
                "inputSaturation": 0.0  // Desaturate to prepare for thermal mapping
            ])

            // Step 3: Apply thermal rainbow gradient using CIColorCube LUT
            let thermalColored = adjusted.applyingFilter("CIColorCube", parameters: [
                "inputCubeDimension": thermalCubeSize,
                "inputCubeData": cubeData
            ])

            // Step 4: Boost saturation of the thermal colors for vivid effect
            let vibrant = thermalColored.applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.4,
                "inputContrast": 1.05
            ])

            return vibrant
        }

        // Bird Vision – Enhanced visual acuity simulation
        // High local contrast, micro-detail separation, no color tint, no edge halos
        func applyBirdVisionFilter(to image: CIImage) -> CIImage? {
            // Step 1: Boost overall contrast (+8%)
            let contrastBoosted = image.applyingFilter("CIColorControls", parameters: [
                "inputContrast": 1.08,
                "inputSaturation": 1.0  // Keep saturation neutral
            ])

            // Step 2: Micro-detail unsharp mask (small radius avoids halos)
            birdUnsharp.inputImage = contrastBoosted
            guard let microDetail = birdUnsharp.outputImage else { return contrastBoosted }

            // Step 3: Luminance sharpening for edge acuity
            birdSharpen.inputImage = microDetail
            guard let sharpened = birdSharpen.outputImage else { return microDetail }

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

        func captureOutput(_ output: AVCaptureOutput,
                           didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection) {
            //Try to extract the camera's image buffer from this frame. If that fails (i.e.
            //it's nil), immediately exit the function—because there's nothing to
            //process—otherwise continue with pixelBuffer safely unwrapped.
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

            // Set video dimensions from camera input on first frame
            if videoDimensions.width == 1080 && videoDimensions.height == 1920 {
                let extent = ciImage.extent
                videoDimensions = (width: Int(extent.width), height: Int(extent.height))
            }

            // Apply vision filter based on current mode
            let currentMode = visionMode.wrappedValue
            let filteredCI: CIImage

            switch currentMode {
            case .dog:
                // Dog Vision – Dichromatic simulation
                configureDogVisionMatrix()
                colorMatrix.inputImage = ciImage
                guard let dogFiltered = colorMatrix.outputImage else { return }
                filteredCI = dogFiltered
            case .bee:
                // Bee Vision – UV patterns simulated
                guard let beeFiltered = applyBeeVisionFilter(to: ciImage) else { return }
                filteredCI = beeFiltered
            case .snake:
                // Snake Vision – Infrared heat-map
                guard let snakeFiltered = applySnakeVisionFilter(to: ciImage) else { return }
                filteredCI = snakeFiltered
            case .bird:
                // Bird Vision – Enhanced acuity
                guard let birdFiltered = applyBirdVisionFilter(to: ciImage) else { return }
                filteredCI = birdFiltered
            }

            guard let cgImage = context.createCGImage(filteredCI, from: filteredCI.extent)
            else { return }

            DispatchQueue.main.async {
                self.previewLayer.contents = cgImage

                // Handle camera switch request
                if self.switchCameraRequested.wrappedValue {
                    self.switchCameraRequested.wrappedValue = false
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.switchCamera()
                    }
                }

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

        // MARK: - Camera Switch Methods

        func switchCamera() {
            guard let session = session else { return }

            session.beginConfiguration()

            // Remove existing input
            if let currentInput = session.inputs.first as? AVCaptureDeviceInput {
                session.removeInput(currentInput)
            }

            // Determine new camera position
            let newPosition: AVCaptureDevice.Position = cameraPosition.wrappedValue == .back ? .front : .back

            // Get new camera device
            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
                session.commitConfiguration()
                return
            }

            if session.canAddInput(newInput) {
                session.addInput(newInput)
                currentDevice = newCamera

                // Update video orientation for the output connection
                if let output = videoOutput, let connection = output.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                    // Mirror front camera for natural preview
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = (newPosition == .front)
                    }
                }

                // Update the binding
                DispatchQueue.main.async {
                    self.cameraPosition.wrappedValue = newPosition
                    // Reset zoom when switching cameras
                    self.zoomFactor.wrappedValue = 1.0
                    self.applyZoom(1.0)
                }
            }

            session.commitConfiguration()
        }

        // MARK: - Zoom Methods

        func applyZoom(_ factor: CGFloat) {
            guard let device = currentDevice else { return }

            let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 5.0) // Cap at 5x for usability
            let clampedFactor = max(1.0, min(factor, maxZoom))

            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clampedFactor
                device.unlockForConfiguration()
            } catch {
                print("Failed to set zoom: \(error)")
            }
        }

        func getMaxZoomFactor() -> CGFloat {
            guard let device = currentDevice else { return 5.0 }
            return min(device.activeFormat.videoMaxZoomFactor, 5.0)
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

        // Camera input - use the bound camera position
        let position = cameraPosition
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: position),
              let input = try? AVCaptureDeviceInput(device: camera)
        else { return view }
        session.addInput(input)
        context.coordinator.currentDevice = camera

        // Video output
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(context.coordinator, queue: .global())
        session.addOutput(output)
        context.coordinator.videoOutput = output

        // Force video orientation to portrait
        if let connection = output.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            // Mirror front camera for natural preview
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = (position == .front)
            }
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

        // Apply initial zoom
        context.coordinator.applyZoom(zoomFactor)

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
            preview.setAffineTransform(.identity)
        }
        context.coordinator.captureRequested = $captureRequested
        context.coordinator.onCapture = onCapture
        context.coordinator.recordingRequested = $recordingRequested
        context.coordinator.stopRecordingRequested = $stopRecordingRequested
        context.coordinator.onRecordingComplete = onRecordingComplete
        context.coordinator.cameraPosition = $cameraPosition
        context.coordinator.zoomFactor = $zoomFactor
        context.coordinator.switchCameraRequested = $switchCameraRequested
        context.coordinator.visionMode = $visionMode

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
        context.coordinator.cameraPosition = $cameraPosition
        context.coordinator.zoomFactor = $zoomFactor
        context.coordinator.switchCameraRequested = $switchCameraRequested
        context.coordinator.visionMode = $visionMode

        // Apply zoom when the binding changes
        context.coordinator.applyZoom(zoomFactor)
    }
}
