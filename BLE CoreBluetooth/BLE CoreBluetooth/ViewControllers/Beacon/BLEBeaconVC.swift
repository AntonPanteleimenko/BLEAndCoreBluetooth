//
//  BLEBeaconVC.swift
//  BLE CoreBluetooth
//
//  Created by user on 30.11.2021.
//

import UIKit
import CoreLocation

class BLEBeaconVC: UIViewController {
    
    // MARK: - Lifecyle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        manager = BluetoothManager(state: .peripheral, delegate: self)
        setupView()
        manager?.startManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)

        self.manager = nil
        bleView = nil
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    deinit {
        bleView = nil
    }
    
    // MARK: - Properties
    var manager: BluetoothManager?
    
    var bleView: BLEViewConstructor? {
        didSet {
            guard bleView != nil else {
                view = UIView()
                return
            }
            view = bleView
        }
    }
}

private extension BLEBeaconVC {
    
    // MARK: - Private funcs
    
    func setupView() {
        guard let manager = manager else { return }
        let view = BLEVCFactory.shared.createBLEViewWith(type: manager.state, vcStyle: .beacon)
        bleView = view
        bleView?.bleViewDelegate = self
    }
}

// MARK: - BlueEar Delegate

extension BLEBeaconVC: BlueEar {
    func didRangeBeacons(beacons: [CLBeacon]) {
        guard !beacons.isEmpty else { return }
        let beacon = beacons[0]
        bleView?.setTextsForBeaconState(with: beacon)
    }
    
    func didStartConfiguration() {
        bleView?.setInfoLabelText(with: "Start configuration 🎛")
    }
    
    func didStartScanningPeripherals() {
        bleView?.setInfoLabelText(with: "Start scanning peripherals 👀")
    }
    
    func didConnectPeripheral(name: String?) {
        bleView?.setInfoLabelText(with: "Did connect to: \(name ?? "") 🤜🏽🤛🏽")
    }
    
    func didDisconnectPeripheral(name: String?) {
        bleView?.setInfoLabelText(with: "Did disconnect: \(name ?? "") 🤜🏽🤚🏽")
    }
    
    func didSendData() {
        bleView?.setInfoLabelText(with: "Did send data ⬆️")
    }
    
    func didReceiveData(data: [String: String]) {
        let text = data.first?.value
        bleView?.setInfoLabelText(with: "Did received data ⬇️: \(text!)")
        //bleView?.setInfoLabelText(with: "Did received data ⬇️")
    }
    
    func didFailConnection() {
        bleView?.setInfoLabelText(with: "Connection failed 🤷🏽‍♂️")
    }
    
    func didStartAdvertising() {
        bleView?.setInfoLabelText(with: "Start advertising 📻")
    }
    
    func didStopAdvertising() {
        bleView?.setInfoLabelText(with: "Stop advertising 📻")
    }
}

// MARK: - BLEViewDelegate Delegate
extension BLEBeaconVC: BLEViewDelegate {
    func didSelectBLEType(type: ManagerState) {
        self.manager = nil
        self.bleView = nil
        
        manager = BluetoothManager(state: type, delegate: self)
        setupView()
        bleView?.selectPickerType()
        manager?.startManager()
    }
    
    func didPressStartMonitoring() {}
    func didPressStopMonitoring() {}
}
