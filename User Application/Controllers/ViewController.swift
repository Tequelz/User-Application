import UIKit

struct Login: Codable { //Structure used to package the users login details for sending via a request
    
    let username: String
    let email: String
    let password:String
    
}
struct Register: Codable{ //Structure used to package the users register information for sending via a request
    
    let username: String
    let email: String
    let password1: String
    let password2: String
    
}
struct AuthKey: Decodable { //Structure used to decode the users token when logged in

    let key: String
    
}
struct LectureData: Codable{ //Structure used to encode the LectureData for sending via a request
    
    let lec_id: Int
    let lec_number: Int
    let lec_length:Int
    
}
struct UserAttend: Codable{ //Structure used to create a lesson session object on the API
    
    let username: Int
    let lecture_id: Int
    
}

class ViewController: UIViewController { // View controller with two buttons available one for logging in and the other for registering within the application

    @IBAction func loginButton(_ sender: Any) { //Button takes the user to the Login view
        DispatchQueue.main.async {
            let story = UIStoryboard(name: "Main",bundle:nil)
            let controller = story.instantiateViewController(identifier: "Login") as! LoginViewController
                controller.modalPresentationStyle = .fullScreen
                controller.modalTransitionStyle = .crossDissolve
                self.present(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func registerButton(_ sender: Any) { //Button that loads the Register view for a user to login
        DispatchQueue.main.async {
            let story = UIStoryboard(name: "Main",bundle:nil)
            let controller = story.instantiateViewController(identifier: "Register") as! RegisterViewController
                controller.modalPresentationStyle = .fullScreen
                controller.modalTransitionStyle = .crossDissolve
                self.present(controller, animated: true, completion: nil)
        }
    }

}



