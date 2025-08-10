//
//  ViewController.swift
//  Bubble
//
//  Created by Shah Mirza on 12/19/19.
//  Copyright © 2019 Shah Mirza. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import Firebase
import GeoFire
import MessageUI

class ViewController: UIViewController, GMSMapViewDelegate, UITextFieldDelegate {

    let locationManager = CLLocationManager()
    var mapView:GMSMapView?
    var bubble:GMSCircle?
    var myLocationButton:UIButton!
    var bubbleChatMessagesFromDatabase:[BubbleChatMessageFromDatabase] = []
    var ref: DatabaseReference!
    var geoFireRef: GeoFire!
    var bubbleQuery: GFQuery?
    var bubbleCenter: CLLocation?
    var randomName : String?
    var bubbleChatMessageFromDatabase: BubbleChatMessageFromDatabase?
    var bubbleChatMessageToDatabase: BubbleChatMessageToDatabase?
    var chatTableView: UITableView?
    var userBubbleMessage: UITextField?
    var blockedUsers: [String] = []
    let defaults = UserDefaults.standard
    var settingsButton = UIButton()
    let zoomLevel:Float = 17.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        // Do any additional setup after loading the view.
        mapView = GMSMapView(frame: CGRect.zero)
        removeGMSBlockingGestureRecognizer()
        checkLocationServices()
        styleMap()
        mapView?.delegate = self
        self.view = mapView
        setupMyLocationButton()
        setupBubbleChatContainer()
        setupFirebaseAndGeoFire()
        generateRandomName()
        loadBlockedUsers()
//        let chatmessageone = BubbleChatMessageFromDatabase(name: "john", message: "hellooo this is a test to see if the text is getting clipped by the end of the view and if it is getting clipped by the cellhellooo this is a test to see if the text is getting clipped by the end of the view and if it is getting clipped by the cell")
//        let chatmessagetwo = BubbleChatMessageFromDatabase(name: "jack", message: "hellooo this is a test to see if the text is getting clipped by the end of the view and if it is getting clipped by the cell")
//        let chatmessagethree = BubbleChatMessageFromDatabase(name: "jill", message: "sup")
//        bubbleChatMessagesFromDatabase.append(chatmessageone)
//        bubbleChatMessagesFromDatabase.append(chatmessagetwo)
//        bubbleChatMessagesFromDatabase.append(chatmessagethree)

        
        
//        bubbleChatContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        bubbleChatContainerView.centerYAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//        bubbleChatContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
//        bubbleChatContainerView.heightAnchor.constraint(equalToConstant: 200).isActive = true
//        bubbleChatContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12).isActive = true
    }
    
    func loadBlockedUsers(){
        if(defaults.value(forKey: "blockedUsers") != nil){
            blockedUsers = defaults.value(forKey: "blockedUsers") as! [String]
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        displayEULA()
    }
    func displayEULA()
    {
        if(!isAppAlreadyLaunchedOnce())
        {
            let alert = UIAlertController(title: "EULA", message: EULA.agreement, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Agree", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    func generateRandomName()
    {
        if((defaults.value(forKey: "anonUsername")) != nil){
            randomName = defaults.value(forKey: "anonUsername") as? String
        }else{
            let randomInt = Int.random(in: 10000...99999)
            randomName = "Anon-\(randomInt)"
            defaults.set(randomName, forKey: "anonUsername")
        }
    }
    func isAppAlreadyLaunchedOnce() -> Bool{
        if let _ = defaults.string(forKey: "isAppAlreadyLaunchedOnce"){
            print("App already launched")
            return true
        }else{
            defaults.set(true, forKey: "isAppAlreadyLaunchedOnce")
            print("App launched first time")
            return false
        }
    }
    func removeGMSBlockingGestureRecognizer()
    {
        for gesture in mapView!.gestureRecognizers! {
            mapView?.removeGestureRecognizer(gesture)
        }
    }
    func setupFirebaseAndGeoFire()
    {
        ref = Database.database().reference()
        geoFireRef = GeoFire(firebaseRef: ref.child("GeoFire"))

    }
    func setupBubbleChatContainer()
    {
        let bubbleChatContainerView = UIView()
        bubbleChatContainerView.backgroundColor = UIColor.white
        bubbleChatContainerView.layer.cornerRadius = 25
        bubbleChatContainerView.layer.shadowColor = UIColor.black.cgColor
        bubbleChatContainerView.layer.shadowRadius = 2
        bubbleChatContainerView.layer.shadowOpacity = 0.2
        bubbleChatContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        bubbleChatContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bubbleChatContainerView)
        
        //setup chat label
        let chatLabel = UILabel()
        chatLabel.text = "Chat"
        chatLabel.textColor = UIColor.black
        chatLabel.font = UIFont.systemFont(ofSize: 15)
        chatLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatLabel)
        
        //setup chat table
        chatTableView = UITableView()
        chatTableView?.delegate = self
        chatTableView?.backgroundColor = UIColor.white
        chatTableView?.dataSource = self
        chatTableView?.rowHeight = UITableView.automaticDimension
        chatTableView?.estimatedRowHeight = 44
        chatTableView?.register(BubbleChatCell.self, forCellReuseIdentifier: "BubbleChatCell")
        chatTableView?.translatesAutoresizingMaskIntoConstraints = false
        chatTableView?.tableFooterView = UIView()
        chatTableView?.keyboardDismissMode = .onDrag
        chatTableView?.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: chatTableView!.frame.size.width, height: 1))
        view.addSubview(chatTableView!)
        
        //setup chat bar
        userBubbleMessage = UITextField()
        userBubbleMessage?.delegate = self
        userBubbleMessage?.placeholder = "Chat with Bubble..."
        userBubbleMessage?.layer.cornerRadius = 16
        if #available(iOS 13.0, *) {
            userBubbleMessage?.backgroundColor = .systemGray5
        } else {
            userBubbleMessage?.backgroundColor = .lightGray
        }
        userBubbleMessage?.translatesAutoresizingMaskIntoConstraints = false
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: userBubbleMessage!.frame.height))
        userBubbleMessage?.leftView = paddingView
        userBubbleMessage?.leftViewMode = .always
        userBubbleMessage?.returnKeyType = .send
        userBubbleMessage?.addTarget(self, action: #selector(dismissKeyboardOnUITextFieldDragExit), for: .touchDragExit)
        if #available(iOS 13.0, *) {
            userBubbleMessage?.overrideUserInterfaceStyle = UIUserInterfaceStyle.light
        } else {
            // Fallback on earlier versions
        }
        view.addSubview(userBubbleMessage!)
        
        //setup send button
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        sendButton.addTarget(self, action: #selector(sendBubbleMessageToDatabase), for: UIControl.Event.touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
        
        //setup settings button
        settingsButton = UIButton(type: .system)
        settingsButton.addTarget(self, action: #selector(showSettingsMenu), for: .touchUpInside)
        if #available(iOS 13.0, *) {
            //let largeConfig = UIImage.SymbolConfiguration(pointSize: 30)
            let largeConfig = UIImage.SymbolConfiguration(pointSize: 20)
            let largeLocationFill = UIImage(systemName: "ellipsis", withConfiguration: largeConfig)
            settingsButton.setImage(largeLocationFill, for: .normal)
            //myLocationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        } else {
            settingsButton.setTitle("Settings", for: .normal)
        }
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingsButton)
        
        //Listen for keyboard events
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        //add line below chat label (above table)
        let lineAboveTable = UIView()
        lineAboveTable.backgroundColor = chatTableView?.separatorColor
        lineAboveTable.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lineAboveTable)
        
        //add line below table
        let lineBelowTable = UIView()
        lineBelowTable.backgroundColor = chatTableView?.separatorColor
        lineBelowTable.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lineBelowTable)
        
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            bubbleChatContainerView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            bubbleChatContainerView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            chatLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 15),
            (chatTableView?.leadingAnchor.constraint(equalTo: margins.leadingAnchor))!,
            (chatTableView?.trailingAnchor.constraint(equalTo:margins.trailingAnchor))!,
            lineAboveTable.leadingAnchor.constraint(equalTo: bubbleChatContainerView.leadingAnchor),
            lineAboveTable.trailingAnchor.constraint(equalTo: bubbleChatContainerView.trailingAnchor),
            lineBelowTable.leadingAnchor.constraint(equalTo: bubbleChatContainerView.leadingAnchor),
            lineBelowTable.trailingAnchor.constraint(equalTo: bubbleChatContainerView.trailingAnchor),
            userBubbleMessage!.leadingAnchor.constraint(equalTo: bubbleChatContainerView.leadingAnchor, constant: 5),
            userBubbleMessage!.trailingAnchor.constraint(equalTo: bubbleChatContainerView.trailingAnchor, constant: -50),
            sendButton.leadingAnchor.constraint(equalTo: userBubbleMessage!.trailingAnchor, constant: 4),
            settingsButton.trailingAnchor.constraint(equalTo: chatTableView!.trailingAnchor, constant: -15)
        ])
        
        
        if #available(iOS 11, *) {
          let guide = view.safeAreaLayoutGuide
          NSLayoutConstraint.activate([
            bubbleChatContainerView.topAnchor.constraint(equalTo: guide.centerYAnchor, constant: 75),
            chatLabel.topAnchor.constraint(equalTo: bubbleChatContainerView.topAnchor, constant: 5),
            (chatTableView?.topAnchor.constraint(equalTo: chatLabel.bottomAnchor, constant: 1))!,
            //guide.bottomAnchor.constraint(equalTo: userBubbleMessage.bottomAnchor),
            guide.bottomAnchor.constraint(equalToSystemSpacingBelow: bubbleChatContainerView.bottomAnchor, multiplier: 1.0),
            guide.bottomAnchor.constraint(equalTo: chatTableView!.bottomAnchor, constant: 50),
            userBubbleMessage!.topAnchor.constraint(equalTo: chatTableView!.bottomAnchor, constant: 5),
            userBubbleMessage!.bottomAnchor.constraint(equalTo: bubbleChatContainerView.bottomAnchor, constant: -5),
            lineAboveTable.topAnchor.constraint(equalTo: chatLabel.bottomAnchor),
            lineAboveTable.bottomAnchor.constraint(equalTo: chatTableView!.topAnchor),
            lineBelowTable.topAnchor.constraint(equalTo: chatTableView!.bottomAnchor),
            lineBelowTable.heightAnchor.constraint(equalToConstant: 1),
            sendButton.centerYAnchor.constraint(equalTo: userBubbleMessage!.centerYAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: chatLabel.centerYAnchor)
           ])
        } else {
           NSLayoutConstraint.activate([
            bubbleChatContainerView.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 75),
            chatLabel.topAnchor.constraint(equalTo: bubbleChatContainerView.topAnchor, constant: 10),
            bottomLayoutGuide.topAnchor.constraint(equalTo: bubbleChatContainerView.bottomAnchor, constant: 15),
            bottomLayoutGuide.topAnchor.constraint(equalTo: chatTableView!.bottomAnchor, constant: 15)
           ])
        }
    }
    
    deinit{
        //stop listening for keyboard hide/show events
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    @objc func showSettingsMenu()
    {
        let blockedUsersVC = BlockedUsersVC()
        blockedUsersVC.unblockUserDelegate = self
        let blockedUser = UIAlertAction(title: "Blocked Users", style: .default, handler: {action in self.present(blockedUsersVC, animated: true, completion: nil)})
        let contactSupport = UIAlertAction(title: "Email Support", style: .default, handler: { action in
            //run your function here
            self.emailSupport()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        [blockedUser, contactSupport, cancel].forEach(actionSheet.addAction)

        actionSheet.popoverPresentationController?.sourceView = settingsButton
        present(actionSheet, animated: true)
    }
    func emailSupport(){
        guard MFMailComposeViewController.canSendMail() else {
            let alert = UIAlertController(title: "Error", message: "Unable to open the mail app to send an email. Please manually email \"shahjmirza@gmail.com\" for support.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["shahjmirza@gmail.com"])
        composer.setSubject("Bubble App Support")
        
        present(composer, animated: true)
    }
    @objc func dismissKeyboardOnUITextFieldDragExit(textField: UITextField) {
        textField.resignFirstResponder()
    }
    @objc func keyboardWillChange(notification: Notification)
    {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else{
            return
        }
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification
        {
            view.frame.origin.y = -keyboardRect.height
        } else {
            view.frame.origin.y = 0
        }
    }
    @objc func sendBubbleMessageToDatabase()
    {
        guard let message = userBubbleMessage?.text else{return}
        //if(bubble == nil || message.trimmingCharacters(in: .whitespacesAndNewlines) == ""){ return }
        if(bubble == nil){
            let noBubbleAlert = UIAlertController(title: "Error", message: "You must tap on the map to create a Bubble in order to send a message.", preferredStyle: .alert)
            
            noBubbleAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            self.present(noBubbleAlert, animated: true, completion: nil)
            
            return
        }else if(message.trimmingCharacters(in: .whitespacesAndNewlines) == ""){
            let noMessageAlert = UIAlertController(title: "Error", message: "Please enter a message.", preferredStyle: .alert)
            
            noMessageAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            self.present(noMessageAlert, animated: true, completion: nil)
            
            return
        }
        userBubbleMessage?.text = nil
        bubbleChatMessageToDatabase = .init(name: randomName!, message: message, timestamp: ServerValue.timestamp(), key: "")
        ref.child("Bubble_Messages").childByAutoId().setValue(["name": bubbleChatMessageToDatabase?.name,
            "message": bubbleChatMessageToDatabase?.message,
            "timestamp": bubbleChatMessageToDatabase?.timestamp], withCompletionBlock: {error, ref in
                //self.bubbleMessageKeyToDatabase = ref.key
                self.bubbleChatMessageToDatabase?.key = ref.key!
                self.geoFireRef.setLocation(self.bubbleCenter!, forKey: ref.key!)
            })
        
    }
    func setupMyLocationButton()
    {
        //let button = UIButton.init(type: .roundedRect)
        myLocationButton = UIButton(type: UIButton.ButtonType.system)
        myLocationButton.addTarget(self, action: #selector(centerOnLocation), for: UIControl.Event.touchUpInside)
        myLocationButton.backgroundColor = UIColor.white
        myLocationButton.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        if #available(iOS 13.0, *) {
            //let largeConfig = UIImage.SymbolConfiguration(pointSize: 30)
            let largeConfig = UIImage.SymbolConfiguration(pointSize: 30)
            let largeLocationFill = UIImage(systemName: "location.fill", withConfiguration: largeConfig)
            myLocationButton.setImage(largeLocationFill, for: .normal)
            //myLocationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        } else {
            myLocationButton.setTitle("Center Map", for: .normal)
        }
        self.view.addSubview(myLocationButton)
        myLocationButton.translatesAutoresizingMaskIntoConstraints = false
        myLocationButton.layer.cornerRadius = 10
        myLocationButton.layer.shadowColor = UIColor.black.cgColor
        myLocationButton.layer.shadowRadius = 2
        myLocationButton.layer.shadowOpacity = 0.2
        myLocationButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
           myLocationButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
        ])
        
        if #available(iOS 11, *) {
          let guide = view.safeAreaLayoutGuide
          NSLayoutConstraint.activate([
            myLocationButton.topAnchor.constraint(equalTo: guide.topAnchor)
           ])
        } else {
           NSLayoutConstraint.activate([
            myLocationButton.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor)
           ])
        }
    }
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        drawBubble(arg: coordinate)
    }
    
    @objc func centerOnLocation() -> Bool
    {
//        print("test")
        guard let lat = locationManager.location?.coordinate.latitude,
            let lng = locationManager.location?.coordinate.longitude else { return false }

        let camera = GMSCameraPosition.camera(withLatitude: lat ,longitude: lng , zoom: zoomLevel)
        mapView?.animate(to: camera)

        return true
    }
    
