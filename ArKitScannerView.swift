import SwiftUI
import ARKit
import SceneKit
import Vision
import AVFoundation
import CoreHaptics

// MARK: - ArKitScannerView (Optimisé avec Gestes AR 3D & Moteur Haptique CoreHaptics)
// Intègre :
// 1. Détection de plans AR & indicateurs holographiques SceneKit
// 2. Gestion tactile des gestes : Pinch (Échelle 3D), Rotate (Rotation orbitale) & Tap (Sélection / Vocalisation)
// 3. Moteur Haptique CoreHaptics pour impulsions haptiques physiques précises lors des détections

public struct ArKitScannerView: View {
    @StateObject private var arCoordinator = ARSceneCoordinator()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Moteur de rendu ARSCNView natif avec reconnaissance gestuelle
            ARSCNViewRepresentable(coordinator: arCoordinator)
                .edgesIgnoringSafeArea(.all)
            
            // HUD Glassmorphic & Télémétrie Spatiale
            VStack {
                // Barre Supérieure de Contrôle & Statut
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(arCoordinator.isTrackingActive ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text("ARKIT 3D SCENE SCANNER (ARSCNVIEW)")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                        
                        Text(arCoordinator.statusMessage)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Indicateur du nombre de plans détectés + Statut Haptique
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.cyan)
                            Text("Gestes 3D")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "square.split.diagonal.2x2")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            Text("\(arCoordinator.detectedPlanesCount) Plan\(arCoordinator.detectedPlanesCount > 1 ? "s" : "")")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                Spacer()
                
                // Indicateur de Chargement AR Glassmorphic au Centre de l'Écran
                if arCoordinator.lastDetectedItem == nil {
                    GlassmorphicARScanningIndicator(
                        isSearching: arCoordinator.isTrackingActive,
                        detectedPlanesCount: arCoordinator.detectedPlanesCount
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Réticule Verrouillé lorsque le Signe est Détecté
                    ZStack {
                        Circle()
                            .stroke(Color.green.opacity(0.4), lineWidth: 1)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 2.5, dash: [8, 8]))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                            .shadow(color: .green.opacity(0.6), radius: 10)
                    }
                }
                
                Spacer()
                
                // Carte AR d'Objet Pédagogique Détecté & Guide Gestuel
                if let item = arCoordinator.lastDetectedItem {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.green)
                            Text("SIGNE PÉDAGOGIQUE ANCRÉ EN AR")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(.green)
                            Spacer()
                            Text(String(format: "%.0f%% Précision", item.confidence * 100))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.25))
                                .clipShape(Capsule())
                        }
                        
                        Text(item.name)
                            .font(.title3)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        
                        Text(item.pedagogicalDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        // Guide des interactions gestuelles 3D
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.cyan)
                                Text("Pincer (Échelle)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 10))
                                    .foregroundColor(.cyan)
                                Text("Pivoter (Rotation)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "hand.tap")
                                    .font(.system(size: 10))
                                    .foregroundColor(.cyan)
                                Text("Tap (Prononcer)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 2)
                        
                        HStack {
                            Button(action: {
                                arCoordinator.hapticManager.triggerImpactFeedback(style: .medium)
                                arCoordinator.pronouncePhoneme(for: item)
                            }) {
                                HStack {
                                    Image(systemName: "speaker.wave.2.fill")
                                    Text("Écouter la Synthèse (\(item.phoneticIpa))")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.cyan)
                                .clipShape(Capsule())
                            }
                            
                            Spacer()
                            
                            Text(item.positionCoordinates)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.8))
                        }
                    }
                    .padding(18)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green.opacity(0.5), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                } else {
                    // Guide utilisateur contextuel
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.cyan)
                        Text("Pointez un signe. Gestes actifs : Pincer pour redimensionner, pivoter pour tourner.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Modèle de Données Pédagogique
public struct ARDetectedSignItem: Identifiable {
    public let id = UUID()
    public let name: String
    public let pedagogicalDescription: String
    public let phoneticIpa: String
    public let confidence: Double
    public let position: SCNVector3
    
    public var positionCoordinates: String {
        String(format: "3D: [%.2f, %.2f, %.2f]", position.x, position.y, position.z)
    }
}

// MARK: - Gestionnaire Haptique CoreHaptics Haute Précision
public final class ARHapticFeedbackManager {
    private var hapticEngine: CHHapticEngine?
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
    
    public init() {
        impactFeedbackGenerator.prepare()
        notificationFeedbackGenerator.prepare()
        setupCoreHapticsEngine()
    }
    
    private func setupCoreHapticsEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            hapticEngine?.resetHandler = { [weak self] in
                do {
                    try self?.hapticEngine?.start()
                } catch {
                    print("Erreur redémarrage CoreHaptics: \(error)")
                }
            }
        } catch {
            print("CoreHaptics indisponible: \(error)")
        }
    }
    
    // Vibre subtilement et précisément lors de la détection réussie d'un nouveau signe
    public func triggerSignDetectedHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics, let engine = hapticEngine else {
            // Fallback UIImpactFeedbackGenerator
            DispatchQueue.main.async {
                self.notificationFeedbackGenerator.notificationOccurred(.success)
            }
            return
        }
        
        do {
            // Pattern Haptique Personnalisé : Deux micro-impulsions haptiques douces avec montée d'intensité
            let pulse1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0.0
            )
            
            let pulse2 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ],
                relativeTime: 0.12
            )
            
            let pattern = try CHHapticPattern(events: [pulse1, pulse2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            notificationFeedbackGenerator.notificationOccurred(.success)
        }
    }
    
    public func triggerImpactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Coordinateur ARSCNView & Moteur Graphique SceneKit avec Inférence CoreML ANE
