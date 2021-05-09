import UIKit
import CoreLocation //First part is importing the CoreLocation framework

class BTShowViewController: UIViewController, CLLocationManagerDelegate { //This class is used to find Bluetooth signals that reach certain requirements for a beaconRegion, if found that region is then used to log the user in
    
    
    @IBOutlet weak var teacherEmailTextBox: UITextField! //Allows the data entered on the instance of the view to be used within the class
    
    var key:String = "" //This is used to pass data from the previous view controller into this one
    var lecture_number = ""
    var lecture_length = "" //These two variables will be used to store their labelled values with them being generated later on
    var teacherEmail = "" //Used to store the data entered into the field
    var lecture_id:Int = 0
    var userID:Int = 0 //These values are used to create the LectureSession object on the API
    var locationManager : CLLocationManager! //The CoreLocationLocationManager is made here which manages all aspects of the finding of iBeacon signals
    
    func failed(error: String) {// This function is used to produce a pop up that lets the user know about an error
        DispatchQueue.main.async {
            let ac = UIAlertController(title:error, message: nil,preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(ac,animated: true)
        }
    }
    
    func getUser(){ //This function obtains the current user's information via a request and if returned correctly proceeds to obtain their own primary key using the getUserPK passing in data
        let url = URL(string: "https://project-api-sc17gt.herokuapp.com/rest-auth/user/")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token " + self.key, forHTTPHeaderField: "Authorization")
        
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
                let data = data{
                self.getUserPK(data: data)
            }
                
        }
        task.resume()
    }
    
    func getUserPK(data: Data){ //This function converts the data into a NSDictionary that can then have its primary key found and then saved to the instance variable userID
        if let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments){
            if let jsonArray = jsonObj as? NSDictionary{
                let userID = jsonArray.value(forKey: "pk")
                self.userID = userID as! Int
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) { //This is delegate method and runs if a beacon that matches the beaconRegion values is found. If found the beacon then has its major and minor keys converted into the lecture_number and lecture_length variables, with two routes dependent on the size of the minor key. Once the values have been set a LectureData structure instance is created and then requested to find the lectures id
        let beacon = beacons.last
           
           if beacons.count > 0 {
            let minorString = String((beacon?.minor.stringValue)!)
            if beacon?.minor.stringValue.count == 5 { //Here it checks the length of the minor value and proceeds to extract each character assigning it the corresponding variable
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
            
            let lecture = LectureData(lec_id: Int(beacon!.major), lec_number: Int(self.lecture_number)!, lec_length: Int(self.lecture_length)!)
            guard let uploadData = try? JSONEncoder().encode(lecture) else {
                return
            }
            self.lectureCheck(uploadData: uploadData)
           }
    }
    
    func lectureCheck(uploadData: Data){ //This function takes some data and then proceeds to try and obtain the details of a lecture, with the data returned being used to get the lectures id. Once found the user can then package the two values together to create a UserAttend instance that can be sent as data to log the user in
        let url = URL(string: "https://project-api-sc17gt.herokuapp.com/lecture-check/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token " + self.key, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion(teacher: self.teacherEmail), beaconConstraint: self.getBeaconIdentityConstraint())
                self.failed(error: "Error in app side (When checking lecture details)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion(teacher: self.teacherEmail), beaconConstraint: self.getBeaconIdentityConstraint())
                self.failed(error: "Error in server side (When checking lecture details)")
                return
            }
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data{
                    self.getLectureID(data: data)
                    let userAttend = UserAttend(username:self.userID, lecture_id: self.lecture_id)
                    print(userAttend)
                    
                    guard let uploadData = try? JSONEncoder().encode(userAttend)else{
                        return
                    }
                self.userAttend(uploadData: uploadData)
            
            }
        }
        task.resume()
    }
    
    func getLectureID(data: Data){ //This takes in some data and then proceeds to obtain the pk field of the lecture, which is then made equal to the lecture_id instance variable
        if let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments){
        if let jsonArray = jsonObj as? NSArray{
            for obj in jsonArray{
                if let objDict = obj as? NSDictionary{
                    if let lecture_id = objDict.value(forKey: "pk"){
                    self.lecture_id = lecture_id as! Int
                    }
                }
            }
    }
        }
    }
    
    func userAttend(uploadData: Data){ //This function takes in some data and then proceeds to try and create a LectureSession on the API with the passed in info. If it works correctly the scanning for beacon region is turned off and the login splash screen is popped up showing the user has logged in
        let url = URL(string: "https://project-api-sc17gt.herokuapp.com/user-attend/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token " + self.key, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                //self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion(teacher: self.teacherEmail), beaconConstraint: self.getBeaconIdentityConstraint())
                self.failed(error: "Error in app side (When checking user attendance)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                print ("server error")
                //self.stopScanningForBeaconRegion(beaconRegion: self.getBeaconRegion(teacher: self.teacherEmail), beaconConstraint: self.getBeaconIdentityConstraint())
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
    
    func getBeaconRegion(teacher: String) -> CLBeaconRegion { //This function is used to get the beacon region from the uuid and identifer which is the teachers email
        let uuid = UUID(uuidString: "E06F95E4-FCFC-42C6-B4F8-F6BAE87EA1A0")
        let beaconRegion = CLBeaconRegion.init(uuid: uuid!, identifier: teacher)
        return beaconRegion
    }
    
    func getBeaconIdentityConstraint() -> CLBeaconIdentityConstraint { //This function returns the beacon constraint made with the uuid
        let uuid = UUID(uuidString: "E06F95E4-FCFC-42C6-B4F8-F6BAE87EA1A0")
        let beaconIdentityConstraint = CLBeaconIdentityConstraint.init(uuid: uuid!)
        return beaconIdentityConstraint
    }
    
    func startScanningForBeaconRegion(beaconRegion: CLBeaconRegion, beaconConstraint: CLBeaconIdentityConstraint) { //This function allows for the scanning of a beacon region making use of that and its constraint, here it mointors the beacon region and start ranging beacons that match the constraint set
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(satisfying: beaconConstraint)
    }
    
    func stopScanningForBeaconRegion(beaconRegion: CLBeaconRegion, beaconConstraint: CLBeaconIdentityConstraint){ //This function is the opposite of the previous stopping the scanning of a beacon region, here it ends the monitoring of the beacon region and stops ranging the beacons that match the constraint
        locationManager.stopMonitoring(for: beaconRegion)
        locationManager.stopRangingBeacons(satisfying: beaconConstraint)
    }
        

    override func viewDidLoad() { //Upon loading the view the user's details are retrieved
        super.viewDidLoad()
        self.getUser()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func searchButton(_ sender: Any) { //This button allows for the program to begin searching for the beacons that match the entered information, it begins by retrieveing and then checking the teacher's email to see if its valid, if it is then the Location Manager is initalised, followed by the setting of delegates and authorization for this view. Once done the startScanningForBeaconRegion is called starting the search with the entered infromation
        self.teacherEmail = teacherEmailTextBox.text!
        self.failed(error: "Began searching for teacher with email \(self.teacherEmail)")
        if self.teacherEmail == "" {
            self.failed(error: "You didnt enter a teacher's email correctly, for connection please enter the email of your teacher")
        }else{
            locationManager = CLLocationManager.init()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            startScanningForBeaconRegion(beaconRegion: getBeaconRegion(teacher: self.teacherEmail), beaconConstraint: getBeaconIdentityConstraint())
            
        }
    }
    
}
