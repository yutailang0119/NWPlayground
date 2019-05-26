//
//  ChatViewModel.swift
//  NWPlayground
//
//  Created by Yutaro Muta on 2019/05/08.
//  Copyright © 2019 yutailang0119. All rights reserved.
//

import Foundation
import Network

protocol ChatViewModelInput {
    func send(message: String?)
    func stopChat()
}

protocol ChatViewModelOutput {
    var cellViewModels: [MessageCellViewModel] { get }
}

protocol ChatViewModelType: ChatViewModelInput, ChatViewModelOutput {
    var input: ChatViewModelInput { get }
    var output: ChatViewModelOutput { get }
}

final class ChatViewModel: NSObject, ChatViewModelType {

    private let listnerQueueLabel = "io.yutailang0119.NWPlayground.listener"
    private let connectionQueueLabel = "io.yutailang0119.NWPlayground.sender"
    private let networkType = "_networkplayground._udp."
    private let networkDomain = "local"
    private var connection: NWConnection?
    private let netServiceBrowser = NetServiceBrowser()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let userName: String
    private let receivedAction: () -> Void
    private let sentAction: () -> Void
    private let showAlertAction: (_ title: String?, _ message: String?) -> Void

    var input: ChatViewModelInput {
        return self
    }

    var output: ChatViewModelOutput {
        return self
    }

    private var viewModels: [MessageCellViewModel] = []

    init(userName: String,
         receivedAction: @escaping () -> Void,
         sentAction: @escaping () -> Void,
         showAlertAction: @escaping (_ title: String?, _ message: String?) -> Void) {
        self.userName = userName
        self.receivedAction = receivedAction
        self.sentAction = sentAction
        self.showAlertAction = showAlertAction

        super.init()

        netServiceBrowser.delegate = self
        netServiceBrowser.searchForServices(ofType: networkType, inDomain: networkDomain)
        startListener(name: userName)
    }

}

extension ChatViewModel {

    private func startListener(name: String) {
        let udpParams = NWParameters.udp
        guard let listener = try? NWListener(using: udpParams) else {
            fatalError()
        }

        listener.service = NWListener.Service(name: name, type: networkType)

        let listnerQueue = DispatchQueue(label: listnerQueueLabel)

        // Processing at the new connection
        listener.newConnectionHandler = { [unowned self] (connection: NWConnection) in
            connection.start(queue: listnerQueue)
            self.receive(on: connection)
        }

        // Start Listener
        listener.start(queue: listnerQueue)
        let serviceName = listener.service?.name ?? "Unkown"
        print("Start Listening as \(serviceName)")
    }

    private func receive(on connection: NWConnection) {
        print("Receive on connection: \(connection)")
        connection.receiveMessage { [weak self] (data: Data?, contentContext: NWConnection.ContentContext?, isComplete: Bool, error: NWError?) in
            if let data = data,
                let chatData = try? self?.decoder.decode(ChatData.self, from: data) {
                let cellViewModel = MessageCellViewModel(type: .others(chatData: chatData))
                self?.viewModels.append(cellViewModel)
                self?.receivedAction()
            }

            if let error = error {
                print(error)
            } else {
                // Call receive(on:) method recursively if there are no errors
                self?.receive(on: connection)
            }
        }
    }

    private func startConnection(to name: String) {
        let udpParams = NWParameters.udp
        let endpoint = NWEndpoint.service(name: name, type: networkType, domain: networkDomain, interface: nil)
        connection = NWConnection(to: endpoint, using: udpParams)

        connection?.stateUpdateHandler = { [weak self] (state: NWConnection.State) in
            guard state != .ready else {
                return
            }

            let cellViewModel = MessageCellViewModel(type: .announce(message: "Connected with \(name)"))
            self?.viewModels.append(cellViewModel)
            self?.receivedAction()

            // do something
        }

        // Start Connection
        let connectionQueue = DispatchQueue(label: connectionQueueLabel)
        connection?.start(queue: connectionQueue)
    }

}

extension ChatViewModel: ChatViewModelInput {

    func send(message: String?) {
        guard let message = message,
            !message.isEmpty else {
                showAlertAction("Invalid message",
                                "Please set message text")
                return
        }
        guard let connection = connection else {
            showAlertAction("Connection not found",
                            "Please search near services")
            return
        }

        let chatData = ChatData(userName: userName,
                                message: message)

        guard let data = try? encoder.encode(chatData) else {
            showAlertAction("Failed to send",
                            "Invalid data format")
            return
        }

        // Processing when sending is completed
        let completion = NWConnection.SendCompletion.contentProcessed { [weak self] (error: NWError?) in
            print("Send complete")
            let cellViewModel = MessageCellViewModel(type: .own(message: message))
            self?.viewModels.append(cellViewModel)
            self?.receivedAction()
            self?.sentAction()
        }

        // Execution sending
        connection.send(content: data, completion: completion)
    }

    func stopChat() {
        netServiceBrowser.stop()
    }

}

extension ChatViewModel: ChatViewModelOutput {
    var cellViewModels: [MessageCellViewModel] {
        return viewModels
    }
}

extension ChatViewModel: NetServiceBrowserDelegate {
    // Called before starting to explore
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        let cellViewModel = MessageCellViewModel(type: .announce(message: "Start searching services"))
        viewModels.append(cellViewModel)
        receivedAction()
    }

    // Called when a service is found
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        // If it is other than myself start sending
        guard service.name != userName else {
                return
        }
        startConnection(to: service.name)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
    }
}
