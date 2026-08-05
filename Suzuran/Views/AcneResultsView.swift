//
//  AcneResultsView.swift
//  Suzuran — Views/
//
//  Full-screen results screen presented after the face-scan ring completes.
//
//  Layout:
//    • Interactive SceneKit 3D face mesh (Full Screen)
//    • Results panel presented as a half-screen draggable modal (.sheet)
//

import SwiftUI
import SceneKit
import ARKit

struct AcneResultsView: View {

    let faceGeometry: ARFaceGeometry
    let detections:   [AcneDetectionResult]

    @Environment(\.dismiss) private var dismiss
    
    @State private var scene: SCNScene?
    @State private var showSheet = true

    // MARK: - Derived

    private var totalCount: Int { detections.count }

    private var overallSeverity: SeverityLevel {
        detections
            .map    { $0.acneClass.severity }
            .max()  ?? .mild
    }

    private var classRows: [(AcneClass, Int)] {
        let counts = Dictionary(grouping: detections, by: { $0.acneClass })
            .mapValues { $0.count }
        return AcneClass.allCases
            .filter  { counts[$0, default: 0] > 0 }
            .sorted  {
                let s = $0.severity.compareSeverity($1.severity)
                if s != 0 { return s > 0 }
                return counts[$0, default: 0] > counts[$1, default: 0]
            }
            .map { ($0, counts[$0, default: 0]) }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Base background
            Color(white: 0.05).ignoresSafeArea()

            // ── Full Screen 3D SceneKit Mesh ───────────────
            if let scene {
                SceneView(
                    scene: scene,
                    options: [.allowsCameraControl] // Removed auto lighting to prevent overexposure
                )
                .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }

            // ── Overlays (Dismiss button & Severity Badge) ───
            VStack {
                HStack(alignment: .top) {
                    SeverityBadge(level: overallSeverity)
                    
                    if !showSheet {
                        Button {
                            showSheet = true
                        } label: {
                            Text("Show Results")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .animation(.easeInOut, value: showSheet)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            self.scene = createFaceScene(geometry: faceGeometry, detections: detections)
        }
        .sheet(isPresented: $showSheet) {
            resultsPanel
                .presentationDetents([.fraction(0.4), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(32)
        }
    }

    // MARK: - Results Panel (.sheet content)

    private var resultsPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Analysis Results")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(totalCount == 0
                         ? "No lesions detected"
                         : "\(totalCount) lesion\(totalCount == 1 ? "" : "s") identified")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.60))
                }
                .padding(.top, 24)

                // Detection rows
                if !classRows.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(classRows, id: \.0) { cls, count in
                            DetectionRow(acneClass: cls, count: count, totalCount: totalCount)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(SeverityLevel.mild.color)
                        Text("Skin looks clear — no acne detected.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.70))
                    }
                    .padding(.vertical, 8)
                }

                // Recommendation
                VStack(alignment: .leading, spacing: 8) {
                    Label("Recommendation", systemImage: "stethoscope")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.45))
                        .textCase(.uppercase)

                    Text(overallSeverity.recommendation)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.70))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )
                )

                // Disclaimer
                Text("For experimental use only. This is not medical advice.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.30))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)

                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - SceneKit Setup

    private func createFaceScene(geometry: ARFaceGeometry, detections: [AcneDetectionResult]) -> SCNScene {
        let scene = SCNScene()
        // Explicit dark background so it doesn't default to white
        scene.background.contents = UIColor(white: 0.05, alpha: 1.0)
        
        // 1. Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.01 // Crucial: Default is 1.0m, which clips the face!
        cameraNode.position = SCNVector3(0, 0, 0.28) // 28cm back
        scene.rootNode.addChildNode(cameraNode)
        
        // 2. Lighting (Explicitly controlled to avoid blowout)
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 300
        scene.rootNode.addChildNode(ambientLight)
        
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 1000
        directionalLight.position = SCNVector3(0.1, 0.2, 0.5)
        directionalLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalLight)
        
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 300
        fillLight.position = SCNVector3(-0.2, -0.1, 0.3)
        fillLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fillLight)
        
        // 3. Face Mesh
        guard let device = MTLCreateSystemDefaultDevice(),
              let scnGeometry = ARSCNFaceGeometry(device: device) else {
            return scene
        }
        scnGeometry.update(from: geometry)
        
        // Premium Dark Material (Phong is much safer without an HDRI environment map)
        let material = SCNMaterial()
        material.lightingModel = .phong
        material.diffuse.contents = UIColor(white: 0.15, alpha: 1.0)
        material.specular.contents = UIColor(white: 0.70, alpha: 1.0)
        material.shininess = 60
        // No transparency for now to avoid rendering artifacts or clipping issues
        scnGeometry.materials = [material]
        
        let faceNode = SCNNode(geometry: scnGeometry)
        scene.rootNode.addChildNode(faceNode)
        
        // 4. Acne Markers
        for det in detections {
            let sphere = SCNSphere(radius: 0.0035) // 3.5mm radius
            let sphereMat = SCNMaterial()
            let uicolor = UIColor(det.acneClass.color)
            sphereMat.diffuse.contents = uicolor
            sphereMat.emission.contents = uicolor
            sphereMat.lightingModel = .phong
            sphere.materials = [sphereMat]
            
            let markerNode = SCNNode(geometry: sphere)
            let pos = det.localPosition
            markerNode.position = SCNVector3(pos.x, pos.y, pos.z + 0.001)
            faceNode.addChildNode(markerNode)
        }
        
        return scene
    }
}

// MARK: - DetectionRow

private struct DetectionRow: View {

    let acneClass:  AcneClass
    let count:      Int
    let totalCount: Int

    private var fraction: Double {
        totalCount > 0 ? Double(count) / Double(totalCount) : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // Colored dot + class name
            HStack(spacing: 8) {
                Circle()
                    .fill(acneClass.color)
                    .frame(width: 10, height: 10)
                    .shadow(color: acneClass.color.opacity(0.50), radius: 4)

                Text(acneClass.displayName)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(minWidth: 105, alignment: .leading)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 6)

                    Capsule()
                        .fill(acneClass.color)
                        .frame(width: geo.size.width * fraction, height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: fraction)
                }
                .frame(height: 6)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 20)

            // Count badge
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(acneClass.color)
                .frame(minWidth: 24, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(acneClass.color.opacity(0.20), lineWidth: 1)
                )
        )
    }
}

// MARK: - SeverityBadge

private struct SeverityBadge: View {

    let level: SeverityLevel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: level.icon)
                .font(.system(size: 13, weight: .bold))
            Text(level.displayName)
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .foregroundColor(level.color)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(level.color.opacity(0.50), lineWidth: 1))
        )
        .shadow(color: level.color.opacity(0.25), radius: 8)
    }
}

// MARK: - SeverityLevel sort helper

private extension SeverityLevel {
    func compareSeverity(_ other: SeverityLevel) -> Int {
        let order: [SeverityLevel: Int] = [.severe: 2, .moderate: 1, .mild: 0]
        return (order[self] ?? 0) - (order[other] ?? 0)
    }
}
