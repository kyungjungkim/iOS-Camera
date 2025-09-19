//
//  FrameHandler.swift
//  B Camera
//
//  Created by Kyungjung Kim on 9/19/25.
//


import AVFoundation
import CoreImage
import Combine

class FrameHandler: NSObject, ObservableObject {
    @Published var frame: CGImage?
    private var permissionGranted = true
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()

    
    override init() {
        super.init()
        
        self.checkPermission()
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                self.permissionGranted = true
                
            case .notDetermined: // The user has not yet been asked for camera access.
                self.requestPermission()
                
        // Combine the two other cases into the default case
        default:
            self.permissionGranted = false
        }
    }
    
    func requestPermission() {
        // Strong reference not a problem here but might become one in the future.
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
        }
    }
    
    func setupCaptureSession() {
        let videoOutput = AVCaptureVideoDataOutput()
        
        guard permissionGranted else { return }
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera,for: .video, position: .back) ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        
        if let connection = videoOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                // Prefer new rotation-angle API when present in the SDK.
                // Use selector checks to avoid compile errors if building with older SDKs.
                let portraitAngle: CGFloat = 90
                // First, try the explicit "isVideoRotationAngleSupported:" check.
                if connection.responds(to: NSSelectorFromString("isVideoRotationAngleSupported:")),
                   let isSupportedIMP = connection.method(for: NSSelectorFromString("isVideoRotationAngleSupported:")) {
                    typealias Func = @convention(c) (AnyObject, Selector, CGFloat) -> Bool
                    let fn = unsafeBitCast(isSupportedIMP, to: Func.self)
                    if fn(connection, NSSelectorFromString("isVideoRotationAngleSupported:"), portraitAngle),
                       connection.responds(to: NSSelectorFromString("setVideoRotationAngle:")) {
                        (connection as AnyObject).setValue(portraitAngle, forKey: "videoRotationAngle")
                    } else {
                        // On iOS 17+, avoid deprecated videoOrientation fallback. Leave default orientation.
                    }
                } else if connection.responds(to: NSSelectorFromString("supportedVideoRotationAngles")),
                          let supported = (connection as AnyObject).value(forKey: "supportedVideoRotationAngles") as? Set<CGFloat>,
                          supported.contains(portraitAngle),
                          connection.responds(to: NSSelectorFromString("setVideoRotationAngle:")) {
                    (connection as AnyObject).setValue(portraitAngle, forKey: "videoRotationAngle")
                } else {
                    // On iOS 17+, avoid deprecated videoOrientation fallback. Leave default orientation.
                }
            } else {
                // iOS 16 and earlier: use videoOrientation
                connection.videoOrientation = .portrait
            }
        }
    }
}


extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        // All UI updates should be/ must be performed on the main queue.
        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return cgImage
    }
}
