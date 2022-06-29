//
//  BLEViewConstructor.swift
//  BLE CoreBluetooth
//
//  Created by user on 30.11.2021.
//

import UIKit
import CoreLocation
import SnapKit
import MapKit

protocol BLEViewDelegate: AnyObject {
    func didSelectBLEType(type: ManagerState)
    
    func didPressStartMonitoring()
    func didPressStopMonitoring()
}

final class BLEViewConstructor: UIView {
    
    let type: ManagerState
    let vcStyle: ControllerType
    
    init(type: ManagerState, vcStyle: ControllerType) {
        self.type = type
        self.vcStyle = vcStyle
        super.init(frame: .zero)
        
        backgroundColor = .black
        constructView()
    }
    
    deinit {
        bleViewDelegate = nil
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        selectBLETypePicker.layer.cornerRadius = 10
    }
    
    weak var bleViewDelegate: BLEViewDelegate?
    var annotations: [MKAnnotation] = []
    
    let transmitterPickerItems: [(String, ManagerState)] = [
        ("ClientPeripheral" , .clientPeripheral),
        ("ServerCentral"    , .serverCentral)
    ]
    
    let beaconPickerItems: [(String, ManagerState)] = [
        ("Peripheral"        , .peripheral),
        ("Central"           , .central)
    ]
    
    // MARK: - Views
    
    fileprivate lazy var infoLabel: UILabel = {
        let label: UILabel = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    fileprivate lazy var centralUUIDLabel: UILabel = {
        let label: UILabel = UILabel()
        label.numberOfLines = 1
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    fileprivate lazy var centralMajorLabel: UILabel = {
        let label: UILabel = UILabel()
        label.numberOfLines = 1
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    fileprivate lazy var centralMinorLabel: UILabel = {
        let label: UILabel = UILabel()
        label.numberOfLines = 1
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    fileprivate lazy var centralIdentityLabel: UILabel = {
        let label: UILabel = UILabel()
        label.numberOfLines = 1
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    fileprivate lazy var centralBeaconLabel: UILabel = {
        let label: UILabel = UILabel()
        label.numberOfLines = 1
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    fileprivate lazy var selectBLETypePicker: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        picker.backgroundColor = .darkGray
        return picker
    }()
    
    fileprivate lazy var mapView: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    fileprivate lazy var startMonitoringButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(startMonitoringButtonAction), for: .touchUpInside)
        button.setTitleColor(.white, for: .normal)
        button.sizeToFit()
        return button
    }()
    
    fileprivate lazy var stopMonitoringButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(stopMonitoringButtonAction), for: .touchUpInside)
        button.setTitleColor(.white, for: .normal)
        button.sizeToFit()
        return button
    }()
    
    func constructView() {
        
        addSubview(selectBLETypePicker)
        selectBLETypePicker.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(150)
            make.height.equalTo(150)
        }
        
        switch type {
        case .peripheral, .central:
            constructForPeripheralOrCentral()
        case .clientPeripheral, .serverCentral:
            constructForServerCentralOrClientPeripheral()
        }
    }
    
    func selectPickerType() {
        switch vcStyle {
        case .transmitter:
            let row = self.type == .clientPeripheral ? 0 : 1
            selectBLETypePicker.selectRow(row, inComponent: 0, animated: true)
        case .beacon:
            let row = self.type == .peripheral ? 0 : 1
            selectBLETypePicker.selectRow(row, inComponent: 0, animated: true)
        }
    }
    
    func setMapViewLocation(latitude: String, longitude: String) {
        let location = CLLocationCoordinate2D(latitude: Double(latitude)!,
                                              longitude: Double(longitude)!)
        
        convertLatLongToAddress(latitude: location.latitude, longitude: location.longitude)
        mapView.setCenter(location, animated: true)
        mapView.removeAnnotations(annotations)
        let anno = MKPointAnnotation()
        anno.coordinate = location
        mapView.addAnnotation(anno)
        annotations.append(anno)
    }
    
    func convertLatLongToAddress(latitude:Double,longitude:Double){
        
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { [weak self] (placemarks, error) -> Void in
            
            guard let self = self else { return }
            
            // Place details
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            
            var adress = ""
            
            // Country
            if let country = placeMark.country {
                adress += country + ", "
            }

            // City
            if let city = placeMark.locality {
                adress += city + ", "
            }
            
            // Street address
            if let street = placeMark.thoroughfare {
                adress += street
            }
            
            self.infoLabel.text = adress
        })
    }
}

