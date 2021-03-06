//
//  OTPViewController.swift
//  keats
//
//  Created by Swamita on 04/04/21.
//

import UIKit
import Firebase

class OTPViewController: UIViewController {
    
    @IBOutlet weak var otpContainerView: UIView!
    @IBOutlet weak var testButton: UIButton!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let otpStackView = OTPStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loggedIn = UserDefaults.standard.bool(forKey: "LoggedIn")
        if loggedIn {
            performSegue(withIdentifier: "otpToHome", sender: self)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        buttonView.isHidden = true
        activityIndicator.isHidden = true
        otpContainerView.addSubview(otpStackView)
        otpStackView.delegate = self
        otpStackView.heightAnchor.constraint(equalTo: otpContainerView.heightAnchor).isActive = true
        otpStackView.centerXAnchor.constraint(equalTo: otpContainerView.centerXAnchor).isActive = true
        otpStackView.centerYAnchor.constraint(equalTo: otpContainerView.centerYAnchor).isActive = true
        
    }
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func clickedForHighlight(_ sender: UIButton) {
        
        buttonView.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
           
        let verificationCode = otpStackView.getOTP()
        if let verificationID = UserDefaults.standard.string(forKey: "VerificationID") {

                let credential = PhoneAuthProvider.provider().credential(
                    withVerificationID: verificationID,
                    verificationCode: verificationCode)

                Auth.auth().signIn(with: credential) { (authResult, error) in
                  if let error = error {
                    let authError = error as NSError
                    self.buttonView.isHidden = false
                    self.activityIndicator.isHidden = true
                    self.activityIndicator.stopAnimating()
                    self.alert(message: "Check the OTP and try again.", title: "Error")
                    print(authError.localizedDescription)
                  } else {
                    let currentUser = Auth.auth().currentUser
                    currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
                      if let error = error {
                        self.buttonView.isHidden = false
                        self.activityIndicator.isHidden = true
                        self.activityIndicator.stopAnimating()
                        self.alert(message: "Sign in unsuccessful. Please try again", title: "Error")
                        print("error in getting id token: \(error.localizedDescription)")
                        return;
                        
                      } else {
                        if let token = idToken {
                            UserDefaults.standard.set(token, forKey: "IDToken")
                            self.signInUser(verificationId: token)
                            
                        }
                      }
                    }
                    
                  }
                    
                    
                }
            }
       }
    
    //MARK: - Sign In User
    
    func signInUser(verificationId: String) {
        
        // prepare json data
        let json: [String: Any] = ["id_token": verificationId]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // create post request
        guard let url = URL(string: "https://keats-testing.herokuapp.com/api/user") else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // insert json data to the request
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                
                let status = responseJSON["status"]
                if status as! String != "error" {
                    let data = responseJSON["data"]
                    if let data = data as? [String: Any] {
                        guard let JWToken = data["token"] else {return}
                        //print("otp jwtoken: \(JWToken)")
                        UserDefaults.standard.set(JWToken, forKey: "JWToken")
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "otpToHome", sender: self)
                            self.buttonView.isHidden = false
                            self.activityIndicator.isHidden = true
                            self.activityIndicator.stopAnimating()
                            print("Successfully signed in!")
                            UserDefaults.standard.set(true, forKey: "LoggedIn")
                        }
                    }
                    
                }
                else{
                    DispatchQueue.main.async {
                        self.alert(message: "Can't sign in, please try again!", title: "Error")
                    }
                }
                //print(responseJSON)
            }
        }

        task.resume()
    
    }
}

extension OTPViewController: OTPDelegate {
    
    func didChangeValidity(isValid: Bool) {
        buttonView.isHidden = !isValid
    }
    
}
