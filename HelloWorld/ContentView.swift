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
//    let myBT = BluetoothController()
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
//                          myBT.startScanning()
                          
                      }) {
                          Image(systemName: "play.circle") // Используйте подходящую SF Symbol
                              .resizable()
                              .frame(width: 50, height: 50)
                      }
                      
                      Spacer()
                      
                      Button(action: {
                          // Действие для кнопки Stop
 //                         myBT.stopScanning()
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

struct CameraViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraView {
        return CameraView()
    }
    
    func updateUIViewController(_ uiViewController: CameraView, context: Context) {
        // Нет необходимости в обновлении
    }
}


