//
//  ManualCodeViewController.swift
//  Login Page
//
//

import UIKit

struct AuthKey: Decodable {
    enum Category: String, Decodable {
        case swift, combine, debugging, xcode
    }

    let key: String
    
}

class ManualCodeViewController: UIViewController {
    
    var key:String = ""

    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let jsonData = key.data(using: .utf8)!
        let authKey: AuthKey = try! JSONDecoder().decode(AuthKey.self, from: jsonData)

        print(authKey.key)
        
        label.text = authKey.key

        // Do any additional setup after loading the view.
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
