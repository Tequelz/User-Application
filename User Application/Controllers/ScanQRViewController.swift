import UIKit
import AVFoundation //Class begins by importing the AVFoundation framework allowing the methods within to be used

class ScanQRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate { //This class will provide the user with a scanner that can take in and decipher QR code information and then generate a LectureSession request for logging in
    
//    @IBOutlet weak var cameraContainerConstraint: NSLayoutConstraint!
    
    var key:String = "" //The token is passed through from the previous controller
    var lecture_id:Int = 0
    var userID:Int = 0//These two values will be used to create the LectureSession request in the class
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer? //These are two core variables that are needed to create the scanner, the capture session allows for the management of what happens with the camera, and the preview layer allows the user to visually see this camera

    
    func popUp(error: String) {// This function is used to produce a pop up that lets the user know about an error
        DispatchQueue.main.async {
            let ac = UIAlertController(title:error, message: nil,preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(ac,animated: true)
        }
    }
    
    func getUserID(){ //This function retrieves the users details via a request to the rest-auth/user path, here the data returned can provide the current users infromation which is required to make a LectureSession, this data is passed in to getUserPK so the primary key can be obtained
        let url = URL(string: "https://project-api-sc17gt.herokuapp.com/rest-auth/user/")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token " + self.key, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.popUp(error: "Error in app side (When getting user details) Error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                self.popUp(error: "Error in server side (When getting user details)")
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
    
    func getUserPK(data:Data){ //This function takes in some data which is then converted into a JSONObject, this object is then made into an NSDictionary which means the pk value can be found and the instance variable userID can be set
        if let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments){
            if let jsonArray = jsonObj as? NSDictionary{
                let userID = jsonArray.value(forKey: "pk")
                self.userID = userID as! Int
            }
        }
    }
    
    func cameraCheck(){ //This function does the checks required to make sure that the camera can be initalised and displayed on the screen, with the setupCaptureSession being called if possible
        self.view.backgroundColor = UIColor.black
        
        switch AVCaptureDevice.authorizationStatus(for: .video){
            case .authorized:
                self.setupCaptureSession()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video){ granted in
                if granted{
                    self.setupCaptureSession()
                }
            }
            
        case .denied:
            return
            
        case .restricted:
            return
        }
    }
    
    func setupCaptureSession(){ //This function creates the capture session as well as the output and input which it then links all together allowing the session to manage the innner workings. The input is an AVCaptureDeviceInput instance and provides the input image for the session, and the output is a AVCaptureMetadataOutput allowing the data to be obtained from the image and converted into a qr. If worked correctly the previewLayer is set to show the capture session with this taking up the whole screen, finally the capture session is then set to running
        self.captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,for:.video,position: .back)else {return}
        let videoInput:AVCaptureDeviceInput
        
        do{
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        }catch{
            return
        }
        if (self.captureSession.canAddInput(videoInput)){
            self.captureSession.addInput(videoInput)
        }else{
            self.popUp(error: "Scan Failed")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (self.captureSession.canAddOutput(metadataOutput)){
            self.captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        }else{
            self.popUp(error: "Scan Failed")
            return
        }
        DispatchQueue.main.async {
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.previewLayer?.frame = self.view.layer.bounds
            self.previewLayer?.videoGravity = .resizeAspectFill
            self.view.layer.addSublayer(self.previewLayer!)
            self.captureSession.startRunning()
        }
        
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) { //This function manages what happens when the output is given some data, the first is stopping the capture session meaning no more data can be retrieved from the camera. After this the data is converted into a readable metadata object and then to a string representation that is passed into lecture check as data
        captureSession.stopRunning()
    
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {return}
            guard let stringValue = readableObject.stringValue else {return}
            
            let qrData = stringValue.data(using: .utf8)!
            self.lectureCheck(uploadData: qrData)
        }
    }
    
    func lectureCheck(uploadData: Data){ //This function takes in some data and finds the corresponding lectyure that matches the entered informqation. Once complete a UserAttend instance is made containing the lectures id and the user id. Here the data is then encoded and passed into the lectureAttend function
        let url = URL(string: "https://project-api-sc17gt.herokuapp.com/lecture-check/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token " + self.key, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                self.popUp(error: "Error in app side (When checking lecture details)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                self.popUp(error: "Error in server side (When checking lecture details)")
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
                
                self.lectureAttend(uploadData: uploadData)
            }
        }
        task.resume()
    }
    
    func getLectureID(data: Data){ //This function takes in some data and then proceeds to convert the data into a dictionary which allows for the lectures primary key to be retrieved for use in the tracking of attendance
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
    
    func lectureAttend(uploadData: Data){ //This function creates the request that logs the user in, taking data from the lectureCheck function and sending it to the user-attend path, if the correct information is returned the LoggedIn splash screen appears as the user is now logged in
        let url = URL(string: "https://project-api-sc17gt.herokuapp.com/user-attend/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token " + self.key, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                self.popUp(error: "Error in app side (When trying to add user to lecture session)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                self.popUp(error: "Error in server side (When trying to add user to lecture session)")
                return
            }
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data{
                
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
 
    override func viewDidLoad() { //When the view is loaded the userID is retrieved using the getUserID function and the camera is checked to see whether it is functional
        super.viewDidLoad()
        self.getUserID()
        self.cameraCheck()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle{
//        return UIStatusBarStyle.lightContent
//    }
    
}

