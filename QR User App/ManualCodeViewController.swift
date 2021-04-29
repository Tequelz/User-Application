//
//  ManualCodeViewController.swift
//  Login Page
//
//

import UIKit
import AVFoundation

struct AuthKey: Decodable {
    enum Category: String, Decodable {
        case swift, combine, debugging, xcode
    }

    let key: String
    
}

struct UserAttend: Codable{
    
    let username: Int
    let lesson_id: Int
}


class ManualCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    

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
    
    var lessonID:Int = 0
    
    var userID:Int = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let jsonData = key.data(using: .utf8)!
        let authKey: AuthKey = try! JSONDecoder().decode(AuthKey.self, from: jsonData)

        print(authKey.key)
        
        
        
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
                    print(userID)
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

        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func failed() {
        let ac = UIAlertController(title:"Scan Failed", message: nil,preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
        present(ac,animated: true)
        self.captureSession = nil
    }
    
    
    func successfulLogin(){
        let ac = UIAlertController(title: "LOGGED IN SUCCESSFULLY", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Close APP", style: .default))
        present(ac,animated: true)
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
            self.failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (self.captureSession.canAddOutput(metadataOutput)){
            self.captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        }else{
            self.failed()
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
    
    func showQRCodeBounds(frame: CGRect?){
        guard let frame = frame else{
            return
        }
        
        self.qrCodeBounds.layer.removeAllAnimations()
        self.qrCodeBounds.alpha = 1
        self.qrCodeBounds.frame = frame
        UIView.animate(withDuration:0.2,delay: 1,options: [],animations: {
            self.qrCodeBounds.alpha = 0
        })
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        let jsonData = key.data(using: .utf8)!
        let authKey: AuthKey = try! JSONDecoder().decode(AuthKey.self, from: jsonData)
        
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {return}
            guard let stringValue = readableObject.stringValue else {return}
            
            if stringValue != lowerBanner.text {
                print("QR Code: \(stringValue)")
                self.lowerBanner.text = stringValue
            }
            
            
            let qrCodeObject = self.previewLayer?.transformedMetadataObject(for: readableObject)
            self.showQRCodeBounds(frame: qrCodeObject?.bounds)
            
            
            lessonID = Int(stringValue)!
            
            print(lessonID)
            
            let userAttend = UserAttend(username:self.userID, lesson_id: lessonID)
            
            guard let uploadData = try? JSONEncoder().encode(userAttend)else{
                return
            }
            
            let url = URL(string: "https://project-api-sc17gt.herokuapp.com/user-attend/")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Token " + authKey.key, forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
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
                    let dataString = String(data: data, encoding: .utf8) {
                    print ("got data: \(dataString)")
                    DispatchQueue.main.async {
                        self.successfulLogin()
                        let story = UIStoryboard(name: "Main",bundle:nil)
                        let controller = story.instantiateViewController(identifier: "LoggedIn") as! UIViewController
                        let navigation = UINavigationController(rootViewController: controller)
                        self.view.addSubview(navigation.view)
                        self.addChild(navigation)
                        navigation.didMove(toParent: self)
                    }
                }
            }
            task.resume()
        }
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

