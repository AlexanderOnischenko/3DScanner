//
//  ContentView.swift
//  HelloWorld
//
//  Created by Alexander Onishchenko on 22.03.2024.
//

import SwiftUI
import UIKit
import AVFoundation

struct ContentView : View {
    var body: some View {
        ZStack {
            CameraViewRepresentable()
                            .edgesIgnoringSafeArea(.all)

              VStack {
                  Spacer()
                  HStack {
                      Spacer()
                      Button(action: {
                          // Действие для кнопки Start
                      }) {
                          Image(systemName: "play.circle") // Используйте подходящую SF Symbol
                              .resizable()
                              .frame(width: 50, height: 50)
                      }
                      
                      Spacer()
                      
                      Button(action: {
                          // Действие для кнопки Stop
                      }) {
                          Image(systemName: "stop.circle") // Используйте подходящую SF Symbol
                              .resizable()
                              .frame(width: 50, height: 50)
                              .foregroundColor(.red) // Делает иконку красной
                      }
                      Spacer()
                  }
                  .padding()
              }
          }
      }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


class CameraView: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    // Use a capture video preview layer as the view's backing layer.
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect: CGRect! = nil // For view dimensions
        
    override func viewDidLoad() {
        checkPermission()
        
   //     sessionQueue.async { [unowned self] in
   //         guard permissionGranted else { return }
           self.setupCaptureSession()
            
   //         self.setupLayers()
   //         self.setupDetector()
            
        DispatchQueue.global(qos: .background).async {
            // Вызовите startRunning() на фоновом потоке
            self.captureSession.startRunning()
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Permission has been granted before
            case .authorized:
            DispatchQueue.main.async {
                self.permissionGranted = true
            }

                
            // Permission has not been requested yet
            case .notDetermined:
                requestPermission()
                    
            default:
            DispatchQueue.main.async {
                self.permissionGranted = false
            }

            }
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    self.permissionGranted = true
                }
            } else {
                DispatchQueue.main.async {
                    self.permissionGranted = false
                }
            }
        }
    }
    
    func setupCaptureSession() {
        // Camera input
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video, position: .back)
            if videoDevice == nil {
                print("Не нашли камеру\n")
                return
            }
           print("Нашли камеру\n")
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!) else { return }
           print("Нашли videoDeviceInput\n")
               
            guard captureSession.canAddInput(videoDeviceInput) else { return }
           print("Добавили ввод\n")
            captureSession.addInput(videoDeviceInput)
                             
            // Preview layer
            screenRect = UIScreen.main.bounds
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Fill screen
            previewLayer.connection?.videoOrientation = .portrait
 
            // Updates to UI must be on main queue
            DispatchQueue.main.async { [weak self] in
                self!.view.layer.addSublayer(self!.previewLayer)
            }
        }
    }


struct CameraViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraView {
        return CameraView()
    }
    
    func updateUIViewController(_ uiViewController: CameraView, context: Context) {
        // Нет необходимости в обновлении
    }
}

