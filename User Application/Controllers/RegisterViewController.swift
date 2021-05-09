import UIKit

class RegisterViewController: UIViewController {//This class is used to take in the users register information and then create an account and then provide them with a Token

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password1: UITextField!
    @IBOutlet weak var password2: UITextField!//Four outlets that allow the data entered in the text fields to be retrieved from the storyboard
    
    func failed(error: String) {// This function is used to produce a pop up that lets the user know about an error
        DispatchQueue.main.async {
            let ac = UIAlertController(title:error, message: nil,preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(ac,animated: true)
        }
    }
    
    func registerAPI(uploadData: Data){ //This function takes in some data and attempts to register a user, if works correctly the user's token is found and then the next TechChoice view is loaded passing along the value of token
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
    
    override func viewDidLoad() {//This function just sets the two password fields to be blacked out
        super.viewDidLoad()
        password1.isSecureTextEntry = true
        password2.isSecureTextEntry = true
    }
    
    @IBAction func registerButton(_ sender: Any) { // This function allows the user to register by getting the information entred within the text fields and then packaging this into a Register instance with this data being encoded and then sent via the registerAPI function
        
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
