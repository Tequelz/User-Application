import UIKit
import CoreBluetooth

class QRBTViewController: UIViewController, CBPeripheralManagerDelegate {
  
    
    var peripheralManager: CBPeripheralManager!
    var characteristic: CBCharacteristic!
    var central: CBCentral!
    
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else {return}
    }
    
    func sendDataToCentral(){
        let data = "Hello again".data(using: .utf8)!
        peripheralManager.updateValue(data, for: characteristic as! CBMutableCharacteristic, onSubscribedCentrals: [central])
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let request = requests.first, let data = request.value else {return}
        let message = String(decoding: data, as: UTF8.self)
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let peripheralManager = CBPeripheralManager(delegate:self,queue: nil)
        
        let characteristicID = CBUUID(string: "E06F95E4-FCFC-42C6-B4F8-F6BAE87EA1A1")
        
        self.characteristic = CBMutableCharacteristic(type: characteristicID, properties: [.write,.notify], value: nil, permissions: .writeable)
        
        let serviceID = CBUUID(string: "E06F95E4-FCFC-42C6-B4F8-F6BAE87EA1A0")
        let service = CBMutableService(type: serviceID, primary: true)
        service.characteristics = [characteristic]
        
        peripheralManager.add(service)
        
        peripheralManager.startAdvertising([CBAdvertisementDataServiceDataKey: [service],
                                            CBAdvertisementDataLocalNameKey: "George's Phone"])
    }

}
