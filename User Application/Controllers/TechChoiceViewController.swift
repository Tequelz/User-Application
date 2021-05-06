import UIKit

class TechChoiceViewController: UIViewController {
    
    var key:String = ""
    
    @IBAction func btLoadButton(_ sender: Any) {
        DispatchQueue.main.async {
            let story = UIStoryboard(name: "Main",bundle:nil)
            let controller = story.instantiateViewController(identifier: "BTShow") as! BTShowViewController
                controller.key = self.key
                controller.modalPresentationStyle = .fullScreen
                controller.modalTransitionStyle = .crossDissolve
                self.present(controller, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func qrLoadButton(_ sender: Any) {
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
