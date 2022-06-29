//
//  Pulsar.swift
//  BLE CoreBluetooth
//
//  Created by user on 30.11.2021.
//

import Foundation

class Pulsar {
    
    // MARK: - Functions
    
    static func async(block: @escaping () -> Void) { DispatchQueue.main.async(execute: block) }
    
    static func delay(for delay: TimeInterval, block: @escaping () -> Void) {
        Timer.scheduledTimer(withTimeInterval: delay, repeats: true) { _ in
            //DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: block)
            block()
        }
    }
}
