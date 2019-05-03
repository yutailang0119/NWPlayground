//
//  ViewModel.swift
//  NWPlayground
//
//  Created by Yutaro Muta on 2019/05/06.
//  Copyright © 2019 yutailang0119. All rights reserved.
//

import Foundation
import Network

protocol Input {
    func updateUser(name: String)
    func startSearchForServices()
    func startListener(name: String)
    func send(message: String?)
}

protocol Output {
    var cellViewModels: [CellViewModel] { get set }
}

final class ViewModel: NSObject, Output {

    private let listnerQueueLabel = "io.yutailang0119.NWPlayground.listener"
    private let connectionQueueLabel = "io.yutailang0119.NWPlayground.sender"
    private let networkType = "_networkplayground._udp."
    private let networkDomain = "local"
    private var connection: NWConnection?
    private let netServiceBrowser = NetServiceBrowser()

    private let receivedAction: () -> Void
    private let sentAction: () -> Void
    private let showAlertAction: (_ title: String?, _ message: String?) -> Void
    private var userName: String?

    var input: Input {
        return self
    }

    var output: Output {
        return self
    }

    var cellViewModels: [CellViewModel] = []

    init(receivedAction: @escaping () -> Void,
         sentAction: @escaping () -> Void,
         showAlertAction: @escaping (_ title: String?, _ message: String?) -> Void) {
        self.receivedAction = receivedAction
        self.sentAction = sentAction
        self.showAlertAction = showAlertAction
    }

}

extension ViewModel: Input {

    func updateUser(name: String) {
        self.userName = name
    }

    func startSearchForServices() {
        netServiceBrowser.delegate = self
        netServiceBrowser.searchForServices(ofType: networkType, inDomain: networkDomain)
    }

    func startListener(name: String) {
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
                let message = String(data: data, encoding: .utf8) {
                let cellViewModel = CellViewModel(message: message)
                self?.cellViewModels.append(cellViewModel)
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

        connection?.stateUpdateHandler = { (state: NWConnection.State) in
            guard state != .ready else {
                return
            }
            print("Connection is ready")

            // do something
        }

        // Start Connection
        let connectionQueue = DispatchQueue(label: connectionQueueLabel)
        connection?.start(queue: connectionQueue)
    }

    func send(message: String?) {
        guard let userName = userName,
            !userName.isEmpty else {
                showAlertAction("Invalid name", "Please set valid user name")
                return
        }
        guard let message = message,
            !message.isEmpty else {
                showAlertAction("Invalid message", "Please set message text")
                return
        }
        guard let connection = connection else {
            showAlertAction("Connection not found", "Please search near services")
            return
        }

        let data = "\(userName): \(message)".data(using: .utf8)

        // Processing when sending is completed
        let completion = NWConnection.SendCompletion.contentProcessed { [weak self] (error: NWError?) in
            print("Send complete")
            let cellViewModel = CellViewModel(message: "You: \(message)")
            self?.cellViewModels.append(cellViewModel)
            self?.receivedAction()
            self?.sentAction()
        }

        // Execution sending
        connection.send(content: data, completion: completion)
    }
}

extension ViewModel: NetServiceBrowserDelegate {
    // Called before starting to explore
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        showAlertAction("Start searching services", "")
    }

    // Called when a service is found
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        // If it is other than myself start sending
        guard let userName = userName,
            service.name != userName else {
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
