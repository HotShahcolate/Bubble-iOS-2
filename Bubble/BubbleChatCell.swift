//
//  BubbleChatCell.swift
//  Bubble
//
//  Created by Shah Mirza on 3/14/20.
//  Copyright © 2020 Shah Mirza. All rights reserved.
//

import UIKit

class BubbleChatCell: UITableViewCell {
    
    var name = UILabel()
    var message = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(name)
        addSubview(message)
        configureName()
        configureMessage()
        
        
        NSLayoutConstraint.activate([
            name.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            name.widthAnchor.constraint(equalToConstant: 150),
            message.leadingAnchor.constraint(equalTo: name.trailingAnchor, constant: 2),
            message.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        
        if #available(iOS 11, *) {
          NSLayoutConstraint.activate([
            //name.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            //message.topAnchor.constraint(equalTo: topAnchor),
            name.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            message.topAnchor.constraint(equalTo: name.topAnchor),
            message.bottomAnchor.constraint(equalTo: bottomAnchor)
           ])
        } else {
           NSLayoutConstraint.activate([
            name.topAnchor.constraint(equalTo: topAnchor),
            message.topAnchor.constraint(equalTo: topAnchor)
           ])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(bubbleChatMessageFromDatabase: BubbleChatMessageFromDatabase)
    {
        name.text = bubbleChatMessageFromDatabase.name + " (" + convertTimestamp(serverTimestamp: bubbleChatMessageFromDatabase.timestamp) + ")"
        message.text = bubbleChatMessageFromDatabase.message
    }
    func configureName()
    {
        name.font = UIFont.boldSystemFont(ofSize: 12)
        name.textColor = UIColor.black
        name.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func convertTimestamp(serverTimestamp: Double) -> String {
        let x = serverTimestamp / 1000
        let date = NSDate(timeIntervalSince1970: x)
        let formatter = DateFormatter()
        //formatter.dateStyle = .long
        formatter.timeStyle = .short

        return formatter.string(from: date as Date)
    }
    
    func configureMessage()
    {
        message.font = UIFont.systemFont(ofSize: 12)
        message.textColor = UIColor.black
        message.translatesAutoresizingMaskIntoConstraints = false
        message.numberOfLines = 0
    }
}
