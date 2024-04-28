//
//  BTController.swift
//  HelloWorld
//
//  Created by Alexander Onishchenko on 24.03.2024.
//

import Foundation
import CoreBluetooth

internal let default_numshots = 20
internal let gearRatio512 = 2176 // real gear ratio is 51/12, then we multiply it on 512 (full cycle)

// These constants use names of BT device defined in BluetoothConfig.h
// imported to the project through 3DScanner-Bridging-Header.h
internal let rotateChar = String(cString: ROTATE_CHAR)
internal let setNumshotCharS = String(cString: SET_NUMSHOTS_START)
internal let setNumshotCharX = String(cString: SET_NUMSHOTS_END)


class BluetoothController: ObservableObject, BluetoothConnectionManagerDelegate {
    var connectionManager: BluetoothProtocolClient
    @Published var numShots = default_numshots
    @Published var connectionState = "Starting..."
    
    init() {
        connectionManager = BluetoothProtocolClient()
        connectionManager.delegate = self
    }

    func bluetoothDidUpdateState(_ stateString: String) {
        // выводим сообщение в лог
        print(stateString)
        // обновить состояние соединения на UI
        connectionState = stateString
    }
    
    func rotate() -> Bool {
        // проверяем готовность устройства
        print("Async: вошли в rotate")
        if !connectionManager.isReady() {
            return false
        }
        // команды для начала сканирования
        guard let data:Data = rotateChar.data(using: .ascii) else {
                    // Обработка ошибки преобразования строки в данные
                    return false
                }
        connectionManager.sendData(data: data)
        print("Async: ждем в rotate")
        connectionManager.waitForSuccess()
        print("Async: проехали rotate")
        return true
     }
    
    func prepareForScanning() {
        connectionManager.prepareForScanning()
        }

    
    func stopScanning() {
        connectionManager.stopWaiting()
    }
    
    func getNumshots() -> Int {
        return numShots
    }
    
    func decreaseNumber() {
        if numShots == 1 {
            return
        }
        setNumshots(num: getNumshots()-1)
    }

    func increaseNumber() {
        setNumshots(num: getNumshots()+1)
    }

    func setNumshots(num: Int) -> Bool {
        if !connectionManager.isReady() {
            return false
        } else {
            if (num >= 0) {
                numShots = num
            } else {
                numShots = 0
            }
            let steps: Int = gearRatio512 / numShots
            let outputString = setNumshotCharS + "\(steps)" + setNumshotCharX
            guard let data:Data = outputString.data(using: .ascii) else {
                // Обработка ошибки преобразования строки в данные
                return false
            }
            connectionManager.sendData(data: data)
            print("Async: ждем в setNumshots")
            connectionManager.waitForSuccess()
            print("Async: проехали setNumshots")
        }
        return true
    }
}
