//
//  ViewController.swift
//  BluetoothSender
//
//  Created by Jay Tucker on 9/23/14.
//  Copyright (c) 2014 Jay. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    let serviceUUIDs = [
        "7AC5A6A8-4DD7-4386-9CD7-D6DF5155A131",
        "84F00541-B4F8-44CC-B96A-C8872CF164BB",
        "59541099-A405-4947-BA70-4D777F38DB8F",
        "B427777C-0153-4486-A87C-FE153686D754",
        "D1517163-EA5E-4F51-9DBD-B0E8D7BB5F55",
        "594B5A2A-1D8C-4D9D-ACA3-B371969DADF0",
        "B590B847-9804-46E3-9818-B5D81118FCFD",
        "24BBB39B-01AA-45C5-9827-9F2582656E29",
    ]

    let characteristicUUIDs = [
        "F93047DC-870A-4172-8B91-AD8F4EFBF21D",
        "E8C9186B-3B16-469B-BEAD-44BDF1CAB2B8",
        "9F7FD713-4357-4D41-A588-58560CDF7D81",
        "31A1ECA2-7AAF-4CBD-956E-21EF295E0A5C",
        "6EB70B8B-0D1D-408A-8174-3B6F9CE33766",
        "BADF0FEC-0616-4C28-B3DE-5CA1981E72AD",
        "968D7D5F-BB21-4028-87A3-33E6631156E0",
        "886484C7-DF60-4C05-A9EF-51D26EAFF309",
    ]
    
    // must be 1-8; no greater than 8
    let nServiceSwitches = 8
    let nCharacteristics = 4
    
    var peripheralManager: CBPeripheralManager!
    
    var isPoweredOn = false
    
    // use this to wait until all the services have been added before we start advertising
    var nServicesAdded = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupUI()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI() {
        var previousView = view
        
        for i in 1 ... nServiceSwitches {
            println("Service \(i) \(serviceUUIDs[i - 1])")
            
            let label = UILabel()
            label.text = "Service " + String(i)
            label.setTranslatesAutoresizingMaskIntoConstraints(false)
            view.addSubview(label)
            
            let serviceSwitch = UISwitch()
            serviceSwitch.tag = 100 + i
            serviceSwitch.on = true
            serviceSwitch.addTarget(self, action: Selector("serviceChanged:"), forControlEvents: .ValueChanged)
            serviceSwitch.setTranslatesAutoresizingMaskIntoConstraints(false)
            view.addSubview(serviceSwitch)
            
            var constraint: NSLayoutConstraint
            
            constraint = NSLayoutConstraint(
                item: label,
                attribute: NSLayoutAttribute.Leading,
                relatedBy: NSLayoutRelation.Equal,
                toItem: view,
                attribute: NSLayoutAttribute.Leading,
                multiplier: 1.0,
                constant: 40.0)
            view.addConstraint(constraint)

            constraint = NSLayoutConstraint(
                item: label,
                attribute: NSLayoutAttribute.Top,
                relatedBy: NSLayoutRelation.Equal,
                toItem: previousView,
                attribute: NSLayoutAttribute.Top,
                multiplier: 1.0,
                constant: 40.0)
            view.addConstraint(constraint)
            
            constraint = NSLayoutConstraint(
                item: serviceSwitch,
                attribute: NSLayoutAttribute.Trailing,
                relatedBy: NSLayoutRelation.Equal,
                toItem: view,
                attribute: NSLayoutAttribute.Trailing,
                multiplier: 1.0,
                constant: -40.0)
            view.addConstraint(constraint)
            
            constraint = NSLayoutConstraint(
                item: serviceSwitch,
                attribute: NSLayoutAttribute.CenterY,
                relatedBy: NSLayoutRelation.Equal,
                toItem: label,
                attribute: NSLayoutAttribute.CenterY,
                multiplier: 1.0,
                constant: 0.0)
            view.addConstraint(constraint)
            
            previousView = label
        }
    }
    
    // helper func
    
    func indexOfString(string: String, inArray array: [String]) -> Int {
        for i in 0 ..< array.count {
            if array[i] == string {
                return i
            }
        }
        return -1
    }
    
    func serviceChanged(sender: AnyObject) {
        let message = "Service " + String(sender.tag - 100) + " switched " + ((sender as UISwitch).on ? "on" : "off")
        println(message)
        if isPoweredOn {
            updateServices()
        }
    }
    
    func createService(uuidString: String) -> CBMutableService {
        return CBMutableService(type: CBUUID(string: uuidString), primary: true)
    }
    
    func createCharacteristic(uuidString: String) -> CBMutableCharacteristic {
        return CBMutableCharacteristic(
            type: CBUUID(string: uuidString),
            properties: CBCharacteristicProperties.Read,
            value: nil,
            permissions: CBAttributePermissions.Readable)
    }
    
    func updateServices() {
        println("updateServices")
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        var services = Array<CBMutableService>()
        for i in 1 ... nServiceSwitches {
            let serviceSwitch: UISwitch = view.viewWithTag(100 + i) as UISwitch
            if serviceSwitch.on {
                let service = createService(serviceUUIDs[i - 1])
                var characteristics = Array<CBMutableCharacteristic>()
                for j in 1 ... nCharacteristics {
                    let characteristic = createCharacteristic(characteristicUUIDs[j - 1])
                    characteristics.append(characteristic)
                }
                service.characteristics = characteristics
                services.append(service)
            }
        }
        nServicesAdded = services.count
        for service in services {
            peripheralManager.addService(service)
        }
    }
    
    func startAdvertising() {
        println("startAdvertising")
        var uuids = Array<CBUUID>()
        for i in 1 ... nServiceSwitches {
            let serviceSwitch: UISwitch = view.viewWithTag(100 + i) as UISwitch
            if serviceSwitch.on {
                uuids.append(CBUUID(string: serviceUUIDs[i - 1]))
            }
        }
        peripheralManager.startAdvertising([ CBAdvertisementDataServiceUUIDsKey: uuids ])
    }
    
}

