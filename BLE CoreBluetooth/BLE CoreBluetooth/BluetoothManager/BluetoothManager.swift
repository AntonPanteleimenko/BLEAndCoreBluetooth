//
//  BluetoothManager.swift
//  BLE CoreBluetooth
//
//  Created by user on 29.11.2021.
//

import CoreBluetooth
import CoreLocation
import UserNotifications

protocol BlueEar {
    /// beacons
    func didRangeBeacons(beacons: [CLBeacon])
    
    /// central server
    func didStartConfiguration()
    func didStartScanningPeripherals()
    func didConnectPeripheral(name: String?)
    func didDisconnectPeripheral(name: String?)
    func didSendData()
    func didReceiveData(data: [String: String])
    func didFailConnection()
    
    /// client peripheral
    func didStartAdvertising()
    func didStopAdvertising()
}

enum ManagerState {
    case peripheral
    case central
    
    case clientPeripheral
    case serverCentral
}

class BluetoothManager: NSObject {
    
    // MARK: - Properties
    
    var state: ManagerState!
    var blueEar: BlueEar?
    
    var notificationSettings: UNNotificationSettings?
    
    /// iBeacon Broadcast
    var localBeacon: CLBeaconRegion!
    var beaconPeripheralData: NSDictionary!
    var peripheralManager: CBPeripheralManager!
    
    /// Scan
    var locationManager: CLLocationManager!
    
    /// Client/Server
    var serviceCBUUID: CBUUID?
    var characteristicCBUUID: CBUUID?
    
    /// Server central
    var centralManager: CBCentralManager?
    var discoveredPeripheral: CBPeripheral?
    
    /// Client peripheral
    let properties: CBCharacteristicProperties = [.read, .notify, .writeWithoutResponse, .write]
    let permissions: CBAttributePermissions = [.readable, .writeable]
    var service: CBMutableService?
    var characterisctic: CBMutableCharacteristic?
    
    /// Local dictionary of connected peripherals, with respect to each of their UUIDS (the ble code updates this var with each connected device)
    var sensorPeripheral = [UUID:CBPeripheral]()
    
    // MARK: - Init
    
    convenience init (state: ManagerState, delegate: BlueEar) {
        self.init()
        
        self.state = state
        self.blueEar = delegate
    }
    
    deinit {
        blueEar = nil
    }
}

extension BluetoothManager {
    
    // MARK: - Functions
    
    func startManager() {
        switch self.state {
        case .peripheral:
            initLocalBeacon()
        case .central:
            initScanner()
        case .clientPeripheral:
            setupClientPeripheral()
        case .serverCentral:
            setupServerCentral()
            serverCentralScan()
        default: break
        }
    }
    
