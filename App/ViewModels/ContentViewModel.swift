//
//  ContentViewModel.swift
//  HelloWorld
//
//  Created by Alexander Onishchenko on 26.04.2024.
//

import Foundation
import AVFoundation

class ContentViewModel: ObservableObject {
    @Published var bluetoothStatus: String = "Disconnected"
    @Published var numShots: Int = 0
    @Published var cameraManager = CameraManager()
    private var myBT = BluetoothController()
    private var scanningStopped = false
    private let scanningQueue = DispatchQueue(label: "com.example.scanning")

    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Подписка на изменения состояния Bluetooth в контроллере
        myBT.$connectionState.assign(to: &$bluetoothStatus)
        myBT.$numShots.assign(to: &$numShots)
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