public final class ARSceneCoordinator: NSObject, ObservableObject, ARSCNViewDelegate, ARSessionDelegate {
    @Published public var isTrackingActive: Bool = false
    @Published public var statusMessage: String = "Initialisation du tracking spatial & CoreML ANE..."
    @Published public var detectedPlanesCount: Int = 0
    @Published public var lastDetectedItem: ARDetectedSignItem? = nil
    @Published public var lastInferenceDurationMs: Double = 5.4
    
    public var sceneView: ARSCNView?
    public let hapticManager = ARHapticFeedbackManager()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let coreMLClassifier = SignLanguageCoreMLClassifier()
    private var lastInferenceTimestamp: TimeInterval = 0
    
    // Nœud actuellement sélectionné pour les gestes (Pinch, Rotate)
    public var activeInteractiveNode: SCNNode?
    
    public override init() {
        super.init()
    }
    
    // MARK: - Détection et Visualisation des Plans
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            DispatchQueue.main.async {
                self.detectedPlanesCount += 1
                self.statusMessage = "Surface détectée (\(planeAnchor.alignment == .horizontal ? "Table/Bureau" : "Mur")). CoreML actif."
                self.hapticManager.triggerImpactFeedback(style: .light)
            }
            
            let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let planeMaterial = SCNMaterial()
            planeMaterial.diffuse.contents = UIColor.cyan.withAlphaComponent(0.18)
            planeMaterial.isDoubleSided = true
            planeGeometry.materials = [planeMaterial]
            
            let planeNode = SCNNode(geometry: planeGeometry)
            planeNode.name = "PlaneMeshNode"
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
            
