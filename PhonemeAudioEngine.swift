import AVFoundation
import Observation

@Observable
public final class PhonemeAudioEngine: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    public var isSpeaking: Bool = false
    public var currentWord: String = ""
    public var currentPhonemeIpa: String = ""
    
    public override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    public func pronounce(text: String, rate: Float = 0.42, pitch: Float = 1.05) {
        synthesizer.stopSpeaking(at: .immediate)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        
        currentWord = text
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
