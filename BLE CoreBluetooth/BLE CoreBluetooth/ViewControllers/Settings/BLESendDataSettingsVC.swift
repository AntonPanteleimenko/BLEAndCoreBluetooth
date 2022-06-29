//
//  BLESendDataSettingsVC.swift
//  BLE CoreBluetooth
//
//  Created by user on 30.11.2021.
//

import UIKit

class BLESendDataSettingsVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        initalSelection()
        constructView()
    }
    
    let settingPickerItems: [String] = [
        "Send quotes",
        "Send places"
    ]
    
    fileprivate lazy var selectBLETypePicker: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        picker.backgroundColor = .darkGray
        return picker
    }()
    
    func initalSelection() {
        let sendQuotes = UserDefaults.standard.bool(forKey: "sendQuotes")
        selectBLETypePicker.selectRow(sendQuotes ? 0 : 1, inComponent: 0, animated: true)
    }
    
    func constructView() {
        view.addSubview(selectBLETypePicker)
        selectBLETypePicker.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.height.equalTo(150)
        }
    }
}

extension BLESendDataSettingsVC: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return settingPickerItems[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if settingPickerItems[row] == "Send quotes" {
            UserDefaults.standard.set(true, forKey: "sendQuotes")
        } else {
            UserDefaults.standard.set(false, forKey: "sendQuotes")
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: settingPickerItems[row],
                                      attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
    }
}
