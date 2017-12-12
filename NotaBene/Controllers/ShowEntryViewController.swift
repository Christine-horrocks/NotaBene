//
//  ShowEntryViewController.swift
//  NotaBene
//
//  Created by Olivia Beresford on 07/12/2017.
//  Copyright © 2017 NotaBeneTeam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import UserNotifications
import FirebaseStorage

class ShowEntryViewController: UIViewController {
    
    var entry: EntryModel?
    var entriesList = [EntryModel]()
    var refEntries = Database.database().reference().child("entries")
//    var ref = Database.database().reference()
    
    @IBOutlet weak var entryContentEditable: UITextView!
    @IBOutlet weak var entryTitleEditable: UITextField!
    @IBOutlet weak var entryImageEditable: UIImageView!
    
    @IBAction func deleteButton(_ sender: Any) {
        self.deleteEntry(id: (entry?.id!)!)
    }
    
    func deleteEntry(id: String) {
        let dbref = Database.database().reference().child("users")
        let user = Auth.auth().currentUser
        if let uid = user?.uid {
            dbref.child("\(uid)").child("entries").child(id).setValue(nil)
        }
    }
    
    @IBAction func saveChanges(_ sender: Any) {
        let id = entry?.id
        self.updateEntry(id: id!, entryTitle: entryTitleEditable.text!, entryContent: entryContentEditable.text!)
        print("success")
        scheduleNotification()
        scheduleSecondNotification()
    }
    
    @IBAction func editText(_ sender: UIButton) {
        entryContentEditable.isEditable = true
    }
    
    
    func updateEntry(id: String, entryTitle: String, entryContent: String){
            let entry = [
                "id": id,
                "entryTitle": entryTitle,
                "entryContent": entryContent,
//                "image": image
            ]
        let dbref = Database.database().reference().child("users")
        let user = Auth.auth().currentUser
        if let uid = user?.uid {
            dbref.child("\(uid)").child("entries").child(id).setValue(entry)
        }
        
    }
    
    //first Notification
    var datePickerView:UIDatePicker = UIDatePicker()
    @IBOutlet weak var dateTextField: UITextField!
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    
    
