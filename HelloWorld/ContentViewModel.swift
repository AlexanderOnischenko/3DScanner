//
//  ContentViewModel.swift
//  HelloWorld
//
//  Created by Alexander Onishchenko on 26.04.2024.
//

import Foundation
import SwiftUI
import UIKit
import AVFoundation

class ContentViewModel: ObservableObject {
    public var isScanningInterrupted = false
    @Published var myBT = BluetoothController()
    public var myCamera : CameraView?
    private var scanningStopped = false
    private let scanningQueue = DispatchQueue(label: "com.example.scanning")

    init() {
    }

    
    func startScanning() {
        scanningStopped = false
        self.myBT.prepareForScanning()
        scanningQueue.async {
            var iteration = 0
            let numShots = self.myBT.getNumshots()
            while iteration < numShots, !self.scanningStopped {
                    print("\(iteration)")
                    if self.myBT.rotate() {
                        if !self.scanningStopped {
                            self.myCamera?.takePhoto()
                            iteration += 1
                        }
                }
            }
        }
     }

    func stopScanning() {
        self.scanningStopped = true
        self.myBT.stopScanning()
    }
     
    
    func decreaseNumber(){
        objectWillChange.send()
        scanningQueue.async {
            self.myBT.decreaseNumber()
        }
    }
    
    func increaseNumber(){
        objectWillChange.send()
        scanningQueue.async {
            self.myBT.increaseNumber()
        }
    }
 }

struct CameraViewRepresentable: UIViewControllerRepresentable {
    @ObservedObject var viewModel: ContentViewModel
 
    func makeUIViewController(context: Context) -> CameraView {
        let camera = CameraView()
        viewModel.myCamera = camera
        return camera
    }
    
    func updateUIViewController(_ uiViewController: CameraView, context: Context) {
        // Нет необходимости в обновлении
    }
}
