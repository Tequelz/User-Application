import UIKit

struct Login: Codable {
    
    let username: String
    let email: String
    let password:String
    
}
struct Register: Codable{
    let username: String
    let email: String
    let password1: String
    let password2: String
}
struct AuthKey: Decodable {

    let key: String
    
}
struct LectureData: Codable{
    
    let lec_id: Int
    let lec_number: Int
    let lec_length:Int
    
}
struct UserAttend: Codable{
    
    let username: Int
    let lecture_id: Int
    
}

class ViewController: UIViewController {

    @IBAction func loginButton(_ sender: Any) {
        DispatchQueue.main.async {
            let story = UIStoryboard(name: "Main",bundle:nil)
            let controller = story.instantiateViewController(identifier: "Login") as! LoginViewController
                controller.modalPresentationStyle = .fullScreen
                controller.modalTransitionStyle = .crossDissolve
                self.present(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func registerButton(_ sender: Any) {
        DispatchQueue.main.async {
            let story = UIStoryboard(name: "Main",bundle:nil)
            let controller = story.instantiateViewController(identifier: "Register") as! RegisterViewController
                controller.modalPresentationStyle = .fullScreen
                controller.modalTransitionStyle = .crossDissolve
                self.present(controller, animated: true, completion: nil)
        }
    }

}