    func initLocalBeacon() {
        if localBeacon != nil {
            stopLocalBeacon()
        }
        let uuid = UUID(uuidString: CBUUIDs.localBeaconUUID)!
        localBeacon = CLBeaconRegion(uuid: uuid,
                                     major: CBUUIDs.localBeaconMajor,
                                     minor: CBUUIDs.localBeaconMinor,
                                     identifier: CBUUIDs.identifier)
        beaconPeripheralData = localBeacon.peripheralData(withMeasuredPower: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    func stopLocalBeacon() {
        peripheralManager.stopAdvertising()
        peripheralManager = nil
        beaconPeripheralData = nil
        localBeacon = nil
    }
    
    func initScanner() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    func startScanning() {
        let uuid = UUID(uuidString: CBUUIDs.localBeaconUUID)!
        let beaconRegion = CLBeaconRegion(uuid: uuid,
                                          major: CBUUIDs.localBeaconMajor,
                                          minor: CBUUIDs.localBeaconMinor,
                                          identifier: CBUUIDs.identifier)
        
        locationManager.startMonitoring(for: beaconRegion)
        let beaconIdentityConstraint = CLBeaconIdentityConstraint(uuid: uuid, major: CBUUIDs.localBeaconMajor, minor: CBUUIDs.localBeaconMinor)
        locationManager.startRangingBeacons(satisfying: beaconIdentityConstraint)
    }
    
    func setupServerCentral() {
        guard
            let serviceUUID: UUID = NSUUID(uuidString: CBUUIDs.serviceUUID) as UUID?,
            let characteristicUUID: UUID = NSUUID(uuidString: CBUUIDs.characteristicUUID) as UUID?
        else { return }
        
        self.serviceCBUUID = CBUUID(nsuuid: serviceUUID)
        self.characteristicCBUUID = CBUUID(nsuuid: characteristicUUID)
    }
    
    func serverCentralScan() {
        
        let options: [String: Any] = [
            CBCentralManagerOptionRestoreIdentifierKey: CBUUIDs.centralId
        ]
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: options)
        self.blueEar?.didStartConfiguration()
    }
    
    func stopServerCentral() {
        if let peripheral = discoveredPeripheral {
            self.centralManager?.cancelPeripheralConnection(peripheral)
            self.blueEar?.didDisconnectPeripheral(name: peripheral.name ?? "")
        }
        self.centralManager?.stopScan()
        self.centralManager = nil
    }
    
    func setupClientPeripheral() {
        guard
            let serviceUUID: UUID = NSUUID(uuidString: CBUUIDs.serviceUUID) as UUID?,
            let characteristicUUID: UUID = NSUUID(uuidString: CBUUIDs.characteristicUUID) as UUID?
        else { return }
        
        self.serviceCBUUID = CBUUID(nsuuid: serviceUUID)
        self.characteristicCBUUID = CBUUID(nsuuid: characteristicUUID)
        
        guard
            let serviceCBUUID: CBUUID = self.serviceCBUUID,
            let characteristicCBUUID: CBUUID = self.characteristicCBUUID
        else { return }
        
        // Configuring service
        self.service = CBMutableService(type: serviceCBUUID, primary: true)
        
        // Configuring characteristic
        self.characterisctic = CBMutableCharacteristic(type: characteristicCBUUID, properties: self.properties, value: nil, permissions: self.permissions)
        
        guard let characterisctic: CBCharacteristic = self.characterisctic else { return }
        
        // Add characterisct to service
        self.service?.characteristics = [characterisctic]
        
        self.blueEar?.didStartConfiguration()
        
        let options: [String: Any] = [
            CBCentralManagerOptionRestoreIdentifierKey: CBUUIDs.peripheralId
        ]
        
        // Initiate peripheral and start advertising
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: options)
    }
    
    func stopClientPeripheral() {
        if peripheralManager != nil {
            self.peripheralManager.stopAdvertising()
            self.peripheralManager = nil
            self.blueEar?.didStopAdvertising()
        }
    }
    
    func requestAuthorization(completion: @escaping  (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _  in
                guard let self = self else { return }
                self.fetchNotificationSettings()
                completion(granted)
            }
    }
    
