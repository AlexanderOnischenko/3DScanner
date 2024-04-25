//
//  BTController.swift
//  HelloWorld
//
//  Created by Alexander Onishchenko on 24.03.2024.
//

internal let default_numshots = 20
internal let gearRatio = 51/12
internal let BTDeviceName = "BT05" // Name of My BLE. Initialize: AT+NAMECC2541\r\n
internal let serviceUUID = CBUUID(string: "FFE0") // Service UUID of My BLE. Initialize: AT+UUIDFABF\r\n
internal let characteristicUUID = CBUUID(string: "FFE1") // Char ID of My BLE. Initialize: AT+CHARA2B2\r\n


import CoreBluetooth

class BluetoothController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var service: CBService?
    private var characteristic: CBCharacteristic?
    private var numShots : Int
    private var isBusy : Bool
    private var isWriting : Bool
    
    
    override init() {
        numShots = default_numshots
        isBusy = false
        isWriting = false
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    // Метод делегата CBCentralManagerDelegate, вызывается при изменении статуса Bluetooth
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Bluetooth включен, начинаем поиск устройств. Ищем устройства, которые реализуют наш сервис (Scan_3D)
            //print("Сканируем устройства")
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        } else {
            // Bluetooth выключен или не доступен
            print("Bluetooth is not available.")
        }
    }
    
    // Метод делегата CBCentralManagerDelegate, вызывается при обнаружении устройства
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Подключаемся к обнаруженному устройству
        let peripheralName = peripheral.name ?? "Unknown"
        let peripheralUUID = peripheral.identifier.uuidString
        
        // Выводим информацию о найденном устройстве в консоль
         print("Discovered Peripheral: \(peripheralName), UUID: \(peripheralUUID)")
        
        if peripheral.name == BTDeviceName {
            self.peripheral = peripheral
            self.peripheral?.delegate = self
            centralManager.connect(peripheral, options: nil)
            print("Подключились к устройству")
        }
    }
    
    // Метод делегата CBCentralManagerDelegate, вызывается при успешном подключении к устройству
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([serviceUUID])
    }
    
    // Метод делегата CBPeripheralDelegate, вызывается при обнаружении сервисов на устройстве
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            //print("\(service.uuid)")
            if service.uuid == serviceUUID {
                self.service = service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    // Метод делегата CBPeripheralDelegate, вызывается при обнаружении характеристик на устройстве
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            //print("\(characteristic.uuid)")
            if characteristic.properties.contains(.write) && characteristic.properties.contains(.read) && characteristic.uuid == characteristicUUID && service.uuid == serviceUUID {
                self.characteristic = characteristic
                print("YESS!!")
                // Подписываемся на уведомления для этой характеристики
                self.peripheral?.setNotifyValue(true, for: characteristic)
                // --> Без этого куска кода не работает. Надо разобраться, зачем он нужен
                self.peripheral?.readValue(for: characteristic)
                if let data = characteristic.value {
                    // Преобразуем полученные данные в строку
                    guard let stringValue = String(data: data, encoding: .utf8) else {
                        print ("проблема декодирования")
                        return
                    }
                    print(stringValue)
                }
                // --> Вот до сюда
            }
        }
    }
    
    // Метод делегата CBPeripheralDelegate, вызывается при обновлении характеристик на устройстве
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    }
    
    
    // Метод для отправки данных
    func sendData(data: Data) {
        //print(String(data: data, encoding: .utf8))
        if let peripheral = peripheral, let characteristic = characteristic {
            isBusy = true
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    
    // Метод для чтения данных
    func waitForSuccess() {
        if !isReady() {
            return
        }
        // Проверяем, что подключение к устройству установлено
        guard let peripheral = self.peripheral, let characteristic = self.characteristic else {
            print("Peripheral or characteristic is nil")
            return
        }
        while true {
            peripheral.readValue(for: characteristic)
            //self.peripheral?.readValue(for: characteristic!)
            if let data = characteristic.value {
                // Преобразуем полученные данные в строку
                guard let stringValue = String(data: data, encoding: .utf8) else {
                    print ("проблема декодирования")
                    return
                }
                // Если получен символ '0', выходим из цикла
                //print(stringValue)
                if stringValue == "0" {
                    print("Success: Received '0'")
                    break
                }
            }
        }
        isBusy = false
    }
    
    func isReady() -> Bool {
        return self.characteristic != nil
    }
    
    func startScanning() {
        if isBusy || isWriting {
            return
        }
        isWriting = true
        // команды для начала сканирования
        //print("шлем восьмерку\n")
        guard let data:Data = "8".data(using: .ascii) else {
                    // Обработка ошибки преобразования строки в данные
                    return
                }
        self.sendData(data: data)
        waitForSuccess()
        isWriting = false
        print("символ 0 получен")
    }
    
    func stopScanning() {
        if isBusy || isWriting {
            return
        }
        isWriting = true
        // команды для начала сканирования
        guard let data:Data = "9".data(using: .utf8) else {
                    // Обработка ошибки преобразования строки в данные
                    return
                }
        self.sendData(data: data)
        waitForSuccess()
        isWriting = false
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
