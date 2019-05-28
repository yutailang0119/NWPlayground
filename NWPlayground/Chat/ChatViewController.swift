//
//  ChatViewController.swift
//  NWPlayground
//
//  Created by Yutaro Muta on 2019/05/08.
//  Copyright © 2019 yutailang0119. All rights reserved.
//

import UIKit

final class ChatViewController: UIViewController {

    struct Dependency {
        let userName: String
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(MyMessageCell.nib, forCellReuseIdentifier: MyMessageCell.nibName)
            tableView.register(OthersMessageCell.nib, forCellReuseIdentifier: OthersMessageCell.nibName)
            tableView.register(AnnounceMessageCell.nib, forCellReuseIdentifier: AnnounceMessageCell.nibName)
            tableView.dataSource = self
        }
    }
    @IBOutlet weak var messageTextField: UITextField! {
        didSet {
            messageTextField.text = nil
            messageTextField.isEnabled = true
        }
    }
    @IBOutlet weak var sendButton: UIButton! {
        didSet {
            sendButton.isEnabled = true
        }
    }

    static func make(with dependency: Dependency) -> ChatViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        viewController.viewModel = ChatViewModel(
            userName: dependency.userName,
            receivedAction: { [weak viewController] in
                viewController?.receivedMessage()
            },
            sentAction: { [weak viewController] in
                viewController?.sentMessage()
            },
            showAlertAction: { [weak viewController] (title, message) in
                viewController?.showAlert(title: title, message: message)
            }
        )
        return viewController
    }

    private var viewModel: ChatViewModelType!

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.input.stopChat()
    }

    @IBAction func send(_ sender: UIButton) {
        viewModel.input.send(message: messageTextField.text)
    }

    private func receivedMessage() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView?.reloadData()
        }
    }

    private func sentMessage() {
        DispatchQueue.main.async { [weak self] in
            self?.messageTextField.text = nil
        }
    }
}

extension ChatViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.output.cellViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellViewModel = viewModel.output.cellViewModels[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellViewModel.cellIdentifier, for: indexPath)
        guard let messageCell = cell as? MessageCellType else {
            fatalError()
        }
        messageCell.configure(with: cellViewModel)
        return cell
    }

}

