import UIKit

class TechChoiceViewController: UIViewController {//Class that is used for the user to choose a technology for the tracking of attendance
    
    var key:String = ""//This instance variable is used to take in values from the previous controller
    
    @IBAction func btLoadButton(_ sender: Any) {//This function handles the Bluetooth button being clicked with the data being passed along into the BTShow view
        DispatchQueue.main.async {
            let story = UIStoryboard(name: "Main",bundle:nil)
            let controller = story.instantiateViewController(identifier: "BTShow") as! BTShowViewController
                controller.key = self.key
                controller.modalPresentationStyle = .fullScreen
                controller.modalTransitionStyle = .crossDissolve
                self.present(controller, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func qrLoadButton(_ sender: Any) {//This function handles the QR button being clicked with the data being passed along into the ScanQR view
        DispatchQueue.main.async {
            let story = UIStoryboard(name: "Main",bundle:nil)
            let controller = story.instantiateViewController(identifier: "ScanQR") as! ScanQRViewController
                controller.key = self.key
                controller.modalPresentationStyle = .fullScreen
                controller.modalTransitionStyle = .crossDissolve
                self.present(controller, animated: true, completion: nil)
        }
    }
    
}