//    func setupMap()
//    {
//        if let location = locationManager.location?.coordinate
//        {
//            let camera = GMSCameraPosition.camera(withLatitude: location.latitude, longitude: location.longitude, zoom: 19.0)
//            mapView?.camera = camera
//        }
//        mapView?.isMyLocationEnabled = true
//        mapView?.settings.compassButton = true
//        mapView?.settings.myLocationButton = true
//    }
    
    func drawBubble(arg para:CLLocationCoordinate2D)
    {
        if (bubble != nil)
        {
            mapView?.clear()
            bubble = nil
            bubbleQuery?.removeAllObservers()
            bubbleChatMessagesFromDatabase.removeAll()
            chatTableView?.reloadData()
        }
        bubble = GMSCircle()
        bubble?.strokeWidth = 10
        bubble?.strokeColor = UIColor(red: CGFloat(0/255.0), green: CGFloat(255.0/255.0), blue: CGFloat(0/255.0), alpha: CGFloat(200.0/255.0))
        bubble?.fillColor = UIColor(red: CGFloat(0/255.0), green: CGFloat(255.0/255.0), blue: CGFloat(0/255.0), alpha: CGFloat(75.0/255.0))
        
        bubble?.radius = 100
        bubble?.position = para
        bubble?.map = mapView
        queryBubble(arg: para)
    }
    func queryBubble(arg para: CLLocationCoordinate2D)
    {
        bubbleCenter = CLLocation(latitude: para.latitude, longitude: para.longitude)
        bubbleQuery = geoFireRef.query(at: bubbleCenter!, withRadius: 0.1)
        bubbleQuery?.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
            self.ref.child("Bubble_Messages").child(key).observeSingleEvent(of: .value, with: { (snapshot) in
                self.addBubbleMessageToList(arg: snapshot)
            })
        })
        bubbleQuery?.observe(.keyExited, with: { (key: String!, location: CLLocation!) in
            self.removeBubbleMessageFromList(arg: key)
        })
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendBubbleMessageToDatabase()
        return true
    }
    func removeBubbleMessageFromList(arg key: String){
        //bubbleChatMessagesFromDatabase.contains(where: {$0.key == key})
        let i = bubbleChatMessagesFromDatabase.firstIndex(where: {$0.key == key})
        bubbleChatMessagesFromDatabase.remove(at: i!)
        chatTableView?.reloadData()
        chatTableView?.scrollToBottom(animated: true)
    }
    func addBubbleMessageToList(arg snapshot: DataSnapshot)
    {
//        let userDict = snapshot.value as! [String: Any]
//        bubbleChatMessagesFromDatabase.append(userDict.name)
        //print(snapshot)
        let test = BubbleChatMessageFromDatabase(snap: snapshot)
        if(blockedUsers.contains(test.name)){return}
        bubbleChatMessagesFromDatabase.append(test)
        bubbleChatMessagesFromDatabase = bubbleChatMessagesFromDatabase.sorted(by: { $0.timestamp < $1.timestamp})
        chatTableView?.reloadData()
        chatTableView?.scrollToBottom(animated: true)
        
    }
