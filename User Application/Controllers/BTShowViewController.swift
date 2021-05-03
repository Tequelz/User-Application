//
//  BTShowViewController.swift
//  User Application
//
//  Created by John Doe on 02/05/2021.
//

import UIKit
import CoreLocation

class BTShowViewController: UIViewController, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var teacherEmailTextBox: UITextField!
    
    var key:String = ""
    var lecture_number = ""
    var lecture_length = ""
    var lecture_id:Int = 0
    var userID:Int = 0
    var teacherEmail = ""
    

    var locationManager : CLLocationManager!
    
    func failed(error: String) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title:error, message: nil,preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(ac,animated: true)
        }
    }
    
    func success(notif: String) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title:notif, message: nil,preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(ac,animated: true)
        }
    }
    
    

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
                self.failed(error: "Error in app side (When getting user details)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                print ("server error")
                self.failed(error: "Error in server side (When getting user details)")
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
        
        self.teacherEmail = teacherEmailTextBox.text!
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func searchButton(_ sender: Any) {
        self.teacherEmail = teacherEmailTextBox.text!
        self.success(notif: "Began searching for teacher with email \(self.teacherEmail)")
        if self.teacherEmail == "" {
            self.failed(error: "You didnt enter a teacher's email correctly, for connection please enter the email of your teacher")
        }else{
            locationManager = CLLocationManager.init()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            startScanningForBeaconRegion(beaconRegion: getBeaconRegion(teacher: self.teacherEmail), beaconConstraint: getBeaconIdentityConstraint())
            
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        let beacon = beacons.last
           
           if beacons.count > 0 {
            let minorString = String((beacon?.minor.stringValue)!)
            print(minorString)
            if beacon?.minor.stringValue.count == 5 {
                let char1 = minorString[minorString.index(minorString.startIndex,offsetBy: 0)]
                self.lecture_number = self.lecture_number+[char1]
                let char2 = minorString[minorString.index(minorString.startIndex,offsetBy: 1)]
                self.lecture_number = self.lecture_number+[char2]
                let char3 = minorString[minorString.index(minorString.startIndex,offsetBy: 2)]
                self.lecture_length = self.lecture_length+[char3]
                let char4 = minorString[minorString.index(minorString.startIndex,offsetBy: 3)]
                self.lecture_length = self.lecture_length+[char4]
                let char5 = minorString[minorString.index(minorString.startIndex,offsetBy: 4)]
                self.lecture_length = self.lecture_length+[char5]
            }else if beacon?.minor.stringValue.count == 4{
                self.lecture_number = String(minorString[minorString.index(minorString.startIndex,offsetBy: 0)])
                print(self.lecture_number)
                let char1 = minorString[minorString.index(minorString.startIndex,offsetBy: 1)]
                self.lecture_length = self.lecture_length+[char1]
                let char2 = minorString[minorString.index(minorString.startIndex,offsetBy: 2)]
                self.lecture_length = self.lecture_length+[char2]
                let char3 = minorString[minorString.index(minorString.startIndex,offsetBy: 3)]
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
                    self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion(teacher: self.teacherEmail), beaconConstraint: self.getBeaconIdentityConstraint())
                    self.failed(error: "Error in app side (When checking lecture details)")
                    return
                }
                guard let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) else {
                    print ("server error")
                    self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion(teacher: self.teacherEmail), beaconConstraint: self.getBeaconIdentityConstraint())
                    self.failed(error: "Error in server side (When checking lecture details)")
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
                                            self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion(teacher: self.teacherEmail), beaconConstraint: self.getBeaconIdentityConstraint())
                                            self.failed(error: "Error in app side (When checking user attendance)")
                                            return
                                        }
                                        guard let response = response as? HTTPURLResponse,
                                            (200...299).contains(response.statusCode) else {
                                            print ("server error")
                                            self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion(teacher: self.teacherEmail), beaconConstraint: self.getBeaconIdentityConstraint())
                                            self.failed(error: "Error in server side (When checking user attendance)")
                                            return
                                        }
                                        if let mimeType = response.mimeType,
                                            mimeType == "application/json",
                                            let data = data,
                                            let dataString = String(data: data, encoding: .utf8) {
                                            print ("got data: \(dataString)")
                                            self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion(teacher: self.teacherEmail), beaconConstraint: self.getBeaconIdentityConstraint())
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
           }
    }
    
    func getBeaconRegion(teacher: String) -> CLBeaconRegion {
        let uuid = UUID(uuidString: "E06F95E4-FCFC-42C6-B4F8-F6BAE87EA1A0")
        let beaconRegion = CLBeaconRegion.init(uuid: uuid!, identifier: teacher)
        return beaconRegion
    }
    
    func getBeaconIdentityConstraint() -> CLBeaconIdentityConstraint {
        let uuid = UUID(uuidString: "E06F95E4-FCFC-42C6-B4F8-F6BAE87EA1A0")
        let beaconIdentityConstraint = CLBeaconIdentityConstraint.init(uuid: uuid!)
        return beaconIdentityConstraint
    }
    
    func startScanningForBeaconRegion(beaconRegion: CLBeaconRegion, beaconConstraint: CLBeaconIdentityConstraint) {
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(satisfying: beaconConstraint)
    }
    
    func stopScanningForBeaconRegion(beaconRegion: CLBeaconRegion, beaconConstraint: CLBeaconIdentityConstraint){
        locationManager.stopMonitoring(for: beaconRegion)
        locationManager.stopRangingBeacons(satisfying: beaconConstraint)
    }
}
