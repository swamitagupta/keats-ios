//
//  ProfileViewController.swift
//  keats
//
//  Created by Swamita on 06/04/21.
//

import UIKit
import FirebaseStorage

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var bioTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var editToggleButton: UIButton!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var uploadImageButtonView: UIView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var profilePicView: UIView!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var logOutView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private let storage = Storage.storage().reference()

    var isEditingProfile = false
    var previousPhone = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        infoView.isHidden = true
        profilePicView.isHidden = true
        uploadImageButtonView.isHidden = true
        
        profileImage.image = myProfileImage
        makeNonEditable()
        fetchUserDetails()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //MARK: - UI Buttons tapped
    
    @IBAction func editButtonTapped(_ sender: Any) {
        if isEditingProfile {
            makeNonEditable()
            disableViews()
            updateUserInfo(imageUrl: "")
            
        } else {
            makeEditable()
        }
    }
    
    @IBAction func logOutTapped(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
        deleteUserData()
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func updateImageTapped(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    func disableViews() {
        uploadImageButtonView.isUserInteractionEnabled = false
        infoView.isUserInteractionEnabled = false
        logOutView.isUserInteractionEnabled = false
        uploadImageButtonView.alpha = 0.5
        infoView.alpha = 0.5
        logOutView.alpha = 0.5
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func enableViews() {
            uploadImageButtonView.isUserInteractionEnabled = true
            infoView.isUserInteractionEnabled = true
            logOutView.isUserInteractionEnabled = true
            uploadImageButtonView.alpha = 1
            infoView.alpha = 1
            logOutView.alpha = 1
        activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
    }
    
    //MARK: - Image picker controller methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        profileImage.image = image
        myProfileImage = image
        
        guard let imageData = image.pngData() else {
            return
        }
        
        let identifier = UUID()
        let path = "public/\(identifier).png"
        //print(path)
        
        let uploadTask = storage.child(path).putData(imageData, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                print("Uh-oh, an error occurred!")
                return
            }
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
            // You can also access to download URL after upload.
            self.storage.child(path).downloadURL { (url, error) in
                guard let downloadURL = url else {
                    print("Uh-oh, an error occurred! 2")
                    return
                }
                //print(downloadURL.absoluteString)
                let imageLink = downloadURL.absoluteString
                //self.updateProfilePic(downloadUrl: imageLink)
                self.disableViews()
                self.updateUserInfo(imageUrl: imageLink)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Info Change UI
    
    func makeEditable() {
        isEditingProfile = true
        editToggleButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        
        nameTextField.isUserInteractionEnabled = true
        nameTextField.borderStyle = .roundedRect
        nameTextField.backgroundColor = UIColor(named: "TextFieldBg")
        
        bioTextField.isUserInteractionEnabled = true
        bioTextField.borderStyle = .roundedRect
        bioTextField.backgroundColor = UIColor(named: "TextFieldBg")
        
        emailTextField.isUserInteractionEnabled = true
        emailTextField.borderStyle = .roundedRect
        emailTextField.backgroundColor = UIColor(named: "TextFieldBg")
        
        phoneTextField.isUserInteractionEnabled = false
        phoneTextField.borderStyle = .none
        phoneTextField.backgroundColor = .clear
    }
    
    func makeNonEditable() {
        isEditingProfile = false
        editToggleButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        
        nameTextField.isUserInteractionEnabled = false
        nameTextField.borderStyle = .none
        nameTextField.backgroundColor = .clear
        
        bioTextField.isUserInteractionEnabled = false
        bioTextField.borderStyle = .none
        bioTextField.backgroundColor = .clear
        
        emailTextField.isUserInteractionEnabled = false
        emailTextField.borderStyle = .none
        emailTextField.backgroundColor = .clear
        
        phoneTextField.isUserInteractionEnabled = false
        phoneTextField.borderStyle = .none
        phoneTextField.backgroundColor = .clear
    }
    
    private func loadImage(url: URL, completion: @escaping (UIImage?) -> ()) {
        //utilityQueue.async {
        guard let data = try? Data(contentsOf: url) else { return }
        let image = UIImage(data: data)
        
        DispatchQueue.main.async {
            completion(image)
        }
        
    }
    
    //MARK: - Fetch User Details
    
    func fetchUserDetails() {
        if let bio = UserDefaults.standard.string(forKey: "bio"), let em = UserDefaults.standard.string(forKey: "email"), let un = UserDefaults.standard.string(forKey: "username"), let ph = UserDefaults.standard.string(forKey: "phone_number"), let profile_pic = UserDefaults.standard.string(forKey: "profile_pic") {
            
            guard let url = URL(string: profile_pic) else {return}
            
            DispatchQueue.global().async {
                guard let data = try? Data(contentsOf: url) else {return }
                guard let img = UIImage(data: data) else {return }
                DispatchQueue.main.async {
                    self.profileImage.image = img
                }
            }
            
            DispatchQueue.main.async {
                self.bioTextField.text = bio
                self.emailTextField.text = em
                self.nameTextField.text = un
                self.phoneTextField.text = ph
                self.showStuff()
            }
        }
        
        else {
            
            let url = URL(string: "https://keats-testing.herokuapp.com/api/user")
            guard let requestUrl = url else { return }
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "GET"
            
            guard let token = UserDefaults.standard.string(forKey: "JWToken") else {return}
            
            request.setValue( "Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    return
                }
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    print(responseJSON)
                    let status = responseJSON["status"]
                    if status as! String != "error" {
                        let userdata = responseJSON["data"]
                        if let userresponseJSON = userdata as? [String: Any] {
                            if let bio = userresponseJSON["bio"] as? String, let email = userresponseJSON["email"] as? String,
                               //let id = userresponseJSON["id"] as? String,
                               let phone = userresponseJSON["phone_number"] as? String, let profile_pic = userresponseJSON["profile_pic"] as? String, let username = userresponseJSON["username"] as? String{
                                
                                //print(id)
                                
                                guard let url = URL(string: profile_pic) else {
                                    print("error1")
                                    return}
                                print(url)
                                DispatchQueue.global().async {
                                    guard let data = try? Data(contentsOf: url) else {
                                        print("error2")
                                        return }
                                    guard let image = UIImage(data: data) else {
                                        print("error3")
                                        return }
                                    DispatchQueue.main.async {
                                        self.profileImage.image = image
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    self.bioTextField.text = bio
                                    self.emailTextField.text = email
                                    self.nameTextField.text = username
                                    self.phoneTextField.text = phone
                                    self.previousPhone = phone
                                    self.showStuff()
                                }
                            }
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    func showStuff() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        infoView.isHidden = false
        profilePicView.isHidden = false
        uploadImageButtonView.isHidden = false
    }
    
    //MARK: - Update User Info
    
    func updateUserInfo(imageUrl: String) {
        
        if let userName = nameTextField.text, let bio = bioTextField.text, let email = emailTextField.text {
            
            var json: [String: Any]
            
            if imageUrl == "" {
                json = ["username": userName,
                "email": email,
                "bio": bio]
            } else {
                json = ["username": userName,
                "email": email,
                "bio": bio,
                "profile_pic": imageUrl]
            }
            
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            guard let url = URL(string: "https://keats-testing.herokuapp.com/api/user") else {return}
            prepareRequest(method: "PATCH", url: url, jsonData: jsonData)
            enableViews()
        }
    }
    
    //MARK: - Delete User Data
    
    func deleteUserData() {
        myProfileImage =  UIImage(named: "default-profile")
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()

            dictionary.keys.forEach
            { key in   defaults.removeObject(forKey: key)
            }
        defaults.synchronize()

    }
    
}
