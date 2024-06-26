//
//  MainScannerView.swift
//  ScannerApp
//
//  Created by Alexander Onishchenko on 22.03.2024.
//

import SwiftUI

struct MainScannerView : View {
    @ObservedObject var viewModel = ContentViewModel()
    
    var body: some View {
         ZStack {
             CameraControlView(cameraManager: viewModel.cameraManager)
                 .edgesIgnoringSafeArea(.all)
             VStack {
                 controlPanel
                 Spacer()
                 bottomButtons
                 bluetoothStatusView
             }
         }
     }

     private var controlPanel: some View {
         HStack {
             Button(action: viewModel.increaseNumber) {
                 Image(systemName: "arrow.up")
                     .font(.system(size: 24))
                     .foregroundColor(.white)
                     .padding()
                     .frame(height: 48)
                     .background(Color.green)
                     .cornerRadius(5)
             }
             
             Text("\(viewModel.numShots)")
                 .font(.system(size: 48))
                 .foregroundColor(.white)
                 .padding()
                 .background(Color.blue)
                 .cornerRadius(10)
                 .padding()
             
             Button(action: viewModel.decreaseNumber) {
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
             Button(action: viewModel.startScanning) {
                 Image(systemName: "play.circle")
                     .resizable()
                     .frame(width: 50, height: 50)
             }
             
             Spacer()
             
             Button(action: viewModel.stopScanning) {
                 Image(systemName: "stop.circle")
                     .resizable()
                     .frame(width: 50, height: 50)
                     .foregroundColor(.red)
             }
             Spacer()
         }
         .padding()
     }
    
    private var bluetoothStatusView: some View {
        Text(viewModel.bluetoothStatus)
            .font(.caption)
            .foregroundColor( .white)
            .padding()
    }

}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainScannerView()
    }
}


