import AVFoundation
import CoreImage
import SwiftUI

public final class CameraFeedManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published public var isRunning: Bool = false
    @Published public var authorizationStatus: AVAuthorizationStatus = .notDetermined
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.mentora.swift.cameraQueue")
    public var onFrameCaptured: ((CMSampleBuffer) -> Void)?
    
    public override init() {
        super.init()
        checkPermissions()
    }
    
    private func checkPermissions() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupSession()
                }
            }
        default:
            break
        }
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .hd1280x720
            
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                self.captureSession.commitConfiguration()
                return
            }
            
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: self.sessionQueue)
            
            if self.captureSession.canAddOutput(output) {
                self.captureSession.addOutput(output)
            }
            
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.isRunning = true
            }
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }
        onFrameCaptured?(sampleBuffer)
    }
    
    public func stop() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isRunning = false
                }
            }
        }
    }
}
