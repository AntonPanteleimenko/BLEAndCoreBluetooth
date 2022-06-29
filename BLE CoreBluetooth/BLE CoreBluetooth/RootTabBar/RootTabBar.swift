//
//  RootTabBar.swift
//  BLE CoreBluetooth
//
//  Created by user on 30.11.2021.
//

import UIKit

class RootTabBar: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        UITabBar.appearance().barTintColor = .systemBackground
        tabBar.tintColor = .label
        setupVCs()
    }
    
    fileprivate func createNavController(for rootViewController: UIViewController,
                                         title: String,
                                         image: UIImage) -> UIViewController {
        
        let navController = UINavigationController(rootViewController: rootViewController)
        navController.tabBarItem.title = title
        navController.tabBarItem.image = image
        navController.navigationBar.prefersLargeTitles = true
        
        return navController
    }
    
    func setupVCs() {
        
        viewControllers = [
            createNavController(for: BLETransmitterVC(),
                                   title: NSLocalizedString("Transmitter", comment: ""),
                                   image: UIImage(named: "transmitter")!),
            createNavController(for: BLEBeaconVC(),
                                   title: NSLocalizedString("iBeacon", comment: ""),
                                   image: UIImage(named: "ibeacon")!),
            createNavController(for: BLESendDataSettingsVC(),
                                   title: NSLocalizedString("Settings", comment: ""),
                                   image: UIImage(named: "settings")!)
        ]
    }
}
