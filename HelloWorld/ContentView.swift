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
    @ObservedObject var myBT = BluetoothController()
    var body: some View {
         ZStack {
             CameraViewRepresentable()
                 .edgesIgnoringSafeArea(.all)
             VStack {
                 controlPanel
                 Spacer()
                 bottomButtons
             }
         }
     }

     private var controlPanel: some View {
         HStack {
             Button(action: myBT.increaseNumber) {
                 Image(systemName: "arrow.up")
                     .font(.system(size: 24))
                     .foregroundColor(.white)
                     .padding()
                     .frame(height: 48)
                     .background(Color.green)
                     .cornerRadius(5)
             }
             
             Text("\(myBT.getNumshots())")
                 .font(.system(size: 48))
                 .foregroundColor(.white)
                 .padding()
                 .background(Color.blue)
                 .cornerRadius(10)
                 .padding()
             
             Button(action: myBT.decreaseNumber) {
                 Image(systemName: "arrow.down")
                     .font(.system(size: 24))
                     .foregroundColor(.white)
                     .padding()
                     .frame(height: 48)
                     .background(Color.red)
                     .cornerRadius(5)
             }
         }
         .padding()
     }

     private var bottomButtons: some View {
         HStack {
             Spacer()
             Button(action: startScanning) {
                 Image(systemName: "play.circle")
                     .resizable()
                     .frame(width: 50, height: 50)
             }
             
             Spacer()
             
             Button(action: stopScanning) {
                 Image(systemName: "stop.circle")
                     .resizable()
                     .frame(width: 50, height: 50)
                     .foregroundColor(.red)
             }
             Spacer()
         }
         .padding()
     }

     private func startScanning() {
         myBT.startScanning()
     }

     private func stopScanning() {
         myBT.stopScanning()
     }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
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


