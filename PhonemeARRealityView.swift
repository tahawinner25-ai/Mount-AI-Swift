import SwiftUI
import RealityKit
import ARKit

public struct PhonemeARRealityView: UIViewRepresentable {
    @Binding public var activePhoneme: String
    
    public init(activePhoneme: Binding<String>) {
        self._activePhoneme = activePhoneme
    }
    
    public func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        arView.session.run(configuration)
        
        // Configuration de la scène spatiale
        let anchor = AnchorEntity(plane: .horizontal)
        
        // Modèle 3D du phonème avec reflets physiques PBR
        let textMesh = MeshResource.generateText(
            activePhoneme.isEmpty ? "Mentora AI" : activePhoneme,
            extrusionDepth: 0.035,
            font: .systemFont(ofSize: 0.08, weight: .black),
            containerFrame: .zero,
            alignment: .center
        )
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .systemCyan)
        material.roughness = 0.15
        material.metallic = 0.90
        material.emissiveColor = .init(color: .systemTeal)
        
        let textEntity = ModelEntity(mesh: textMesh, materials: [material])
        textEntity.name = "PhonemeTextEntity"
        textEntity.position = [0, 0.15, -0.4]
        
        // Particules d'ondes sonores gravitationnelles
        let sphereMesh = MeshResource.generateSphere(radius: 0.02)
        var sphereMat = SimpleMaterial(color: .systemGreen, isMetallic: true)
        sphereMat.roughness = 0.2
        let satelliteNode = ModelEntity(mesh: sphereMesh, materials: [sphereMat])
        satelliteNode.position = [0.15, 0.05, 0]
        textEntity.addChild(satelliteNode)
        
        anchor.addChild(textEntity)
        arView.scene.addAnchor(anchor)
        
        return arView
    }
    
    public func updateUIView(_ uiView: ARView, context: Context) {
        guard let textEntity = uiView.scene.findEntity(named: "PhonemeTextEntity") as? ModelEntity else { return }
        
        let newMesh = MeshResource.generateText(
            activePhoneme.isEmpty ? "Mentora AI" : activePhoneme,
            extrusionDepth: 0.035,
            font: .systemFont(ofSize: 0.08, weight: .black),
            containerFrame: .zero,
            alignment: .center
        )
        textEntity.model?.mesh = newMesh
    }
}
