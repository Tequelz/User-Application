//
//  RegisterViewController.swift
//  Login Page
//
//

import UIKit

struct Register: Codable{
    let username: String
    let email: String
    let password1: String
    let password2: String
}

class RegisterViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var username: UITextField!
    
    @IBOutlet weak var email: UITextField!
    
    @IBOutlet weak var password1: UITextField!
    
    
    @IBOutlet weak var password2: UITextField!
    
    
    @IBAction func registerButton(_ sender: Any) {
        
        let user = username.text
        let mail = email.text
        let pw1 = password1.text
        let pw2 = password2.text
        let register = Register(username: user!, email: mail!, password1: pw1!, password2: pw2!)
        guard let uploadData = try? JSONEncoder().encode(register) else{
            return
        }
        let url = URL(string: "https://project-api-sc17gt.herokuapp.com/rest-auth/registration/")!
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
