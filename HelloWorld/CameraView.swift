//
//  CameraView.swift
//  HelloWorld
//
//  Created by Alexander Onishchenko on 24.03.2024.
//

import UIKit
import AVFoundation
//import GCDWebServer
import Photos

class CameraView: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    // Use a capture video preview layer as the view's backing layer.
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private var photoOutput: AVCapturePhotoOutput?
    var screenRect: CGRect! = nil // For view dimensions
    private var focusIndicator: UIView!

    
    //var webServer = GCDWebServer()
        
    override func viewDidLoad() {
        checkPermission()
        
   //     sessionQueue.async { [unowned self] in
   //         guard permissionGranted else { return }
        self.setupCaptureSession()
        self.setupFocusIndicator()
 
            
   //         self.setupLayers()
   //         self.setupDetector()
            
        DispatchQueue.global(qos: .background).async {
            // Вызовите startRunning() на фоновом потоке
            self.captureSession.startRunning()
        }
        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in
            self!.setupLayers()
        }

 //       setupWebServer()
        // Добавляем Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap(_:)))
        view.addGestureRecognizer(tapGesture)
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
    
/*    func setupWebServer() {
        webServer.addHandler(forMethod: "GET", path: "/takePhoto", request: GCDWebServerRequest.self) { [weak self] request in
            self?.takePhoto()
            return GCDWebServerDataResponse(html: "Taking photo...")
        }

        webServer.start(withPort: 8080, bonjourName: "iOS Web Server")
        print("Server is running on \(String(describing: webServer.serverURL))")
    }*/
    
    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }

        // Теперь у вас есть Data изображения, которое можно, например, преобразовать в UIImage
        let image = UIImage(data: imageData)!
        // Здесь вы можете делать что угодно с изображением, например, сохранять его или отображать на экране
        savePhoto(image: image)
    }
    
    func savePhoto(image: UIImage, albumName: String = "3dscan") {
        // Проверяем доступность библиотеки фотографий
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Необходимо разрешение на доступ к фото")
                return
            }
            
            // Пытаемся найти альбом с заданным именем
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
            let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            
            if let assetCollection = collection.firstObject {
                // Альбом найден, сохраняем фото
                self.addImage(image, to: assetCollection)
            } else {
                // Альбом не найден, создаём новый
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                }, completionHandler: { success, error in
                    if success {
                        // Повторный поиск и сохранение фото после создания альбома
                        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                        if let assetCollection = collection.firstObject {
                            self.addImage(image, to: assetCollection)
                        }
                    } else {
                        print("Ошибка создания альбома: \(String(describing: error))")
                    }
                })
            }
        }
    }

    private func addImage(_ image: UIImage, to album: PHAssetCollection) {
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
            guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
                  let assetPlaceholder = assetPlaceholder else { return }
            
            let enumeration: NSArray = [assetPlaceholder]
            albumChangeRequest.addAssets(enumeration)
        }, completionHandler: { success, error in
            if success {
                print("Фото успешно сохранено в альбом '\(album.localizedTitle ?? "")'")
            } else {
                print("Ошибка сохранения фото в альбом: \(String(describing: error))")
            }
        })
    }
    
    func setupCaptureSession() {
        // Camera input
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video, position: .back)
            if videoDevice == nil {
                print("Не нашли камеру\n")
                return
            }
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!) else { return }
            photoOutput = AVCapturePhotoOutput()
               
            guard captureSession.canAddInput(videoDeviceInput) else { return }
            captureSession.addInput(videoDeviceInput)
            captureSession.addOutput(photoOutput!)
        }
    
    @objc func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: view)
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: location)
        updateFocusIndicator(at: location)
        focus(at: devicePoint)
    }
    
    func focus(at point: CGPoint) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            device.unlockForConfiguration()
        } catch {
            print("Не удалось заблокировать конфигурацию камеры для фокусировки")
        }
    }
    
    private func setupFocusIndicator() {
        focusIndicator = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        focusIndicator.layer.borderColor = UIColor.yellow.cgColor
        focusIndicator.layer.borderWidth = 2
        focusIndicator.layer.cornerRadius = 40
        focusIndicator.backgroundColor = .clear
        focusIndicator.isHidden = true
        view.addSubview(focusIndicator)
    }
    
    private func updateFocusIndicator(at point: CGPoint) {
        focusIndicator.center = point
        focusIndicator.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.focusIndicator.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.focusIndicator.transform = CGAffineTransform.identity
            }
        }
    }
    
    private func setupPreviewLayer() {
        // Preview layer
        screenRect = UIScreen.main.bounds
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Fill screen
        previewLayer.connection?.videoOrientation = .portrait
        self.view.layer.addSublayer(previewLayer)
    }
    
    
    private func setupLayers() {
        self.setupPreviewLayer()
        self.setupFocusIndicator()  // Ensure focusIndicator is on top of the camera layer
    }
    
}




