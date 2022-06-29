//
//  BLEVCFactory.swift
//  BLE CoreBluetooth
//
//  Created by user on 30.11.2021.
//

import UIKit

enum ControllerType {
    case transmitter
    case beacon
}

protocol BLEVCFactoryProtocol: AnyObject {
    func createBLEViewWith(type: ManagerState, vcStyle: ControllerType) -> BLEViewConstructor
}

class BLEVCFactory: BLEVCFactoryProtocol {
    
    static let shared = BLEVCFactory()
    
    private init() { }
    
    
    func createBLEViewWith(type: ManagerState, vcStyle: ControllerType) -> BLEViewConstructor {
        let view = BLEViewConstructor(type: type, vcStyle: vcStyle)
        return view
    }
}
