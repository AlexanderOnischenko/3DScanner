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
    public var myCamera = CameraViewRepresentable()
    private var scanningStopped = false

    init() {
    }

    
    func startScanning() {
        scanningStopped = false
        var iteration = 0
        let numShots = self.myBT.getNumshots()
        while iteration < numShots {
//                 Thread.sleep(forTimeInterval: 0.1)
            self.myBT.rotate()
            self.waitForSuccess()
            //self.myCamera.takePhoto()
            iteration += 1
            print("\(iteration)")
        }
     }

     func stopScanning() {
         scanningStopped = true
    }
     
     private func waitForSuccess() {
        while !self.myBT.isReady() {
   //         Thread.sleep(forTimeInterval: 0.1)
            }
        }
    
    func decreaseNumber(){
        objectWillChange.send()
        myBT.decreaseNumber()
    }
    
    func increaseNumber(){
        objectWillChange.send()
        myBT.increaseNumber()
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