//    private void drawBubble(LatLng latLng) {
//        if (bubble != null) {
//            bubble.remove();
//            bubble = null;
//            geoQuery.removeAllListeners();
//            bubbleMessageListAdapter.notifyItemRangeRemoved(0, mBubbleMessages.size());
//            mBubbleMessages.clear();
//        }
//        bubble = mMap.addCircle(new CircleOptions()
//                .strokeWidth(10)
//                .strokeColor(Color.argb(200, 0, 255, 0))
//                .fillColor(Color.argb(75, 0, 255, 0))
//                .radius(25)
//                .center(latLng));
//        bubbleCenter = new LatLng(latLng.latitude, latLng.longitude);
//        queryBubble();
//    }
    func checkLocationServices()
    {
        if CLLocationManager.locationServicesEnabled()
        {
            setupLocationManager()
            checkLocationAuthorization()
        }else
        {
            
        }
    }
    func setupLocationManager()
    {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    func checkLocationAuthorization()
    {
        switch CLLocationManager.authorizationStatus()
        {
            case .authorizedWhenInUse:
                setupMap()
                break
            case .denied:
                createAlert(title: "Error", message: "Bubble is not authorized to use location services.")
                break
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
                break
            case .restricted:
                createAlert(title: "Error", message: "Bubble is not authorized to use location services.")
                break
            case .authorizedAlways:
                setupMap()
                break
        }
    }
    func setupMap()
    {
        if let location = locationManager.location?.coordinate
        {
            let camera = GMSCameraPosition.camera(withLatitude: location.latitude, longitude: location.longitude, zoom: zoomLevel)
            mapView?.camera = camera
        }
        mapView?.isMyLocationEnabled = true
    }
    
    func styleMap()
    {
        
        do {
          // Set the map style by passing the URL of the local file.
          if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
            mapView?.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
          } else {
            NSLog("Unable to find style.json")
          }
        } catch {
          NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        
    }
    func createAlert(title:String, message:String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
}

extension ViewController: CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        NSLog("Authorization status changed.")
        checkLocationAuthorization()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource, UnblockUserDelegate, MFMailComposeViewControllerDelegate
{
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let _ = error {
            controller.dismiss(animated: true)
            return
        }
        
        switch result {
        case .cancelled:
            print("Cancelled")
        case .failed:
            print("Failed to send")
        case .saved:
            print("Saved")
        case .sent:
            print("Email sent")
        }
        
        controller.dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if bubbleChatMessagesFromDatabase.count == 0 {
            tableView.setEmptyMessage("Tap on the map to load messages from that Bubble here!")
        } else {
            tableView.restore()
        }
        return bubbleChatMessagesFromDatabase.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BubbleChatCell") as! BubbleChatCell
        let bubbleChatMessageFromDatabase = bubbleChatMessagesFromDatabase[indexPath.row]
        cell.set(bubbleChatMessageFromDatabase: bubbleChatMessageFromDatabase)
        cell.backgroundColor = UIColor.white
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //1. you
        //2. already blocked
        //3. not blocked
        let bubbleChatMessageFromDatabase = bubbleChatMessagesFromDatabase[indexPath.row]
        if(bubbleChatMessageFromDatabase.name == defaults.value(forKey: "anonUsername") as? String){
            let deleteMessageAlertAction = UIAlertAction(title: "Delete Message", style: .destructive, handler: { action in
                //run your function here
                self.deleteMessage(message: bubbleChatMessageFromDatabase)
            })

            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            [deleteMessageAlertAction, cancel].forEach(actionSheet.addAction)

            actionSheet.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
            present(actionSheet, animated: true)
        }else{
            let blockUserAlertAction = UIAlertAction(title: "Block User", style: .destructive, handler: { action in
                //run your function here
                self.blockUser(user: bubbleChatMessageFromDatabase.name)
            })
            let reportUserAlertAction = UIAlertAction(title: "Report User", style: .destructive, handler: { action in
                //run your function here
                self.reportUser(user: bubbleChatMessageFromDatabase.name)
            })

            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            [blockUserAlertAction, reportUserAlertAction, cancel].forEach(actionSheet.addAction)

            actionSheet.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
            present(actionSheet, animated: true)
        }
    }
    
    func deleteMessage(message: BubbleChatMessageFromDatabase){
        geoFireRef.removeKey(message.key)
        ref.child("Bubble_Messages").child(message.key).removeValue()
    }
    
    func didUnblockUser() {
        blockedUsers = defaults.value(forKey: "blockedUsers") as! [String]
    }
            /*for blockedUser in blockedUsers!
            {
                if(bubbleChatMessageFromDatabase.name == blockedUser){
                    let alert = UIAlertController(title: "User Already Blocked", message: "You have already blocked this user. You will no longer receive messages from them. If you would like to unblock them, go to the options menu at the top right of the chatbox and tap \"Blocked Users\", then swipe on a user you'd like to unblock and tap \"Delete\".", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    
                    self.present(alert, animated: true, completion: nil)
                    break
                }else if(bubbleChatMessageFromDatabase.name != defaults.value(forKey: "anonUsername") as? String)
                {
                    let blockUserAlertAction = UIAlertAction(title: "Block User", style: .destructive, handler: { action in
                        //run your function here
                        self.blockUser(blockedUser: bubbleChatMessageFromDatabase.name)
                    })

                    let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    
                    let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    [blockUserAlertAction, cancel].forEach(actionSheet.addAction)

                    present(actionSheet, animated: true)
                }
            }
        }
        else{
            if(bubbleChatMessageFromDatabase.name != defaults.value(forKey: "anonUsername") as? String)
            {
                let blockUserAlertAction = UIAlertAction(title: "Block User", style: .destructive, handler: { action in
                    //run your function here
                    self.blockUser(blockedUser: bubbleChatMessageFromDatabase.name)
                })

                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                [blockUserAlertAction, cancel].forEach(actionSheet.addAction)

                present(actionSheet, animated: true)
            }
        */
        
        
    
    
    func blockUser(user: String)
    {
        if(blockedUsers.contains(user))
        {
            let alert = UIAlertController(title: "User Already Blocked", message: "You have already blocked this user. You will no longer receive messages from them. If you would like to unblock them, go to the options menu at the top right of the chatbox and tap \"Blocked Users\", then swipe on a user you'd like to unblock and tap \"Delete\".", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }else{
            blockedUsers.append(user)
            defaults.set(blockedUsers, forKey: "blockedUsers")
        }
    }
    func reportUser(user: String)
    {
        let alert = UIAlertController(title: "Confirm Report", message: "Are you sure you want to report \(user)?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
            //run your function here
            self.ref.child("Reported_Users").childByAutoId().setValue(user)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}
