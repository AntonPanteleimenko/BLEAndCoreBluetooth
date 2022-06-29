//
//  AmazingFinds.swift
//  BLE CoreBluetooth
//
//  Created by user on 30.11.2021.
//

import Foundation
import CoreLocation

class Place: NSObject, NSCoding, NSSecureCoding {
    
    static var supportsSecureCoding: Bool {
        return true
    }
    
    private var _name: String!
    private var _latitude: String!
    private var _longitude: String!
        
    var name: String {
        get {
            return _name
        }
        set {
            _name = newValue
        }
    }
    
    var latitude: String {
        get {
            return _latitude
        }
        set {
            _latitude = newValue
        }
    }
    
    var longitude: String {
        get {
            return _longitude
        }
        set {
            _longitude = newValue
        }
    }
    
    init(name: String, latitude: String, longitude: String) {
        _name = name
        _latitude = latitude
        _longitude = longitude
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(latitude, forKey: "latitude")
        aCoder.encode(longitude, forKey: "longitude")
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: "name") as! String
        let latitude = aDecoder.decodeObject(forKey: "latitude") as! String
        let longitude = aDecoder.decodeObject(forKey: "longitude") as! String
        self.init(name: name, latitude: latitude, longitude: longitude)
    }
}

class AmazingFinds {
    
    fileprivate static let places: [Place] = [
        Place(name: "Copenhagen, Denmark", latitude: "55.6761", longitude: "12.5683"),
        Place(name: "Moscow, Russia", latitude: "55.7558", longitude: "37.6173"),
        Place(name: "Stockholm, Sweden", latitude: "59.32", longitude: "18.06"),
        Place(name: "Amsterdam, Netherlands", latitude: "52.36", longitude: "4.9"),
        Place(name: "Gothenburg, Sweden", latitude: "57.7", longitude: "11.9667"),
        Place(name: "Helsinki, Finland", latitude: "60.1699", longitude: "24.94"),
        Place(name: "Tver', Russia", latitude: "56.8587", longitude: "35.9176")
    ]
    
    static fileprivate var previousPlace: Place?
    
    static func getPlace() -> [String: Any] {
        if let randomPlace = places.randomElement() {
            if randomPlace != previousPlace {
                previousPlace = randomPlace
                return [randomPlace.latitude: randomPlace.longitude]
            } else {
                return getPlace()
            }
        }
        return [places[0].latitude: places[0].longitude]
    }
}
