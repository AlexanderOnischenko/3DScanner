//
//  CameraManager.swift
//  3DScanner
//
//  Created by Alexander Onishchenko on 27.04.2024.
//

import AVFoundation
import Photos
import Combine
import UIKit

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    @Published var photoOutput: AVCapturePhotoOutput?
    @Published var permissionGranted = false

    private let captureSession = AVCaptureSession()

    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill // Заполнить область представления
        return layer
    }()

    override init() {
        super.init()
        self.setupCaptureSession()
    }

    func checkPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.permissionGranted = true
                completion(true)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                    completion(granted)
                }
            }
        default:
            DispatchQueue.main.async {
                self.permissionGranted = false
                completion(false)
            }
        }
    }

    func setupCaptureSession() {
        // Настройка устройства видеозахвата для использования задней камеры
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else {
            print("Не удалось настроить ввод устройства")
            return
        }
        
        // Добавление входа и выхода фото в сессию захвата
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddInput(videoDeviceInput) && captureSession.canAddOutput(photoOutput!) {
            captureSession.addInput(videoDeviceInput)
            captureSession.addOutput(photoOutput!)
        }
    }

    func startSession() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    func takePhoto() {
        var photoSettings = AVCapturePhotoSettings()
        // Создание настроек фотографирования с предпочтительным форматом файла
        if #available(iOS 11.0, *), photoOutput?.availablePhotoCodecTypes.contains(.jpeg) ?? false {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            // Если JPEG недоступен, используем стандартные настройки
            photoSettings = AVCapturePhotoSettings()
        }
        photoOutput?.capturePhoto(with: photoSettings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }

        savePhoto(image: image, albumName: "3dscan")
    }
    
    func savePhoto(image: UIImage, albumName: String = "3dscan") {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard status == .authorized, let self = self else {
                print("Необходимо разрешение на доступ к фото")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                // Создание или поиск альбома и добавление фото
                self.createOrAddImageToAlbum(image: image, albumName: albumName)
            }, completionHandler: { success, error in
                if success {
                    print("Фото успешно сохранено.")
                } else {
                    print("Ошибка при сохранении фото: \(String(describing: error))")
                }
            })
        }
    }
    
    private func createOrAddImageToAlbum(image: UIImage, albumName: String) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let assetCollection = collection.firstObject {
            self.addImage(image, to: assetCollection)
        } else {
            self.createAlbumAndAddImage(image: image, albumName: albumName)
        }
    }

    private func createAlbumAndAddImage(image: UIImage, albumName: String) {
        // Проверка существует ли альбом
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let existingAlbum = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions).firstObject

        if let album = existingAlbum {
            // Альбом уже существует, добавить изображение
            addImage(image, to: album)
        } else {
            // Альбом не существует, создать новый
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                let albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { success, error in
                if success {
                    // После успешного создания альбома, повторно ищем альбом и добавляем изображение
                    self.addImageToNewAlbum(image: image, albumName: albumName)
                } else {
                    print("Ошибка создания альбома: \(String(describing: error))")
                }
            })
        }
    }

    private func addImageToNewAlbum(image: UIImage, albumName: String) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        PHPhotoLibrary.shared().performChanges({
            let album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions).firstObject
            if let album = album {
                self.addImage(image, to: album)
            }
        }, completionHandler: { success, error in
            if !success {
                print("Ошибка добавления изображения в новый альбом: \(String(describing: error))")
            }
        })
    }

    private func addImage(_ image: UIImage, to album: PHAssetCollection) {
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
            if let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) {
                albumChangeRequest.addAssets([assetPlaceholder] as NSArray)
            }
        }, completionHandler: { success, error in
            if success {
                print("Фото успешно сохранено в альбом '\(album.localizedTitle ?? "")'")
            } else {
                print("Ошибка сохранения фото в альбом: \(String(describing: error))")
            }
        })
    }

    
    // Настройка фокуса в точке
     func focus(at point: CGPoint) {
         guard let device = AVCaptureDevice.default(for: .video) else { return }
         do {
             try device.lockForConfiguration()
             if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                 device.focusPointOfInterest = point
                 device.focusMode = .autoFocus
             }
             if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                 device.exposurePointOfInterest = point
                 device.exposureMode = .autoExpose
             }
             device.unlockForConfiguration()
         } catch {
             print("Не удалось заблокировать конфигурацию камеры для фокусировки")
         }
     }
 }
 