extension ViewController: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(peripheralManager: CBPeripheralManager!) {
        var caseString: String!
        switch peripheralManager.state {
        case .Unknown:
            caseString = "Unknown"
        case .Resetting:
            caseString = "Resetting"
        case .Unsupported:
            caseString = "Unsupported"
        case .Unauthorized:
            caseString = "Unauthorized"
        case .PoweredOff:
            caseString = "PoweredOff"
        case .PoweredOn:
            caseString = "PoweredOn"
        default:
            caseString = "WTF"
        }
        println("peripheralManagerDidUpdateState \(caseString)")
        isPoweredOn = (peripheralManager.state == .PoweredOn)
        if isPoweredOn {
            updateServices()
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didAddService service: CBService!, error: NSError!) {
        let uuid = "\(service.UUID)"
        let i = indexOfString(uuid, inArray: serviceUUIDs) + 1
        var message = "peripheralManager didAddService \(i) \(uuid) "
        if error == nil {
            message += "ok"
        } else {
            message = "error " + error.localizedDescription
        }
        println(message)
        nServicesAdded--;
        if nServicesAdded == 0 {
            startAdvertising()
        }
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager!, error: NSError!) {
        var message = "peripheralManagerDidStartAdvertising "
        if error == nil {
            message += "ok"
        } else {
            message = "error " + error.localizedDescription
        }
        println(message)
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didReceiveReadRequest request: CBATTRequest!) {
        let serviceUUID = request.characteristic.service.UUID.UUIDString
        let i = indexOfString(serviceUUID, inArray: serviceUUIDs) + 1
        let characteristicUUID = request.characteristic.UUID.UUIDString
        let j = indexOfString(characteristicUUID, inArray: characteristicUUIDs) + 1
        println("peripheralManager didReceiveReadRequest \(i) \(j) \(serviceUUID) \(characteristicUUID)")
        let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .ShortStyle, timeStyle: .MediumStyle)
        let response = "value for service \(i) characteristic \(j) on \(timestamp)"
        request.value = response.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        peripheralManager.respondToRequest(request, withResult: CBATTError.Success)
    }

}
