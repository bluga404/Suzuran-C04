//
//  ARViewContainer.swift
//  Suzuran — Controllers/
//
//  Responsibilities:
//    • Bridges ARKit's UIKit-based ARSCNView into SwiftUI via
//      UIViewControllerRepresentable.
//    • Hosts ARViewController, which manages the view lifecycle
//      (start / pause session, idle-timer, full-screen layout).
//

import ARKit
import SceneKit
import SwiftUI

// MARK: - ARViewContainer

/// SwiftUI wrapper around `ARViewController`.
/// Injects the shared `ARFaceViewModel` so the scene view and session
/// are owned in one place and never duplicated.
struct ARViewContainer: UIViewControllerRepresentable {

    @ObservedObject var viewModel: ARFaceViewModel

    func makeUIViewController(context: Context) -> ARViewController {
        let vc = ARViewController()
        vc.viewModel = viewModel
        return vc
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        // Session lifecycle is managed by the ViewModel; no updates needed here.
    }
}

// MARK: - ARViewController

/// Thin `UIViewController` that hosts the `ARSCNView`.
///
/// Using a `UIViewController` (rather than a bare `UIView`) gives us
/// `viewWillAppear` / `viewWillDisappear` lifecycle hooks to pause the
/// AR session when the screen is off-screen, saving battery.
final class ARViewController: UIViewController {

    var viewModel: ARFaceViewModel!
    private var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView = ARSCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.delegate = viewModel       // renderer callbacks → ViewModel
        sceneView.session  = viewModel.session
        sceneView.autoenablesDefaultLighting = true

        view.addSubview(sceneView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        viewModel.startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.pauseSession()
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
