//
//  RegisterViewController.swift
//  NWPlayground
//
//  Created by Yutaro Muta on 2019/05/08.
//  Copyright © 2019 yutailang0119. All rights reserved.
//

import UIKit

final class RegisterViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField! {
        didSet {
            nameTextField.text = nil
            nameTextField.isEnabled = true
        }
    }
    @IBOutlet weak var startButton: UIButton! {
        didSet {
            startButton.isEnabled = true
        }
    }

    @IBAction func start(_ sender: UIButton) {
        guard let userName = nameTextField.text,
            !userName.isEmpty else {
                showAlert(title: "Invalid name", message: "Please set valid user name")
                return
        }

        let dependency = ChatViewController.Dependency(userName: userName)
        let viewController = ChatViewController.make(with: dependency)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
