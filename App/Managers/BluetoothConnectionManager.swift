//
//  BluetoothConnectionManager.swift
//  3DScanner
//
//  Created by Alexander Onishchenko on 28.04.2024.
//

import Foundation
import CoreBluetooth

// These constants use names of BT device defined in BluetoothConfig.h
// imported to the project through 3DScanner-Bridging-Header.h
internal let BTDeviceName =  String(cString: DEVICE_NAME)
internal let serviceUUID = CBUUID(string: String(cString: SERVICE_UUID))
internal let characteristicUUID = CBUUID(string: String(cString: CHARACTERISTIC_UUID))

protocol BluetoothConnectionManagerDelegate: AnyObject {
    func bluetoothDidUpdateState(_ stateString: String)
}

class BluetoothConnectionManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    public var peripheral: CBPeripheral?
    public var characteristic: CBCharacteristic?
    weak var delegate: BluetoothConnectionManagerDelegate?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning(serviceUUIDs: [CBUUID]? = nil) {
        if centralManager.state == .poweredOn {
            // Bluetooth включен, начинаем поиск устройств. Ищем устройства, которые реализуют наш сервис (Scan_3D)
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        } else {
            // Bluetooth выключен или не доступен
            print("Bluetooth is not available.")
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    func connectPeripheral(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
        stopScanning()
    }
    
    func disconnectPeripheral(_ peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: - CBCentralManagerDelegate Methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            delegate?.bluetoothDidUpdateState("Bluetooth is turned off")
        default:
            delegate?.bluetoothDidUpdateState("Bluetooth is not available")
            return
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Подключаемся к обнаруженному устройству
        let peripheralName = peripheral.name ?? "Unknown"
        let peripheralUUID = peripheral.identifier.uuidString
        
        // Выводим информацию о найденном устройстве в консоль
        delegate?.bluetoothDidUpdateState("Discovered Peripheral: \(peripheralName), UUID: \(peripheralUUID)")
        
        if peripheral.name == BTDeviceName {
            self.peripheral = peripheral
            self.peripheral?.delegate = self
            connectPeripheral(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        delegate?.bluetoothDidUpdateState("Connected to Peripheral: \(peripheral.name ?? "Unknown Device"). No Service found, UUID: \(peripheral.identifier.uuidString)")

    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        delegate?.bluetoothDidUpdateState("Failed to connect to peripheral: \(peripheral.name), UUID: \(peripheral.identifier.uuidString)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // нужна логика реконнекта
        delegate?.bluetoothDidUpdateState("Device disconnected")
        startScanning()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    }
    
    // MARK: - CBPeripheralDelegate Methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == serviceUUID {
                delegate?.bluetoothDidUpdateState("Connected to Peripheral: \(peripheral.name ?? "Unknown Device"), Service found. Characteristic not found. UUID: \(peripheral.identifier.uuidString)")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.write) && characteristic.properties.contains(.read) && characteristic.uuid == characteristicUUID && service.uuid == serviceUUID {
                self.characteristic = characteristic
                // Подписываемся на уведомления для этой характеристики
                self.peripheral?.setNotifyValue(true, for: characteristic)
                // Update UI
                delegate?.bluetoothDidUpdateState("Connected to Peripheral: \(peripheral.name ?? "Unknown Device"), UUID: \(peripheral.identifier.uuidString)")
            }
        }
    }
}

// MARK: - Bluetooth Protocol

/*class BluetoothManagerExtension {
    private var connectionManager: BluetoothConnectionManager
    
    private let serialQueue = DispatchQueue(label: "com.btcontroller.serialqueue") // для синхронного выполнения записи в BT
    private var interruptionFlag = false
    private var waitingForSuccess = false
    private var semaphore = DispatchSemaphore(value: 0)

    init(connectionManager: BluetoothConnectionManager) {
        self.connectionManager = connectionManager
    }
    
    override func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            // Преобразуем полученные данные в строку
            guard let stringValue = String(data: data, encoding: .utf8) else {
                print ("проблема декодирования")
                return
            }
            print("пришло \(stringValue)")
            if stringValue == terminatingChar {
                if waitingForSuccess {
                    print("уменьшили семафор")
                    semaphore.signal()
                    // чтобы не посылать повторно, пока его не прочитают
                    waitingForSuccess = false
                }
                
            }
        }
    }
    
    // Метод для отправки данных
    func sendData(data: Data) {
        // для правильного исполнения waitingForTermination должен быть false, иначе в порт ничего не запишется
        serialQueue.sync {
            if let peripheral = self.peripheral, let characteristic = self.characteristic {
                if !waitingForSuccess {
                    print("Q1: пишем\(String(data: data, encoding: .utf8))")
                    waitingForSuccess = true
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                }
            }
        }
    }
    
    func waitForCompletion() {
        // очищаем флаг приема
        waitingForSuccess = true
        semaphore.wait()
        serialQueue.sync {
            // очищаем флаг isBusy только в случае реального получения терминирующего символа
            if !interttuptionFlag {
                print("Q1: очищаем флаг isBusy")
                waitingForSuccess = false
            }
        }
    }
    
    func interruptProcessing() {
        interttuptionFlag = true
        semaphore.signal()
    }
}*/
    
class BluetoothProtocolClient : BluetoothConnectionManager {
    
    private let serialQueue = DispatchQueue(label: "com.btcontroller.serialqueue") // для синхронного выполнения записи в BT
    private var scanningIsStopped = false
    private var waitingForTermination = false
    private var semaphore = DispatchSemaphore(value: 0)
    
    override func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            // Преобразуем полученные данные в строку
            guard let stringValue = String(data: data, encoding: .utf8) else {
                print ("проблема декодирования")
                return
            }
            print("пришло \(stringValue)")
            if stringValue == terminatingChar {
                if waitingForTermination {
                    print("уменьшили семафор")
                    semaphore.signal()
                    // чтобы не посылать повторно, пока его не прочитают
                    waitingForTermination = false
                }
                
            }
        }
    }
    
    
    // Метод для отправки данных
    func sendData(data: Data) {
        // для правильного исполнения waitingForTermination должен быть false, иначе в порт ничего не запишется
        serialQueue.sync {
            if let peripheral = self.peripheral, let characteristic = self.characteristic {
                if !waitingForTermination {
                    print("Q1: пишем\(String(data: data, encoding: .utf8))")
                    waitingForTermination = true
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                }
            }
        }
    }
    
    func isReady() -> Bool {
        guard let peripheral = self.peripheral, let characteristic = self.characteristic else {
            print("Peripheral or characteristic is nil")
            return false
        }
        if self.peripheral?.state != CBPeripheralState.connected {
            return false
        }
        // читаем на главной очереди, чтобы процедуры чтения и записи шли синхронно (по очереди)
        var res = false
        serialQueue.sync {
            print("Q1: проверяем isBusy")
            // проверяем isBusy, чтобы не вычитывать из порта, если мы уже находили там ноль
            if waitingForTermination == false {
                res = true
                return
            } else {
                print("Q1: оу, а мы заняты")
                res = false
                return
            }
        }
        return res
    }
    
    func waitForSuccess() {
        // очищаем флаг приема
        waitingForTermination = true
        semaphore.wait()
        serialQueue.sync {
            // очищаем флаг isBusy только в случае реального получения терминирующего символа
            if !scanningIsStopped {
                print("Q1: очищаем флаг isBusy")
                waitingForTermination = false
            }
        }
    }
    
    func stopWaiting() {
        scanningIsStopped = true
        print("прервали сканирование семафором")
        semaphore.signal()
    }
    
    // Этот метод надо удалить или переписать
    
    func prepareForScanning() {
        if waitingForTermination {
            self.semaphore = DispatchSemaphore(value: 1)
        } else {
            self.semaphore = DispatchSemaphore(value: 0)
        }
        
    }
    
}
