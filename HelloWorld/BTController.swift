//
//  BTController.swift
//  HelloWorld
//
//  Created by Alexander Onishchenko on 24.03.2024.
//

let default_numshots: Int = 20
import CoreBluetooth

class BluetoothController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
 //   private var sppServiceUUID = CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB") // SPP UUID
    private var numShots : Int
    
    override init() {
        numShots = default_numshots
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Метод делегата CBCentralManagerDelegate, вызывается при изменении статуса Bluetooth
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Bluetooth включен, начинаем поиск устройств
            print("Bluetooth включен")
           // centralManager.scanForPeripherals(withServices: [sppServiceUUID], options: nil)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            // Bluetooth выключен или не доступен
            print("Bluetooth is not available.")
        }
    }
    
    // Метод делегата CBCentralManagerDelegate, вызывается при обнаружении устройства
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Подключаемся к обнаруженному устройству
        if peripheral.name == "3DScan" {
            self.peripheral = peripheral
            self.peripheral?.delegate = self
            centralManager.connect(peripheral, options: nil)
            print("Подключились к устройству")
        }
    }
    
    // Метод делегата CBCentralManagerDelegate, вызывается при успешном подключении к устройству
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let services = peripheral.services else {
                print("No services found")
                return
            }
        for service in services {
            print("Discovered service: \(service)")
        }
    }
    
    // Метод делегата CBPeripheralDelegate, вызывается при обнаружении сервисов на устройстве
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // Метод делегата CBPeripheralDelegate, вызывается при обнаружении характеристик на устройстве
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.write) && characteristic.properties.contains(.read) {
                self.characteristic = characteristic
            }
        }
    }
    
    // Метод для отправки данных
    func sendData(data: Data) {
        print(data)
        if let peripheral = peripheral, let characteristic = characteristic {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    
    // Метод для чтения данных
    func readData() {
        if let peripheral = peripheral, let characteristic = characteristic {
            peripheral.readValue(for: characteristic)
        }
    }
    
    func isReady() -> Bool {
        return true
    }
    
    func startScanning() {
        // команды для начала сканирования
        print("шлем восьмерку\n")
        guard let data:Data = "8".data(using: .ascii) else {
                    // Обработка ошибки преобразования строки в данные
                    return
                }
        self.sendData(data: data)
    }
    
    func stopScanning() {
        // команды для начала сканирования
        guard let data:Data = "9".data(using: .utf8) else {
                    // Обработка ошибки преобразования строки в данные
                    return
                }
        self.sendData(data: data)
    }
    
    func getNumshots() -> Int {
        return numShots
    }
    
    func setNumshots(num: Int) {
        if (num >= 0) {
            numShots = num
        } else {
            numShots = 0
        }
    }
}
