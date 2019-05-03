//
//  CellViewModel.swift
//  NWPlayground
//
//  Created by Yutaro Muta on 2019/05/06.
//  Copyright © 2019 yutailang0119. All rights reserved.
//

import Foundation

struct CellViewModel {
    private let message: String

    init(message: String) {
        self.message = message
    }

    var text: String {
        return message
    }
}
