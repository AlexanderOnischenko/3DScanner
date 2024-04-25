//
//  CameraView.swift
//  HelloWorld
//
//  Created by Alexander Onishchenko on 24.03.2024.
//

import UIKit
import AVFoundation
import GCDWebServer
import Photos

class CameraView: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    // Use a capture video preview layer as the view's backing layer.
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private var photoOutput: AVCapturePhotoOutput?
    var screenRect: CGRect! = nil // For view dimensions
    
    var webServer = GCDWebServer()
        
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
        setupWebServer()
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
    
    func setupWebServer() {
        webServer.addHandler(forMethod: "GET", path: "/takePhoto", request: GCDWebServerRequest.self) { [weak self] request in
            self?.takePhoto()
            return GCDWebServerDataResponse(html: "Taking photo...")
        }

        webServer.start(withPort: 8080, bonjourName: "iOS Web Server")
        print("Server is running on \(String(describing: webServer.serverURL))")
    }
    
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




