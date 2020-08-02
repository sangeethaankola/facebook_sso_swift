//
//  LoginViewController.swift
//  GlucoseReading
//
//  Created by Sangeetha Ankola on 3/2/16.
//  Copyright © 2016 Sangeetha Ankola. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseDatabase
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController {
    
    let firebase = DataService.ds?.REF_BASE
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        let tap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.DismissKeyboard))
        self.view.addGestureRecognizer(tap)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If a firebase auth key id is saved on a device then launch the app without asking to sign in
        
        if UserDefaults.standard.value(forKey: KEY_UID) != nil {
            self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func fbBtnPressed(_ sender: UIButton!){
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logIn(withReadPermissions: ["email"]) { (facebookResult: FBSDKLoginManagerLoginResult?, facebookError: Error?) -> Void in
            
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError) ")
            } else if (facebookResult?.isCancelled)! {
                print("Facebook login was cancelled.")
            } else {
                let accessToken = FBSDKAccessToken.current().tokenString
                print("Successfully logged in with facebook \(accessToken)")
                
                // saving firebase id for the user
               let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
                    if let error = error {
                         print("Login failed! \(error)")
                    }
                    else{
                        print("Logged in!")
                        
                        UserDefaults.standard.setValue(authResult?.user.uid, forKey : KEY_UID)
                        
                        // let user = ["provider": authData.provider!, "check" : "test"]
                        DataService.ds?.createFirebaseUser((authResult?.user.uid)!)
                        self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func attemptToLogin(_ sender: UIButton!) {
        
        if let email = emailField.text, email != "", let password = passwordField.text, password != "" {
            
            Auth.auth().signIn(withEmail: email, password: password, completion: { authData, error  in
                
                // If error happened
                if error != nil {
                    self.showErrorAlert("Enter a valid email and password", msg: "")
                }
                else {
                    UserDefaults.standard.setValue(authData?.user.uid, forKey : KEY_UID)
                    self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                }
            })
            
        } else {
            showErrorAlert("Email and Password required!", msg: "You must enter the email and password")
        }
        
    }
    
    
       @IBAction func skipLogin(_ sender: UIButton!) {
        Auth.auth().signInAnonymously()  { (authData, error) in
            if error != nil {
                self.showErrorAlert("There was a problem accessing the system. Please try again later", msg: "")
                
            } else {
                
                UserDefaults.standard.setValue(authData?.user.uid, forKey : KEY_UID)
                
                //Checking if the user is created in firebase for provider email/login
                DataService.ds?.createFirebaseUser((authData?.user.uid)!)
                
                self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                
            }
           
            
        }
        
    }
    
   
    func showErrorAlert(_ title: String, msg: String){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func DismissKeyboard(){
        self.view.endEditing(true)
    }
    
    
}

