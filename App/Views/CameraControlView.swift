//
//  CameraControlView.swift
//  3DScanner
//
//  Created by Alexander Onishchenko on 27.04.2024.
//

import SwiftUI

struct CameraControlView: View {
    @ObservedObject var cameraManager = CameraManager()
    @State private var permissionGranted = false
    @State private var focusIndicatorPosition: CGPoint = .zero
    @State private var isFocusIndicatorVisible: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreview(cameraManager: cameraManager)
                    .onAppear {
                        cameraManager.checkPermission { granted in
                            self.permissionGranted = granted
                            if granted {
                                cameraManager.startSession()
                            }
                        }
                    }
                    .onDisappear {
                        cameraManager.stopSession()
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onEnded { value in
                                let location = value.location
                                let devicePoint = CGPoint(
                                    x: location.x / geometry.size.width,
                                    y: location.y / geometry.size.height
                                )
                                cameraManager.focus(at: devicePoint)
                                // Update focus indicator
                                focusIndicatorPosition = location
                                isFocusIndicatorVisible = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    isFocusIndicatorVisible = false
                                }
                            }
                    )

                FocusIndicatorView(center: focusIndicatorPosition, isVisible: isFocusIndicatorVisible)

                VStack {
                    if permissionGranted {
                        // Ваша панель управления здесь
                    } else {
                        Text("Camera permission is required.")
                    }
                }
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.layer.addSublayer(cameraManager.previewLayer)
        cameraManager.previewLayer.frame = view.bounds
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        cameraManager.previewLayer.frame = uiView.bounds
    }
}
