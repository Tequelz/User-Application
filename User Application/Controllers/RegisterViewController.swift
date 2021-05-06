import UIKit

class RegisterViewController: UIViewController {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password1: UITextField!
    @IBOutlet weak var password2: UITextField!
    
    func failed(error: String) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title:error, message: nil,preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(ac,animated: true)
        }
    }
    
    func registerAPI(uploadData: Data){
        let url = URL(string: "https://project-api-sc17gt.herokuapp.com/rest-auth/registration/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                self.failed(error: "Error in application side (Try reload app) Error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                self.failed(error: "Error in server side (Please check register details)")
                return
            }
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data{
                
                let authKey: AuthKey = try! JSONDecoder().decode(AuthKey.self, from: data)
                
                DispatchQueue.main.async {
                    let story = UIStoryboard(name: "Main",bundle:nil)
                    let controller = story.instantiateViewController(identifier: "TechChoice") as! TechChoiceViewController
                        controller.key = authKey.key
                        controller.modalPresentationStyle = .fullScreen
                        controller.modalTransitionStyle = .crossDissolve
                        self.present(controller, animated: true, completion: nil)
                }
            }
        }
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        password1.isSecureTextEntry = true
        password2.isSecureTextEntry = true
    }
    
    @IBAction func registerButton(_ sender: Any) {
        
        let user = username.text
        let mail = email.text
        let pw1 = password1.text
        let pw2 = password2.text
        
        let register = Register(username: user!, email: mail!, password1: pw1!, password2: pw2!)
        guard let uploadData = try? JSONEncoder().encode(register) else{
            return
        }
        self.registerAPI(uploadData: uploadData)
    }
    
}
