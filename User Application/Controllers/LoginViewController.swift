import UIKit

class LoginViewController: UIViewController { //This class is used to take in the users login information and then log them in providing them with a Token
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField! //Three outlets that allow the data entered in the text fields to be retrieved from the storyboard

    func popUp(error: String) { // This function is used to produce a pop up that lets the user know about an error
        DispatchQueue.main.async {
            let ac = UIAlertController(title:error, message: nil,preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(ac,animated: true)
        }
    }
    
    func loginAPI(uploadData: Data){ //This function takes in some data and attempts to log a user in, if works correctly the user's token is found and then the next TechChoice view is loaded passing along the value of token
        let url = URL(string: "https://project-api-sc17gt.herokuapp.com/rest-auth/login/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                self.popUp(error: "Error in app side (When getting logging in) Error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                self.popUp(error: "Error in server side (When getting logging in)")
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
    
    override func viewDidLoad() {//This function just sets the password field to be blacked out
        super.viewDidLoad()
        password.isSecureTextEntry = true
    }
    
    @IBAction func loginButton(_ sender: Any) { // This function allows the user to login by getting the information entred within the text fields and then packaging this into a Login instance with this data being encoded and then sent via the loginAPI function
        let user = username.text!
                let mail = email.text
                let pass = password.text


        let login = Login(username: user, email : mail!, password : pass!)
        guard let uploadData = try? JSONEncoder().encode(login) else {
            return
        }
        self.loginAPI(uploadData: uploadData)
    }

}


