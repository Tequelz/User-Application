//
//  LoginViewController.swift
//  Login Page
//
//

import UIKit

struct Login: Codable {
    let username: String
    let email: String
    let password:String
}

struct Key: Decodable{
    let key:String
}

class LoginViewController: UIViewController {
    
    @IBOutlet weak var buttonLog: UIButton!
    @IBOutlet weak var username: UITextField!
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonLog.addTarget(self, action: #selector(tapButton), for: .touchUpInside)

        // Do any additional setup after loading the view.
    }
    
    @objc func tapButton(_ sender: Any) {
//        let user = username.text
//        let mail = email.text
//        let pass = password.text
        let user = "sc17gt"
        let mail = "sc17gt@leeds.ac.uk"
        let pass = "hellothere123"
        let login = Login(username: user, email : mail, password : pass)
        guard let uploadData = try? JSONEncoder().encode(login) else {
            return
        }
        
        let url = URL(string: "https://project-api-sc17gt.herokuapp.com/rest-auth/login/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
                
                let story = UIStoryboard(name: "Main",bundle:nil)
                let controller = story.instantiateViewController(identifier: "ManualCodeViewController") as! ManualCodeViewController
                    controller.key = dataString
                let navigation = UINavigationController(rootViewController: controller)
                self.view.addSubview(navigation.view)
                self.addChild(navigation)
                navigation.didMove(toParent: self)
                }
            }
        }
        task.resume()

        
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
