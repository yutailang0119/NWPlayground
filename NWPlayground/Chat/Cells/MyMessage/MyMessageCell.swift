//
//  MyMessageCell.swift
//  NWPlayground
//
//  Created by Yutaro Muta on 2019/05/26.
//  Copyright © 2019 yutailang0119. All rights reserved.
//

import UIKit

final class MyMessageCell: UITableViewCell, NibInstantitable {

    @IBOutlet weak var messageLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil

    }
}

extension MyMessageCell: MessageCellType {
    func configure(with viewModel: MessageCellViewModel) {
        messageLabel.text = viewModel.message
    }
}
