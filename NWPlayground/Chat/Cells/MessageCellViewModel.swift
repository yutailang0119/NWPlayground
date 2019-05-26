//
//  MessageCellViewModel.swift
//  NWPlayground
//
//  Created by Yutaro Muta on 2019/05/08.
//  Copyright © 2019 yutailang0119. All rights reserved.
//

import Foundation

struct MessageCellViewModel {
    enum MessageType {
        case own(message: String)
        case others(chatData: ChatData)
        case announce(message: String)

        var cellIdentifier: String {
            switch self {
            case .own:
                return MyMessageCell.nibName
            case .others:
                return OthersMessageCell.nibName
            case .announce:
                return AnnounceMessageCell.nibName
            }
        }

        var message: String {
            switch self {
            case .own(let message):
                return message
            case .others(let chatData):
                return "\(chatData.userName): \(chatData.message)"
            case .announce(let message):
                return message
            }
        }
    }

    private let type: MessageType

    init(type: MessageType) {
        self.type = type
    }

    var message: String {
        return type.message
    }

    var cellIdentifier: String {
        return type.cellIdentifier
    }
}