    func fetchNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationSettings = settings
            }
        }
    }
    
    func sendLocalNotification(text: String) {
        requestAuthorization { granted in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "BLE"
            content.subtitle = text
            content.sound = UNNotificationSound.default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        }
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if state == .peripheral {
            if peripheral.state == .poweredOn {
                self.peripheralManager.startAdvertising(self.beaconPeripheralData as? [String: Any])
            }
            else if peripheral.state == .poweredOff {
                peripheralManager.stopAdvertising()
            }
        }
        if state == .clientPeripheral {
            print("peripheralManagerDidUpdateState")
            
            if peripheral.state == .poweredOn {
                
                guard let service: CBMutableService = self.service else { return }
                
                self.peripheralManager?.removeAllServices()
                self.peripheralManager?.add(service)
                
            }
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if state == .clientPeripheral {
            print("\ndidAdd service")
            
            let advertisingData: [String: Any] = [
                CBAdvertisementDataServiceUUIDsKey: [self.service?.uuid],
                CBAdvertisementDataLocalNameKey: "Peripheral - iOS"
            ]
            self.peripheralManager?.stopAdvertising()
            self.peripheralManager?.startAdvertising(advertisingData)
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("peripheralManagerDidStartAdvertising")
        self.blueEar?.didStartAdvertising()
    }
    
    // Listen to dynamic values
    // Called when CBPeripheral .setNotifyValue(true, for: characteristic) is called from the central
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
        if state == .clientPeripheral {
            print("\ndidSubscribeTo characteristic")
            
            guard let characterisctic: CBMutableCharacteristic = self.characterisctic else { return }
            Pulsar.delay(for: 20) {
                do {
                    var dict: [String: Any] = [: ]
                    if UserDefaults.standard.bool(forKey: "sendQuotes") == true {
                        dict = ["Quote": EncouragingQuotes.getQuote()]
                    } else {
                        dict = AmazingFinds.getPlace()
                    }
                    let data: Data = try PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0)
                    self.peripheralManager?.updateValue(data, for: characterisctic, onSubscribedCentrals: [central])
                    self.blueEar?.didSendData()
                } catch let error {
                    print(error)
                }
            }
        }
    }
    
    // Read static values
    // Called when CBPeripheral .readValue(for: characteristic) is called from the central
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if state == .clientPeripheral {
            print("\ndidReceiveRead request")
            if let uuid: CBUUID = self.characterisctic?.uuid, request.characteristic.uuid == uuid {
                print("Match characteristic for static reading")
            }
        }
    }
    
    // Called when receiving writing from Central.
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        if state == .clientPeripheral {
            print("\ndidReceiveWrite requests")
            
            guard
                let characteristicCBUUID: CBUUID = self.characteristicCBUUID,
                let request: CBATTRequest = requests.filter({ $0.characteristic.uuid == characteristicCBUUID }).first,
                let value: Data = request.value
            else {
                for request: CBATTRequest in requests {
                    if let value: Data = request.value, request.offset > value.count {
                        print("Sending response: Error offset")
                        self.peripheralManager?.respond(to: request, withResult: .invalidOffset)
                    }
                }
                return
            }
            
            // Send response to central if this writing request asks for response [.withResponse]
            print("Sending response: Success")
            self.peripheralManager?.respond(to: request, withResult: .success)
            print("Match characteristic for writing")
            do {
                if let receivedData: [String: String] = try PropertyListSerialization.propertyList(from: value, options: [], format: nil) as? [String: String] {
                    print("Written value is: \(receivedData)")
                    self.sendLocalNotification(text: "Value written by central is: \(receivedData.first?.value)")
                    self.blueEar?.didReceiveData(data: receivedData)
                } else {
                    return
                }
            } catch let error {
                print(error)
            }
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        if state == .clientPeripheral {
            print("\ndidUnsubscribeFrom characteristic")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        if state == .clientPeripheral {
            print("willRestoreState")
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        if state == .clientPeripheral {
            print("peripheralManagerIsReady")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension BluetoothManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    startScanning()
                    self.blueEar?.didStartScanningPeripherals()
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            print(beacons[0])
            blueEar?.didRangeBeacons(beacons: beacons)
        } else {
            print("Nothing found")
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("\ncentralManagerDidUpdateState \(Date())")
        if central.state == .poweredOn {
            guard let serviceCBUUID: CBUUID = self.serviceCBUUID else { return }
            self.blueEar?.didStartScanningPeripherals()
            self.centralManager?.scanForPeripherals(withServices: [serviceCBUUID], options: nil)
            
            //Iterate through array of connected UUIDS
                let keysArray = Array(self.sensorPeripheral.keys)
                    for i in 0..<keysArray.count {

            //Check if peripheral exists for given UUID
                       if let peripheral = self.sensorPeripheral[keysArray[i]] {
                        print("peripheral exists")

            //Check if services exist within the peripheral
                        if let services = peripheral.services {
                             print("services exist")

            //Check if predefined serviceUUID exists within services
                            if let serviceIndex = services.firstIndex(where: {$0.uuid == serviceCBUUID}) {
                                 print("serviceUUID exists within services")
                                let transferService = services[serviceIndex]
                                guard let characteristicUUID = characteristicCBUUID else { return }

            //Check if predefined characteristicUUID exists within serviceUUID
                                if let characteristics = transferService.characteristics {
                                     print("characteristics exist within serviceUUID")

                                    if let characteristicIndex = characteristics.firstIndex(where: {$0.uuid == characteristicUUID}) {
                                         print("characteristcUUID exists within serviceUUID")
                                        let characteristic = characteristics[characteristicIndex]

            //If characteristicUUID exists, begin getting notifications from it
                                        if !characteristic.isNotifying {
                                             print("subscribe if not notifying already")
                                            peripheral.setNotifyValue(true, for: characteristic)
                                        }
                                        else {
                                             print("invoke discover characteristics")
                                        peripheral.discoverCharacteristics([characteristicUUID], for: transferService)
                                        }
                                    }
                                }
                            }
                            else {
                                print("invoke discover characteristics")
                                peripheral.discoverServices([serviceCBUUID])
                            }
                        }
                    }
                }
        
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // We must keep a reference to the new discovered peripheral, which means we must retain it.
        self.discoveredPeripheral = peripheral
        sensorPeripheral[peripheral.identifier] = peripheral
        print("\ndidDiscover:", self.discoveredPeripheral?.name ?? "")
        self.discoveredPeripheral?.delegate = self
        guard let discoveredPeripheral: CBPeripheral = self.discoveredPeripheral else { return }
        self.centralManager?.connect(discoveredPeripheral,
                                     options: [CBConnectPeripheralOptionNotifyOnConnectionKey:true,
                                            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("\ndidConnect", self.discoveredPeripheral?.name ?? "")
        self.blueEar?.didConnectPeripheral(name: peripheral.name ?? "")
        guard let serviceCBUUID: CBUUID = self.serviceCBUUID else {
            self.discoveredPeripheral?.discoverServices(nil)
            return
        }
        self.discoveredPeripheral?.discoverServices([serviceCBUUID])
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("willRestoreState")
        if let peripheralsObject = dict[CBCentralManagerRestoredStatePeripheralsKey] {
            let peripherals = peripheralsObject as! Array<CBPeripheral>
            print ("starting restorestate code")
            if peripherals.count > 0 {
                for i in 0 ..< peripherals.count {
                    print ("starting restorecheck")
                    //Check if the peripheral exists within our list of connected peripherals, and assign delegate if it does
                    if self.sensorPeripheral.keys.contains(peripherals[i].identifier) {
                        peripherals[i].delegate = self
                    }
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didRetrievePeripherals peripherals: [CBPeripheral]) {
        print("\ndidRetrievePeripherals")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("\ndidFailToConnect")
        self.blueEar?.didFailConnection()
    }
    
    func centralManager(_ central: CBCentralManager, didRetrieveConnectedPeripherals peripherals: [CBPeripheral]) {
        print("\ndidRetrieveConnectedPeripherals")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("\ndidDisconnectPeripheral", self.discoveredPeripheral?.name ?? "")
        self.blueEar?.didDisconnectPeripheral(name: peripheral.name ?? "")
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("\ndidDiscoverServices")
        if let service: CBService = self.discoveredPeripheral?.services?.filter({ $0.uuid == self.serviceCBUUID }).first {
            guard let characteristicCBUUID: CBUUID = self.characteristicCBUUID else { return }
            self.discoveredPeripheral?.discoverCharacteristics([characteristicCBUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("\ndidWriteValueFor \(Date())")
        //// After we write data on peripheral, we disconnect it.
        //self.centralManager?.cancelPeripheralConnection(peripheral)
        //// We stop scanning.
        //self.centralManager?.stopScan()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("\ndidDiscoverCharacteristicsFor")
        if let characteristic: CBCharacteristic = service.characteristics?.filter({ $0.uuid == self.characteristicCBUUID }).first {
            print("Matching characteristic")
            // To listen and read dynamic values
            self.discoveredPeripheral?.setNotifyValue(true, for: characteristic)
            // To read static values
            // self.discoveredPeripheral?.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("\ndidUpdateValueFor")
        // We read
        if let value: Data = characteristic.value {
            do {
                let receivedData: [String: String] = try PropertyListSerialization.propertyList(from: value, options: [], format: nil) as! [String: String]
                print("Value read is: \(receivedData)")
                self.sendLocalNotification(text: "Value written by Peripheral is: \(receivedData.first?.value ?? "")")
                self.blueEar?.didReceiveData(data: receivedData)
            } catch let error {
                print(error)
            }
        }
        
        // We write
//        do {
//
//            print("\nWriting on peripheral.")
//
//            let dict: [String: String] = ["Da": "YA s4ital"]
//            let data: Data = try PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0)
//
//            self.discoveredPeripheral?.writeValue(data, for: characteristic, type: .withResponse)
//            self.blueEar?.didSendData()
//        } catch let error {
//            print(error)
//        }
    }
    
    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        print("\nperipheralDidUpdateRSSI")
        print(self.discoveredPeripheral?.readRSSI ?? "")
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        print("\nperipheralDidUpdateName")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("\ndidWriteValueFor")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("\ndidModifyServices")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("\ndidUpdateValueFor")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        print("\ndidDiscoverIncludedServicesFor")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("\ndidDiscoverDescriptorsFor")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("\ndidUpdateNotificationStateFor")
    }
}