    @IBAction func textFieldEditing(_ sender: UITextField) {
        datePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        sender.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(Entry.datePickerValueChanged), for: UIControlEvents.valueChanged)
    }
    
    @objc func datePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateTextField.text = dateFormatter.string(from: sender.date)
    }
    
    func scheduleNotification() {
        let key = entry?.entryTitle!
        let content = UNMutableNotificationContent() //The notification's content
        let datePicker = datePickerView
        
        content.title = "It is time to review " + entryTitleEditable.text!
        content.sound = UNNotificationSound.default()
        
        let dateComponent = datePicker.calendar.dateComponents([.day, .hour, .minute], from: datePicker.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: false)
        let notificationReq = UNNotificationRequest(identifier: key!, content: content, trigger: trigger)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [key!])
        UNUserNotificationCenter.current().add(notificationReq, withCompletionHandler: nil)
    }
    
    
    @objc func donePressed(sender: UIBarButtonItem) {
        dateTextField.resignFirstResponder()
    }
    
    @objc func tappedToolBarBtn(sender: UIBarButtonItem) {
        let dateformatter = DateFormatter()
        dateformatter.dateStyle = DateFormatter.Style.medium
        dateformatter.timeStyle = DateFormatter.Style.short
        dateTextField.text = dateformatter.string(from: NSDate() as Date)
        dateTextField.resignFirstResponder()
    }
    
    func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    // ends first Notification
    
    //second Notification
    var secondDatePickerView:UIDatePicker = UIDatePicker()
    @IBOutlet weak var secondDateTextField: UITextField!
 
    @IBAction func secondTextFieldEditing(_ sender: UITextField) {
        secondDatePickerView.datePickerMode = UIDatePickerMode.dateAndTime
        sender.inputView = secondDatePickerView
        secondDatePickerView.addTarget(self, action: #selector(Entry.secondDatePickerValueChanged), for: UIControlEvents.valueChanged)
    }
    
    @objc func secondTappedToolBarBtn(sender: UIBarButtonItem) {
        let dateformatter = DateFormatter()
        dateformatter.dateStyle = DateFormatter.Style.medium
        dateformatter.timeStyle = DateFormatter.Style.short
        secondDateTextField.text = dateformatter.string(from: NSDate() as Date)
        secondDateTextField.resignFirstResponder()
    }
    
    @objc func secondDatePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.short
        secondDateTextField.text = dateFormatter.string(from: sender.date)
    }
    
    @objc func secondDonePressed(sender: UIBarButtonItem) {
        secondDateTextField.resignFirstResponder()
    }
    
    func scheduleSecondNotification() {
        let user = Auth.auth().currentUser
        let uid = user?.uid
        let refEntries = Database.database().reference().child("users").child("\(uid)").child("entries")
        let key = refEntries.childByAutoId().key
        let content = UNMutableNotificationContent() //The notification's content
        let datePicker = secondDatePickerView
        
        content.title = "Another reminder to review " + entryTitleEditable.text!
        content.sound = UNNotificationSound.default()
        
        let dateComponent = datePicker.calendar.dateComponents([.day, .hour, .minute], from: datePicker.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: false)
        let notificationReq = UNNotificationRequest(identifier: key, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(notificationReq, withCompletionHandler: nil)
    }
    //ends second Notification

    override func viewDidLoad() {
        super.viewDidLoad()
        entryTitleEditable.text = entry?.entryTitle
        entryContentEditable.text = entry?.entryContent
        
        
        let image = entry?.image
        let imageRef = Storage.storage().reference().child("images/" + image!)
        imageRef.getData(maxSize: 25 * 1024 * 1024, completion: { (data, error) -> Void in
            if error == nil {
                let image = UIImage(data: data!)
                self.entryImageEditable.image = image
            } else {
                //error
                print("error downloading image: \(error?.localizedDescription)")
            }
        })
        
        Database.database().reference().child("entries");
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {didAllow, error in})
        
//        refEntries = Database.database().reference().child("entries");
        let user = Auth.auth().currentUser
        let uid = user?.uid
        refEntries = Database.database().reference().child("users").child("\(uid)").child("entries")
        
        //toolbar1
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 40.0, width: self.view.frame.size.width, height: self.view.frame.size.height/6))
        toolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        toolBar.barStyle = UIBarStyle.blackTranslucent
        toolBar.tintColor = UIColor.white
        toolBar.backgroundColor = UIColor.white
        
        let okBarBtn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(Entry.donePressed))
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width / 3, height: self.view.frame.size.height))
        
        label.font = UIFont(name: "Helvetica", size: 20)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.text = "Set a Reminder Date"
        label.textAlignment = NSTextAlignment.center
        let textBtn = UIBarButtonItem(customView: label)
        toolBar.setItems([flexSpace,textBtn,flexSpace,okBarBtn], animated: true)
        dateTextField.inputAccessoryView = toolBar
        //end of toolbar 1
        
        //toolbar2
        let secondToolBar = UIToolbar(frame: CGRect(x: 0, y: 40.0, width: self.view.frame.size.width, height: self.view.frame.size.height/6))
        secondToolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
        secondToolBar.barStyle = UIBarStyle.blackTranslucent
        secondToolBar.tintColor = UIColor.white
        secondToolBar.backgroundColor = UIColor.white
        
        let secondOkBarBtn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(Entry.secondDonePressed))
        
        //        let secondFlexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        //
        let secondLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width / 3, height: self.view.frame.size.height))
        
        secondLabel.font = UIFont(name: "Helvetica", size: 20)
        secondLabel.backgroundColor = UIColor.clear
        secondLabel.textColor = UIColor.white
        secondLabel.text = "Set a Second Reminder Date"
        secondLabel.textAlignment = NSTextAlignment.center
        let secondTextBtn = UIBarButtonItem(customView: secondLabel)
        secondToolBar.setItems([flexSpace,secondTextBtn,flexSpace,secondOkBarBtn], animated: true)
        secondDateTextField.inputAccessoryView = secondToolBar
        //end of toolbar 2
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
