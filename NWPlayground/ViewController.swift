//
//  ViewController.swift
//  NWPlayground
//
//  Created by Yutaro Muta on 2019/05/03.
//  Copyright © 2019 yutailang0119. All rights reserved.
//

import UIKit
import Network

class ViewController: UIViewController {

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
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
            tableView.dataSource = self
        }
    }
    @IBOutlet weak var messageTextField: UITextField! {
        didSet {
            messageTextField.text = nil
            messageTextField.isEnabled = false
        }
    }
    @IBOutlet weak var sendButton: UIButton! {
        didSet {
            sendButton.isEnabled = false
        }
    }

    private let cellIdentifier: String = "cell"
    private lazy var viewModel: ViewModel = ViewModel(receivedAction: self.receivedMessage,
                                                      sentAction: self.sentMessage,
                                                      showAlertAction: self.showAlert)

    @IBAction func start(_ sender: UIButton) {
        guard let name = nameTextField.text,
            !name.isEmpty else {
            showAlert(title: "Invalid name", message: "Please set valid user name")
            return
        }

        nameTextField.isEnabled = false
        startButton.isEnabled = false
        messageTextField.isEnabled = true
        sendButton.isEnabled = true

        viewModel.input.updateUser(name: name)
        viewModel.input.startSearchForServices()
        viewModel.input.startListener(name: name)
    }

    @IBAction func send(_ sender: UIButton) {
        viewModel.input.send(message: messageTextField.text)
    }

    private func receivedMessage() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func sentMessage() {
        DispatchQueue.main.async { [weak self] in
            self?.messageTextField.text = nil
        }
    }

    private func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.output.cellViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = viewModel.cellViewModels[indexPath.row].text
        return cell
    }

}
