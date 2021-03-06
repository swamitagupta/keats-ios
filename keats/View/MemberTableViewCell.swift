//
//  MemberTableViewCell.swift
//  keats
//
//  Created by Swamita on 12/05/21.
//

import UIKit

class MemberTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var removeButton: UIButton!
    
    @IBOutlet weak var hostMarkView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        hostMarkView.curvedButtonView(color: "KeatsOrange")
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
