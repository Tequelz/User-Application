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

struct PostView: Decodable {
    enum Category: String, Decodable {
        case swift, combine, debugging, xcode
    }
    
    let title: String
    let description: String
    let owner: String
}

class ManualCodeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    

    
    
    @IBOutlet weak var tableView: UITableView!
    
    var key:String = ""

    @IBOutlet weak var label: UILabel!
    
    var titleArray = [String]()
    var descriptionArray = [String]()
    var ownerArray = [String]()
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "MyCell")! as! MyCellTableViewCell
        cell.titleLabel.text = self.titleArray[indexPath.row]
        cell.descriptionLabel.text = self.descriptionArray[indexPath.row]
        cell.ownerLabel.text = self.ownerArray[indexPath.row]
        
        return cell
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let jsonData = key.data(using: .utf8)!
        let authKey: AuthKey = try! JSONDecoder().decode(AuthKey.self, from: jsonData)

        print(authKey.key)
        
        label.text = authKey.key
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        
        
        let url = URL(string: "https://project-api-sc17gt.herokuapp.com/?format=json")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token " + authKey.key, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
                let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments){
                if let jsonArray = jsonObj as? NSArray{
                    for obj in jsonArray{
                        print(obj)
                        if let objDict = obj as? NSDictionary{
                            if let name = objDict.value(forKey: "title"){
                                self.titleArray.append(name as! String)
                                print(name)
                            }
                            if let name = objDict.value(forKey: "description"){
                                self.descriptionArray.append(name as! String)
                                print(name)
                            }
                            if let name = objDict.value(forKey: "owner"){
                                self.ownerArray.append(String(name as! Int))
                                print(name)
                            }
                
                            OperationQueue.main.addOperation( {
                                self.tableView.reloadData()
                            })
                
                        }
                    }
                }
            }
        }
            
        task.resume()

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