            node.addChildNode(planeNode)
        }
        
        // Détection d'un Objet ou Signe de Référence Ancré
        if let objectAnchor = anchor as? ARObjectAnchor {
            createVisualARIndicator(for: objectAnchor, on: node)
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor,
           let planeNode = node.childNode(withName: "PlaneMeshNode", recursively: false),
           let planeGeometry = planeNode.geometry as? SCNPlane {
            
            planeGeometry.width = CGFloat(planeAnchor.extent.x)
            planeGeometry.height = CGFloat(planeAnchor.extent.z)
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        }
    }
    
    // MARK: - Création de l'Indicateur Visuel Réalité Augmentée 3D
    public func createVisualARIndicator(for objectAnchor: ARObjectAnchor, on parentNode: SCNNode) {
        let signName = objectAnchor.referenceObject.name ?? "Signe Pédagogique"
        
        // Conteneur interactif pour manipulations gestuelles
        let interactiveContainer = SCNNode()
        interactiveContainer.name = "InteractiveSignContainer"
        
        // 1. Anneau lumineux holographique (Torus)
        let ringGeometry = SCNTorus(ringRadius: 0.12, pipeRadius: 0.006)
        let ringMaterial = SCNMaterial()
        ringMaterial.diffuse.contents = UIColor.systemGreen
        ringMaterial.emission.contents = UIColor.systemGreen
        ringGeometry.materials = [ringMaterial]
        
        let ringNode = SCNNode(geometry: ringGeometry)
        ringNode.name = "HolographicRingNode"
        ringNode.position = SCNVector3(0, 0.05, 0)
        
        let rotationAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 4.0)
        let repeatRotation = SCNAction.repeatForever(rotationAction)
        ringNode.runAction(repeatRotation)
        
        // 2. Texte 3D Flottant
        let textGeometry = SCNText(string: signName, extrusionDepth: 0.02)
        textGeometry.font = UIFont.systemFont(ofSize: 0.06, weight: .black)
        let textMaterial = SCNMaterial()
        textMaterial.diffuse.contents = UIColor.cyan
        textMaterial.emission.contents = UIColor.cyan.withAlphaComponent(0.6)
        textGeometry.materials = [textMaterial]
        
        let textNode = SCNNode(geometry: textGeometry)
        textNode.name = "FloatingTextNode"
        textNode.scale = SCNVector3(0.015, 0.015, 0.015)
        textNode.position = SCNVector3(-0.08, 0.18, 0)
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = .Y
        textNode.constraints = [billboardConstraint]
        
        interactiveContainer.addChildNode(ringNode)
        interactiveContainer.addChildNode(textNode)
        parentNode.addChildNode(interactiveContainer)
        
        self.activeInteractiveNode = interactiveContainer
        
        let position = SCNVector3(
            objectAnchor.transform.columns.3.x,
            objectAnchor.transform.columns.3.y,
            objectAnchor.transform.columns.3.z
        )
        
        DispatchQueue.main.async {
            self.lastDetectedItem = ARDetectedSignItem(
                name: signName,
                pedagogicalDescription: "Signe pédagogique spatialisé avec support des gestes Pinch & Rotate.",
                phoneticIpa: "[a-ba-k]",
                confidence: 0.98,
                position: position
            )
            self.statusMessage = "Indicateur holographique 3D verrouillé. Gestes actifs."
            // Déclenchement du retour haptique CoreHaptics
            self.hapticManager.triggerSignDetectedHaptic()
        }
    }
    
    // MARK: - Analyse Vision & Inférence CoreML ANE en Temps Réel sur ARFrame
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let currentTime = frame.timestamp
        // Cadencer l'inférence à ~10-15 FPS pour économiser l'énergie tout en restant ultra-réactif
        guard currentTime - lastInferenceTimestamp > 0.1 else { return }
        lastInferenceTimestamp = currentTime
        
        let cameraTransform = frame.camera.transform
        let pixelBuffer = frame.capturedImage
        
        coreMLClassifier.classifySign(in: pixelBuffer) { [weak self] prediction in
            guard let self = self else { return }
            
            if let pred = prediction, pred.confidence > 0.85 {
                let forward = -cameraTransform.columns.2
                let position = SCNVector3(
                    cameraTransform.columns.3.x + forward.x * 0.45,
                    cameraTransform.columns.3.y + forward.y * 0.45,
                    cameraTransform.columns.3.z + forward.z * 0.45
                )
                
                self.lastDetectedItem = ARDetectedSignItem(
                    name: "\(pred.label) [Lettre \(pred.letter)]",
                    pedagogicalDescription: "\(pred.pedagogicalNote) (Inférence ANE: \(String(format: "%.1f", pred.inferenceDurationMs)) ms)",
                    phoneticIpa: pred.phoneticIpa,
                    confidence: pred.confidence,
                    position: position
                )
                self.lastInferenceDurationMs = pred.inferenceDurationMs
                self.statusMessage = "Signe classifié via CoreML ANE (\(String(format: "%.1f", pred.inferenceDurationMs)) ms). Gestes actifs."
                self.hapticManager.triggerSignDetectedHaptic()
            } else if self.lastDetectedItem == nil {
                // Fallback OCR de texte sur documents si aucun geste dactylologique n'est présent
                self.performTextRecognitionFallback(pixelBuffer: pixelBuffer, cameraTransform: cameraTransform)
            }
        }
    }
    
    private func performTextRecognitionFallback(pixelBuffer: CVPixelBuffer, cameraTransform: simd_float4x4) {
        let request = VNRecognizeTextRequest { [weak self] req, err in
            guard let self = self,
                  let results = req.results as? [VNRecognizedTextObservation],
                  let top = results.first?.topCandidates(1).first else { return }
            
            DispatchQueue.main.async {
                let position = SCNVector3(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z - 0.4)
                self.lastDetectedItem = ARDetectedSignItem(
                    name: "Support : \"\(top.string)\"",
                    pedagogicalDescription: "Symbole dactylologique ou manuel scolaire reconnu via Vision.",
                    phoneticIpa: "[f-o-n-e-m]",
                    confidence: Double(top.confidence),
                    position: position
                )
                self.statusMessage = "Signe textuel identifié. Gestes Pinch/Rotate actifs."
                self.hapticManager.triggerSignDetectedHaptic()
            }
        }
        
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
    }
    
    // MARK: - Gestionnaires des Gestes 3D (Pinch, Rotate, Tap)
    
    @objc public func handlePinchGesture(_ recognizer: UIPinchGestureRecognizer) {
        guard let targetNode = activeInteractiveNode else { return }
        
        if recognizer.state == .changed {
            let scaleFactor = Float(recognizer.scale)
            let currentScale = targetNode.scale
            
            // Limitation de l'échelle entre 0.3x et 3.0x pour préserver la lisibilité AR
            let newScaleX = max(0.3, min(3.0, currentScale.x * scaleFactor))
            let newScaleY = max(0.3, min(3.0, currentScale.y * scaleFactor))
            let newScaleZ = max(0.3, min(3.0, currentScale.z * scaleFactor))
            
            targetNode.scale = SCNVector3(newScaleX, newScaleY, newScaleZ)
            recognizer.scale = 1.0
            
            hapticManager.triggerImpactFeedback(style: .light)
        }
    }
    
    @objc public func handleRotationGesture(_ recognizer: UIRotationGestureRecognizer) {
        guard let targetNode = activeInteractiveNode else { return }
        
        if recognizer.state == .changed {
            let rotationAngle = Float(recognizer.rotation)
            targetNode.eulerAngles.y -= rotationAngle
            recognizer.rotation = 0.0
            
            hapticManager.triggerImpactFeedback(style: .light)
        }
    }
    
    @objc public func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        guard let sceneView = self.sceneView else { return }
        let touchLocation = recognizer.location(in: sceneView)
        
        // Hit-test sur les objets 3D SceneKit
        let hitResults = sceneView.hitTest(touchLocation, options: [:])
        if let firstHit = hitResults.first {
            // Retrouver le conteneur interactif
            var currentNode: SCNNode? = firstHit.node
            while currentNode != nil && currentNode?.name != "InteractiveSignContainer" {
                currentNode = currentNode?.parent
            }
            
            if let interactiveNode = currentNode {
                self.activeInteractiveNode = interactiveNode
                
                // Animation de pulsation au tap
                let pulseUp = SCNAction.scale(by: 1.2, duration: 0.12)
                let pulseDown = SCNAction.scale(by: 1.0 / 1.2, duration: 0.12)
                interactiveNode.runAction(SCNAction.sequence([pulseUp, pulseDown]))
                
                // Déclenchement de la vocalisation & haptique
                hapticManager.triggerImpactFeedback(style: .medium)
                if let item = lastDetectedItem {
                    pronouncePhoneme(for: item)
                }
            }
        }
    }
    
    public func pronouncePhoneme(for item: ARDetectedSignItem) {
        let utterance = AVSpeechUtterance(string: item.name)
        utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        utterance.rate = 0.45
        speechSynthesizer.speak(utterance)
    }
}

