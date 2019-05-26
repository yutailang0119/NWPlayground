//
//  NibInstantitable.swift
//  NWPlayground
//
//  Created by Yutaro Muta on 2019/05/26.
//  Copyright © 2019 yutailang0119. All rights reserved.
//

import UIKit

protocol NibInstantitable {}

extension NibInstantitable {

    static var nibName: String {
        return String(describing: Self.self)
    }

    static var nib: UINib {
        return UINib(nibName: Self.nibName, bundle: nil)
    }

    static func instantiateFromNib() -> Self {
        return nib.instantiate(withOwner: self, options: nil)[0] as! Self
    }

}
