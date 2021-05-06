import UIKit
import AVFoundation

class ScanQRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet var headerBanner: UIView!
    @IBOutlet var lowerBanner: UILabel!

    
    @IBOutlet weak var cameraContainerConstraint: NSLayoutConstraint!
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeBounds: UIView = {
        let view = UIView(frame: CGRect(x:0,y:0,width:100,height:100))
        view.layer.borderColor = UIColor.green.cgColor
        view.layer.borderWidth = 3
        return view
    }()
    
    var key:String = ""
    var lecture_id:Int = 0
    var userID:Int = 0
    
    func failed(error: String) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title:error, message: nil,preferredStyle: .alert)
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
        task.resume()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    
    func setupCaptureSession(){
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
            self.failed(error: "Scan Failed")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (self.captureSession.canAddOutput(metadataOutput)){
            self.captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        }else{
            self.failed(error: "Scan Failed")
            return
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer?.frame = view.layer.bounds
        self.previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        self.qrCodeBounds.alpha = 0
        self.headerBanner.addSubview(self.qrCodeBounds)
        self.captureSession.startRunning()
        view.bringSubviewToFront(lowerBanner)
        view.bringSubviewToFront(headerBanner)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return UIStatusBarStyle.lightContent
    }
    

    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
    
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {return}
            guard let stringValue = readableObject.stringValue else {return}
            
            if stringValue != lowerBanner.text {
                print("QR Code: \(stringValue)")
                self.lowerBanner.text = stringValue
            }
            
            let jsonData = key.data(using: .utf8)!
            let authKey: AuthKey = try! JSONDecoder().decode(AuthKey.self, from: jsonData)

            let qrData = stringValue.data(using: .utf8)!
            let lecData: LectureData = try! JSONDecoder().decode(LectureData.self, from: qrData)
            print(lecData)
            
            guard let uploadData = try? JSONEncoder().encode(lecData)else{
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
                    self.failed(error: "Error in app side (When checking lecture details)")
                    return
                }
                guard let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) else {
                    print ("server error")
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
                                            self.failed(error: "Error in app side (When trying to add user to lecture session)")
                                            return
                                        }
                                        guard let response = response as? HTTPURLResponse,
                                            (200...299).contains(response.statusCode) else {
                                            print ("server error")
                                            self.failed(error: "Error in server side (When trying to add user to lecture session)")
                                            return
                                        }
                                        if let mimeType = response.mimeType,
                                            mimeType == "application/json",
                                            let data = data,
                                            let dataString = String(data: data, encoding: .utf8) {
                                            print ("got data: \(dataString)")
                                            
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
}

