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
    @Published var cameraManager = CameraManager()
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
                            self.cameraManager.takePhoto()
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
