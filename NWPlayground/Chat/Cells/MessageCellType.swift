//
//  MessageCellType.swift
//  NWPlayground
//
//  Created by Yutaro Muta on 2019/05/26.
//  Copyright © 2019 yutailang0119. All rights reserved.
//

import Foundation

protocol MessageCellType {
    func configure(with viewModel: MessageCellViewModel)
}
