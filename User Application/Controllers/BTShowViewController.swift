//
//  BTShowViewController.swift
//  User Application
//
//  Created by John Doe on 02/05/2021.
//

import UIKit
import CoreLocation

class BTShowViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var iBeaconFoundLabel: UILabel!
        @IBOutlet weak var proximityUUIDLabel: UILabel!
        @IBOutlet weak var majorLabel: UILabel!
        @IBOutlet weak var minorLabel: UILabel!
        @IBOutlet weak var accuracyLabel: UILabel!
        @IBOutlet weak var distanceLabel: UILabel!
        @IBOutlet weak var rssiLabel: UILabel!
    
    
    
    var key:String = ""
    var lecture_number = ""
    var lecture_length = ""
    var lecture_id:Int = 0
    var userID:Int = 0
    

    var locationManager : CLLocationManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let jsonData = key.data(using: .utf8)!
        let authKey: AuthKey = try! JSONDecoder().decode(AuthKey.self, from: jsonData)
        
        let url = URL(string: "https://project-api-sc17gt.herokuapp.com/rest-auth/user/")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token " + authKey.key, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                print ("server error")
                return
            }
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data,
                let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments){
                if let jsonArray = jsonObj as? NSDictionary{
                    let userID = jsonArray.value(forKey: "pk")
                    self.userID = userID as! Int
                }
            }
        }
        task.resume()
        locationManager = CLLocationManager.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        startScanningForBeaconRegion(beaconRegion: getBeaconRegion())
        // Do any additional setup after loading the view.
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        let beacon = beacons.last
           
           if beacons.count > 0 {
            var minorString = String((beacon?.minor.stringValue)!)
            print(minorString)
            if beacon?.minor.stringValue.count == 5 {
                var char1 = minorString[minorString.index(minorString.startIndex,offsetBy: 0)]
                self.lecture_number = self.lecture_number+[char1]
                var char2 = minorString[minorString.index(minorString.startIndex,offsetBy: 1)]
                self.lecture_number = self.lecture_number+[char2]
                var char3 = minorString[minorString.index(minorString.startIndex,offsetBy: 2)]
                self.lecture_length = self.lecture_length+[char3]
                var char4 = minorString[minorString.index(minorString.startIndex,offsetBy: 3)]
                self.lecture_length = self.lecture_length+[char4]
                var char5 = minorString[minorString.index(minorString.startIndex,offsetBy: 4)]
                self.lecture_length = self.lecture_length+[char5]
            }else if beacon?.minor.stringValue.count == 4{
                self.lecture_number = String(minorString[minorString.index(minorString.startIndex,offsetBy: 0)])
                print(self.lecture_number)
                var char1 = minorString[minorString.index(minorString.startIndex,offsetBy: 1)]
                self.lecture_length = self.lecture_length+[char1]
                var char2 = minorString[minorString.index(minorString.startIndex,offsetBy: 2)]
                self.lecture_length = self.lecture_length+[char2]
                var char3 = minorString[minorString.index(minorString.startIndex,offsetBy: 3)]
                self.lecture_length = self.lecture_length+[char3]
            }
            
            let jsonData = key.data(using: .utf8)!
            let authKey: AuthKey = try! JSONDecoder().decode(AuthKey.self, from: jsonData)
            
            
            print(self.lecture_length)
            print(self.lecture_number)
            
            let lecture = LectureData(lec_id: Int(beacon!.major), lec_number: Int(self.lecture_number)!, lec_length: Int(self.lecture_length)!)
            guard let uploadData = try? JSONEncoder().encode(lecture) else {
                return
            }
            
            let url = URL(string: "https://project-api-sc17gt.herokuapp.com/lecture-check/")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Token " + authKey.key, forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
                if let error = error {
                    print ("error: \(error)")
                    self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion())
                    return
                }
                guard let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) else {
                    print ("server error")
                    self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion())
                    return
                }
                if let mimeType = response.mimeType,
                    mimeType == "application/json",
                    let data = data,
                    let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments){
                    if let jsonArray = jsonObj as? NSArray{
                        for obj in jsonArray{
                            if let objDict = obj as? NSDictionary{
                                if let lecture_id = objDict.value(forKey: "pk"){
                                self.lecture_id = lecture_id as! Int
                                    print(self.lecture_id)
                                    
                                    let userAttend = UserAttend(username:self.userID, lecture_id: self.lecture_id)
                                    print(userAttend)
                                    
                                    guard let uploadData = try? JSONEncoder().encode(userAttend)else{
                                        return
                                    }
                                    print(uploadData)
                                    
                                    let url = URL(string: "https://project-api-sc17gt.herokuapp.com/user-attend/")!
                                    var request = URLRequest(url: url)
                                    request.httpMethod = "POST"
                                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                                    request.setValue("Token " + authKey.key, forHTTPHeaderField: "Authorization")
                                    
                                    let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
                                        if let error = error {
                                            print ("error: \(error)")
                                            self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion())
                                            return
                                        }
                                        guard let response = response as? HTTPURLResponse,
                                            (200...299).contains(response.statusCode) else {
                                            print ("server error")
                                            self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion())
                                            return
                                        }
                                        if let mimeType = response.mimeType,
                                            mimeType == "application/json",
                                            let data = data,
                                            let dataString = String(data: data, encoding: .utf8) {
                                            print ("got data: \(dataString)")
                                            self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion())
                                            DispatchQueue.main.async {
                                                    
                                                let story = UIStoryboard(name: "Main",bundle:nil)
                                                let controller = story.instantiateViewController(identifier: "LoggedIn") as! UIViewController
                                                    controller.modalPresentationStyle = .fullScreen
                                                    controller.modalTransitionStyle = .crossDissolve
                                                    self.present(controller, animated: true, completion: nil)
                                            }
                                        }
                                    }
                                    task.resume()
                                }
                            }
                        }
                    }
                }
            }
            task.resume()
            