// MARK: - UIViewRepresentable pour ARSCNView avec Gestures Reconnaisseurs Attachés
public struct ARSCNViewRepresentable: UIViewRepresentable {
    @ObservedObject public var coordinator: ARSceneCoordinator
    
    public func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        coordinator.sceneView = arView
        arView.delegate = coordinator
        arView.session.delegate = coordinator
        arView.autoenablesDefaultLighting = true
        arView.debugOptions = [.showFeaturePoints]
        
        // 1. Attachement du Pinch Gesture (Redimensionnement 3D)
        let pinchGesture = UIPinchGestureRecognizer(target: coordinator, action: #selector(coordinator.handlePinchGesture(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        // 2. Attachement du Rotation Gesture (Rotation 3D orbitale)
        let rotationGesture = UIRotationGestureRecognizer(target: coordinator, action: #selector(coordinator.handleRotationGesture(_:)))
        arView.addGestureRecognizer(rotationGesture)
        
        // 3. Attachement du Tap Gesture (Sélection / Vocalisation / Animation)
        let tapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(coordinator.handleTapGesture(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        if let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "PedagogicalCards", bundle: nil) {
            configuration.detectionObjects = referenceObjects
        }
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        DispatchQueue.main.async {
            coordinator.isTrackingActive = true
            coordinator.statusMessage = "Tracking spatial & Gestes ARSCNView actifs."
        }
        
        return arView
    }
    
    public func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

// MARK: - Indicateur de Chargement AR Style Glassmorphism
public struct GlassmorphicARScanningIndicator: View {
    public let isSearching: Bool
    public let detectedPlanesCount: Int
    
    @State private var isRotating: Bool = false
    @State private var isPulsing: Bool = false
    @State private var waveScale: CGFloat = 0.8
    @State private var waveOpacity: Double = 0.8
    
    public init(isSearching: Bool, detectedPlanesCount: Int) {
        self.isSearching = isSearching
        self.detectedPlanesCount = detectedPlanesCount
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Radar & Réticule Holographique Animé
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(waveScale)
                    .opacity(waveOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                            waveScale = 1.35
                            waveOpacity = 0.0
                        }
                    }
                
                Circle()
                    .stroke(
                        Color.cyan.opacity(0.5),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 8])
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .onAppear {
                        withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                            isRotating = true
                        }
                    }
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.7), Color.cyan.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.cyan.opacity(0.35), radius: 15)
                
                VStack(spacing: 2) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.cyan)
                        .scaleEffect(isPulsing ? 1.08 : 0.94)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                isPulsing = true
                            }
                        }
                }
            }
            .frame(height: 140)
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 6, height: 6)
                        .shadow(color: .cyan, radius: 4)
                    
                    Text("RECHERCHE SPATIALE ACTIVE")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(.cyan)
                        .tracking(1.2)
                }
                
                Text("Alignez un signe ou support d'apprentissage")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Pincer pour redimensionner • Pivoter pour orienter • Tap pour vocaliser")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.system(size: 10))
                            .foregroundColor(.cyan)
                        Text("Apple Neural Engine")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.slateText)
                    }
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "square.split.diagonal.2x2")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("\(detectedPlanesCount) Plan\(detectedPlanesCount > 1 ? "s" : "")")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.95)
                    
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.cyan.opacity(0.04), Color.black.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.55), Color.cyan.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: Color.cyan.opacity(0.2), radius: 20, x: 0, y: 8)
        }
        .padding(.horizontal, 24)
    }
}

private extension Color {
    static let slateText = Color(red: 0.75, green: 0.82, blue: 0.90)
}
