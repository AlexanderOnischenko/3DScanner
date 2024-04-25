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

                      HStack {
                          Button(action: myBT.increaseNumber) {
                              Image(systemName: "arrow.up")
                                  .font(.system(size: 24))
                                  .foregroundColor(.white)
                                  .padding()
                                  .frame(height: 48) // Устанавливаем высоту кнопки по высоте текста
                                  .background(Color.green)
                                  .cornerRadius(5)
                          }
                          
                          Text("\(myBT.getNumshots())")
                              .font(.system(size: 48)) // Крупные цифры
                              .foregroundColor(.white) // Белый цвет текста
                              .padding() // Добавляем немного отступа вокруг текста
                              .background(Color.blue) // Синий фон
                              .cornerRadius(10) // Закругляем углы фона
                              .padding()
                          
                          Button(action: myBT.decreaseNumber) {
                              Image(systemName: "arrow.down")
                                  .font(.system(size: 24))
                                  .foregroundColor(.white)
                                  .padding()
                                  .frame(height: 48) // Устанавливаем высоту кнопки по высоте текста
                                  .background(Color.red)
                                  .cornerRadius(5)
                          }
                      }
                      .padding()
                  
                  Spacer()
                  HStack {
                      Spacer()
                      Button(action: {
                          // Действие для кнопки Start
                          myBT.startScanning()
                          
                      }) {
                          Image(systemName: "play.circle") // Используйте подходящую SF Symbol
                              .resizable()
                              .frame(width: 50, height: 50)
                      }
                      
                      Spacer()
                      
                      Button(action: {
                          // Действие для кнопки Stop
                          myBT.stopScanning()
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


