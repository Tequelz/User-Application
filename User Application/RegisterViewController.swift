import UIKit

class RegisterViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
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
                DispatchQueue.main.async {
                    let story = UIStoryboard(name: "Main",bundle:nil)
                    let controller = story.instantiateViewController(identifier: "Core") as! ViewController
                        controller.modalPresentationStyle = .fullScreen
                        controller.modalTransitionStyle = .crossDissolve
                        self.present(controller, animated: true, completion: nil)
                }
            }
        }
        task.resume()
    }
}
