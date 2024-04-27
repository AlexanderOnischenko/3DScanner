//
//  BTController.swift
//  HelloWorld
//
//  Created by Alexander Onishchenko on 24.03.2024.
//

internal let default_numshots = 20
internal let gearRatio512 = 2176 // real gear ratio is 51/12, then we multiply it on 512 (full cycle)
internal let BTDeviceName = "BT05" // Name of My BLE. Initialize: AT+NAMECC2541\r\n
internal let serviceUUID = CBUUID(string: "FFE0") // Service UUID of My BLE. Initialize: AT+UUIDFABF\r\n
internal let characteristicUUID = CBUUID(string: "FFE1") // Char ID of My BLE. Initialize: AT+CHARA2B2\r\n
internal let terminatingChar = "b"


import CoreBluetooth

class BluetoothController: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    @Published var numShots : Int
    private let serialQueue = DispatchQueue(label: "com.btcontroller.serialqueue") // для синхронного выполнения записи в BT
    private var scanningIsStopped = false
    private var waitingForTermination = false
    private var terminatingSymbolReceived = true
    private var semaphore = DispatchSemaphore(value: 0)
    
    
    override init() {
        numShots = default_numshots
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
                //self.service = service
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
                // инициализируем устройство нужными настройками
                setNumshots(num: numShots)
            }
        }
    }
    
    // Метод делегата CBPeripheralDelegate, вызывается при обновлении характеристик на устройстве
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            // Преобразуем полученные данные в строку
            guard let stringValue = String(data: data, encoding: .utf8) else {
                print ("проблема декодирования")
                return
            }
            print("пришло \(stringValue)")
            if stringValue == terminatingChar {

                    if !terminatingSymbolReceived {
                        print("уменьшили семафор")
                        semaphore.signal()
                        // чтобы не посылать повторно, пока его не прочитают
                        terminatingSymbolReceived = true
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
    
    func rotate() {
        // проверяем готовность устройства
        if !isReady() {
            return
        }
        // команды для начала сканирования
        //print("шлем восьмерку\n")
        guard let data:Data = "8".data(using: .ascii) else {
                    // Обработка ошибки преобразования строки в данные
                    return
                }
        self.sendData(data: data)
        print("Async: ждем в rotate")
        self.waitForSuccess()
        print("Async: проехали rotate")
     }
    
    func waitForSuccess() {
        // очищаем флаг приема
        terminatingSymbolReceived = false
        semaphore.wait()
        serialQueue.sync {
            // очищаем флаг isBusy только в случае реального получения терминирующего символа
            if !scanningIsStopped {
                print("Q1: очищаем флаг isBusy")
                waitingForTermination = false
            } 
        }
    }
    
    func stopScanning() {
        scanningIsStopped = true
        print("Async: прервали сканирование семафором")
        semaphore.signal()
    }
    
    func getNumshots() -> Int {
        return numShots
    }
    
    func decreaseNumber() {
        if numShots == 1 {
            return
        }
  //      objectWillChange.send()
        setNumshots(num: getNumshots()-1)
    }

    func increaseNumber() {
   //     objectWillChange.send()
        setNumshots(num: getNumshots()+1)
    }

    func setNumshots(num: Int) -> Bool {
        if !isReady() {
            return false
        } else {
            if (num >= 0) {
                numShots = num
            } else {
                numShots = 0
            }
            let steps: Int = gearRatio512 / numShots
            print("S\(steps)X")
            guard let data:Data = "S\(steps)X".data(using: .utf8) else {
                // Обработка ошибки преобразования строки в данные
                return false
            }
            self.sendData(data: data)
            print("Async: ждем в setNumshots")
            self.waitForSuccess()
            print("Async: проехали setNumshots")
        }
        return true
    }
}
