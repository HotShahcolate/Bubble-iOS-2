//
//  BlockedUsersVC.swift
//  Bubble
//
//  Created by Shah Mirza on 4/19/20.
//  Copyright © 2020 Shah Mirza. All rights reserved.
//

import UIKit

protocol UnblockUserDelegate {
    func didUnblockUser()
}

class BlockedUsersVC: UIViewController
{
    var blockedUsers = [String]()
    let blockedUsersTableView = UITableView()
    var safeArea: UILayoutGuide!
    let defaults = UserDefaults.standard
    var unblockUserDelegate: UnblockUserDelegate!
    
    override func viewDidLoad() {
        safeArea = view.layoutMarginsGuide
        blockedUsersTableView.dataSource = self
        blockedUsersTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellid")
        configureTableView()
        if((defaults.value(forKey: "blockedUsers")) != nil){
            blockedUsers = defaults.value(forKey: "blockedUsers") as! [String]
            blockedUsersTableView.reloadData()
        }
//        blockedUsers.append("test")
//        blockedUsers.append("test")
//        blockedUsers.append("test")
//        blockedUsers.append("test")
//        blockedUsers.append("test")
//        blockedUsersTableView.reloadData()
    }
    
    func configureTableView()
    {
        view.addSubview(blockedUsersTableView)
        
        blockedUsersTableView.backgroundColor = .white
        blockedUsersTableView.translatesAutoresizingMaskIntoConstraints = false
        blockedUsersTableView.topAnchor.constraint(equalTo: safeArea.topAnchor).isActive = true
        blockedUsersTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        blockedUsersTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        blockedUsersTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}

extension BlockedUsersVC: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if blockedUsers.count == 0 {
            tableView.setEmptyMessage("No blocked users. Tap on a message in the chat box to block that user.")
        } else {
            tableView.restore()
        }
        return blockedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellid", for: indexPath)
        cell.backgroundColor = .white
        cell.textLabel?.textColor = .black
        let blockedUser = blockedUsers[indexPath.row]
        cell.textLabel?.text = blockedUser
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        blockedUsers.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        defaults.set(blockedUsers, forKey: "blockedUsers")
        unblockUserDelegate.didUnblockUser()
    }
}

