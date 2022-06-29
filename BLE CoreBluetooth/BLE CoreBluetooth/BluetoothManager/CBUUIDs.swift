//
//  CBUUIDs.swift
//  BLE CoreBluetooth
//
//  Created by user on 29.11.2021.
//

import Foundation

import CoreBluetooth
import CoreLocation

struct CBUUIDs {
    /// iBeacon Broadcast
    static let localBeaconUUID = "7D0D9B66-0554-4CCF-A6E4-ADE12325C4F0"
    static let localBeaconMajor: CLBeaconMajorValue = 123
    static let localBeaconMinor: CLBeaconMinorValue = 789
    static let identifier = "MyIBecon"
    
    /// Client/Server
    static let centralId: String = "62443cc7-15bc-4136-bf5d-0ad80c459216"
    static let serviceUUID: String = "0cdbe648-eed0-11e6-bc64-92361f002671"
    static let characteristicUUID: String = "199ab74c-eed0-11e6-bc64-92361f002672"

    /// ClientPeripheral
    static let peripheralId: String = "62443cc7-15bc-4136-bf5d-0ad80c459215"
    static let localName: String = "Client Peripheral - iOS Device"
}
