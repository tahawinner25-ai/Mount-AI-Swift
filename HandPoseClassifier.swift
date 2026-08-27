import SwiftUI
import Vision
import CoreML
import Observation

@Observable
public final class HandPoseClassifier {
    public var recognizedSign: String = "Placez votre main face à la caméra..."
    public var confidence: Double = 0.0
    public var detectedJoints: [CGPoint] = []
    public var isHandDetected: Bool = false
    public var inferenceTimeMs: Double = 0.0
    public var activeLandmarksCount: Int = 0
    public var detectedPhonemeIpa: String = "[a]"
    
    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        return request
    }()
    
    public init() {}
    
    public func processFrame(_ sampleBuffer: CMSampleBuffer) {
        let startTime = CACurrentMediaTime()
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                Task { @MainActor in
                    self.isHandDetected = false
                    self.recognizedSign = "Recherche de repères articulaires..."
                    self.detectedJoints = []
                    self.activeLandmarksCount = 0
                }
                return
            }
            
            let allPoints = try observation.recognizedPoints(.all)
            var pointsList: [CGPoint] = []
            
            for (_, point) in allPoints where point.confidence > 0.25 {
                pointsList.append(CGPoint(x: point.location.x, y: 1.0 - point.location.y))
            }
            
            guard let wrist = allPoints[.wrist],
                  let thumbTip = allPoints[.thumbTip],
                  let indexTip = allPoints[.indexTip],
                  let middleTip = allPoints[.middleTip],
                  let ringTip = allPoints[.ringTip],
                  let littleTip = allPoints[.littleTip] else { return }
            
            // Calculs de géométrie euclidienne haute précision
            let thumbIndexDist = hypot(thumbTip.location.x - indexTip.location.x, thumbTip.location.y - indexTip.location.y)
            let indexWristDist = hypot(indexTip.location.x - wrist.location.x, indexTip.location.y - wrist.location.y)
            let middleWristDist = hypot(middleTip.location.x - wrist.location.x, middleTip.location.y - wrist.location.y)
            let ringWristDist = hypot(ringTip.location.x - wrist.location.x, ringTip.location.y - wrist.location.y)
            let littleWristDist = hypot(littleTip.location.x - wrist.location.x, littleTip.location.y - wrist.location.y)
            
            var result = "Geste en analyse..."
            var conf = 0.85
            var ipa = "[a]"
            
            // Classification dactylologique LSF & Gestes universels
            if thumbIndexDist < 0.055 && middleWristDist > 0.22 && ringWristDist > 0.22 {
                result = "Signe : 'OK' / 'O' 👌"
                conf = 0.97
                ipa = "[o]"
            } else if indexWristDist > 0.26 && middleWristDist > 0.26 && ringWristDist < 0.19 && littleWristDist < 0.19 {
                result = "Signe : 'V (Victoire / Paix)' ✌️"
                conf = 0.95
                ipa = "[v]"
            } else if indexWristDist > 0.26 && thumbTip.location.x < indexTip.location.x && middleWristDist < 0.19 {
                result = "Signe : 'L' 👆"
                conf = 0.93
                ipa = "[l]"
            } else if indexWristDist > 0.26 && middleWristDist > 0.26 && ringWristDist > 0.22 && littleWristDist > 0.22 && thumbIndexDist > 0.11 {
                result = "Signe : 'B' / Main Ouverte ✋"
                conf = 0.98
                ipa = "[b]"
            } else if indexWristDist < 0.19 && middleWristDist < 0.19 && ringWristDist < 0.19 && littleWristDist < 0.19 {
                result = "Signe : 'A' / Poing Fermé ✊"
                conf = 0.92
                ipa = "[a]"
            } else if indexWristDist > 0.26 && middleWristDist < 0.19 && ringWristDist < 0.19 && littleWristDist < 0.19 {
                result = "Signe : '1' / Pointer ☝️"
                conf = 0.94
                ipa = "[œ̃]"
            }
            
            let elapsed = (CACurrentMediaTime() - startTime) * 1000.0
            
            Task { @MainActor in
                self.isHandDetected = true
                self.detectedJoints = pointsList
                self.recognizedSign = result
                self.confidence = conf
                self.detectedPhonemeIpa = ipa
                self.activeLandmarksCount = pointsList.count
                self.inferenceTimeMs = elapsed
            }
            
        } catch {
            print("Erreur Hand Pose: \(error)")
        }
    }
}