//               iBeaconFoundLabel.text = "Yes"
//               proximityUUIDLabel.text = beacon?.proximityUUID.uuidString
//               majorLabel.text = beacon?.major.stringValue
//               minorLabel.text = beacon?.minor.stringValue
//               accuracyLabel.text = String(describing: beacon?.accuracy)
//               if beacon?.proximity == CLProximity.unknown {
//                   distanceLabel.text = "Unknown Proximity"
//               } else if beacon?.proximity == CLProximity.immediate {
//                   distanceLabel.text = "Immediate Proximity"
//               } else if beacon?.proximity == CLProximity.near {
//                   distanceLabel.text = "Near Proximity"
//               } else if beacon?.proximity == CLProximity.far {
//                   distanceLabel.text = "Far Proximity"
//               }
//               rssiLabel.text = String(describing: beacon?.rssi)
           } else {
               iBeaconFoundLabel.text = "No"
               proximityUUIDLabel.text = ""
               majorLabel.text = ""
               minorLabel.text = ""
               accuracyLabel.text = ""
               distanceLabel.text = ""
               rssiLabel.text = ""
           }
//
//           print("Ranging")
    }
    
    func getBeaconRegion() -> CLBeaconRegion {
        let beaconRegion = CLBeaconRegion.init(proximityUUID: UUID.init(uuidString: "E06F95E4-FCFC-42C6-B4F8-F6BAE87EA1A0")!,
                                               identifier: "teacher1")
        return beaconRegion
    }
    
    func startScanningForBeaconRegion(beaconRegion: CLBeaconRegion) {
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
    }
    
    func stopScanningForBeaconRegion(beaconRegion: CLBeaconRegion){
        locationManager.stopMonitoring(for: beaconRegion)
        locationManager.stopRangingBeacons(in: beaconRegion)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    

}
