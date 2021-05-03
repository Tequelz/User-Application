import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var buttonLog: UIButton!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        password.isSecureTextEntry = true
    }
    
    func failed(error: String) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title:error, message: nil,preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(ac,animated: true)
        }
    }
    
    @IBAction func loginButton(_ sender: Any) {
//                let user = username.text
//                let mail = email.text
//                let pass = password.text
                let user = "sc17gt"
                let mail = "sc17gt@leeds.ac.uk"
                let pass = "user1@123"
//        
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
                        self.failed(error: "Error in application side (Try reload app)")
                        return
                    }
                    guard let response = response as? HTTPURLResponse,
                        (200...299).contains(response.statusCode) else {
                        print ("server error")
                        self.failed(error: "Error in server side (Please check login details)")
                        return
                    }
                    if let mimeType = response.mimeType,
                        mimeType == "application/json",
                        let data = data,
                        let dataString = String(data: data, encoding: .utf8) {
                        print ("got data: \(dataString)")
                        DispatchQueue.main.async {
                            let story = UIStoryboard(name: "Main",bundle:nil)
                            let controller = story.instantiateViewController(identifier: "TechChoice") as! TechChoiceViewController
                                controller.key = dataString
                                controller.modalPresentationStyle = .fullScreen
                                controller.modalTransitionStyle = .crossDissolve
                                self.present(controller, animated: true, completion: nil)
                        }
                    }
                }
                task.resume()
            }
        }


