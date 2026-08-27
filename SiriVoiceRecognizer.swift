import SwiftUI
import Speech
import AVFoundation
import Observation

// MARK: - Reconnaissance Vocale Temps Réel & Assistant Siri Vocal
// Pipeline de transcription en continu via SFSpeechRecognizer & AVAudioEngine

@Observable
public final class SiriVoiceRecognizer: NSObject, SFSpeechRecognizerDelegate {
    public var transcribedText: String = ""
    public var isRecording: Bool = false
    public var speechStatus: String = "Prêt pour écoute vocale..."
    public var detectedIntents: [String] = []
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    public override init() {
        super.init()
        speechRecognizer?.delegate = self
    }
    
    public func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            Task { @MainActor in
                switch authStatus {
                case .authorized:
                    self.speechStatus = "Autorisation vocale validée."
                case .denied, .restricted, .notDetermined:
                    self.speechStatus = "Accès au micro ou à Speech refusé."
                @unknown default:
                    break
                }
            }
        }
    }
    
    public func toggleRecording() {
        if audioEngine.isRunning {
            stopRecording()
        } else {
            do {
                try startRecording()
            } catch {
                speechStatus = "Erreur audio : \(error.localizedDescription)"
            }
        }
    }
    
    private func startRecording() throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Impossible de créer l'instance SFSpeechAudioBufferRecognitionRequest")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true // 100% On-Device Neural Engine (Privacy)
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            var isFinal = false
            
            if let result = result {
                Task { @MainActor in
                    self.transcribedText = result.bestTranscription.formattedString
                    self.parseVoiceCommands(self.transcribedText)
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                Task { @MainActor in
                    self.isRecording = false
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        Task { @MainActor in
            self.isRecording = true
            self.speechStatus = "Écoute active avec Apple Speech On-Device..."
        }
    }
    
    public func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
        speechStatus = "Écoute terminée."
    }
    
    private func parseVoiceCommands(_ text: String) {
        let lower = text.lowercased()
        if lower.contains("traduire") || lower.contains("signe") || lower.contains("scanner") {
            detectedIntents.append("Commande Siri détectée : Lancer SL2T Hand Scanner")
        } else if lower.contains("dyslexie") || lower.contains("lecture") {
            detectedIntents.append("Commande Siri détectée : Activer Lecteur Bionique")
        }
    }
}