extension BLEViewConstructor {
    private func constructForPeripheralOrCentral() {
        addSubview(centralUUIDLabel)
        centralUUIDLabel.snp.makeConstraints { make in
            make.height.equalTo(15)
            make.top.equalTo(selectBLETypePicker.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        addSubview(centralMajorLabel)
        centralMajorLabel.snp.makeConstraints { make in
            make.height.equalTo(15)
            make.top.equalTo(centralUUIDLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        addSubview(centralMinorLabel)
        centralMinorLabel.snp.makeConstraints { make in
            make.height.equalTo(15)
            make.top.equalTo(centralMajorLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        addSubview(centralIdentityLabel)
        centralIdentityLabel.snp.makeConstraints { make in
            make.height.equalTo(15)
            make.top.equalTo(centralMinorLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        addSubview(centralBeaconLabel)
        centralBeaconLabel.snp.makeConstraints { make in
            make.height.equalTo(15)
            make.top.equalTo(centralIdentityLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(centralBeaconLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
    }
    
    func constructForServerCentralOrClientPeripheral() {
        
        if self.vcStyle == .transmitter && (self.type == .serverCentral || self.type == .clientPeripheral) {
            addSubview(startMonitoringButton)
            startMonitoringButton.snp.makeConstraints { make in
                make.height.equalTo(20)
                make.bottom.equalToSuperview().offset(-200)
                make.leading.equalToSuperview().offset(20)
            }
            
            addSubview(stopMonitoringButton)
            stopMonitoringButton.snp.makeConstraints { make in
                make.height.equalTo(20)
                make.bottom.equalToSuperview().offset(-200)
                make.trailing.equalToSuperview().offset(-20)
            }
            
            if self.type == .serverCentral {
                stopMonitoringButton.setTitle("StopMonitoring", for: .normal)
                startMonitoringButton.setTitle("StartMonitoring", for: .normal)
            } else if self.type == .clientPeripheral {
                stopMonitoringButton.setTitle("StopAdvertising", for: .normal)
                startMonitoringButton.setTitle("StartAdvertising", for: .normal)
            }
        }
        
        if UserDefaults.standard.bool(forKey: "sendQuotes") {
            addSubview(infoLabel)
            infoLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.centerX.equalToSuperview()
                make.leading.equalToSuperview().offset(20)
                make.trailing.equalToSuperview().offset(-20)
            }
        } else {
            addSubview(infoLabel)
            infoLabel.snp.makeConstraints { make in
                make.top.equalTo(selectBLETypePicker.snp.bottom).offset(15)
                make.height.equalTo(15)
                make.leading.equalToSuperview().offset(20)
                make.trailing.equalToSuperview().offset(-20)
            }
            if self.vcStyle == .transmitter && self.type == .serverCentral {
                addSubview(mapView)
                mapView.snp.makeConstraints { make in
                    make.height.equalTo(170)
                    make.top.equalTo(infoLabel.snp.bottom).offset(15)
                    make.leading.equalToSuperview().offset(20)
                    make.trailing.equalToSuperview().offset(-20)
                }
            }
        }
    }
}

extension BLEViewConstructor {
    func setTextsForBeaconState(with beacon: CLBeacon) {
        centralUUIDLabel.text = "UUID: " + beacon.uuid.uuidString
        centralMajorLabel.text = "Major: " + beacon.major.stringValue
        centralMinorLabel.text = "Minor: " + beacon.minor.stringValue
        
        switch beacon.proximity {
        case .near, .immediate:
            centralIdentityLabel.text = "Proximity: beacon is near"
            break
        default:
            centralIdentityLabel.text = "Proximity: beacon is still far"
            break
        }
        
        centralBeaconLabel.text = "RSSI: " + String(beacon.rssi)
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "yyyy-MM-dd HH:mm:ss"
        infoLabel.text = dateFormatterPrint.string(from: beacon.timestamp)
    }
    
    func setInfoLabelText(with string: String) {
        self.infoLabel.text = string
    }
}

extension BLEViewConstructor: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch vcStyle {
        case.beacon:
            return beaconPickerItems[row].0
        case.transmitter:
            return transmitterPickerItems[row].0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch vcStyle {
        case.beacon:
            let value = beaconPickerItems[row]
            bleViewDelegate?.didSelectBLEType(type: value.1)
        case.transmitter:
            let value = transmitterPickerItems[row]
            bleViewDelegate?.didSelectBLEType(type: value.1)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        switch vcStyle {
        case.beacon:
            return NSAttributedString(string: beaconPickerItems[row].0,
                                      attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
        case.transmitter:
            return NSAttributedString(string: transmitterPickerItems[row].0,
                                      attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
        }
    }
}

extension BLEViewConstructor {
    @objc
    func startMonitoringButtonAction() {
        bleViewDelegate?.didPressStartMonitoring()
    }
    
    @objc
    func stopMonitoringButtonAction() {
        bleViewDelegate?.didPressStopMonitoring()
    }
}
