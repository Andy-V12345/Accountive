//
//  Network.swift
//  Training Reminder
//
//  Created by Andy Vu on 10/3/23.
//

import Foundation
import Network

class Network: ObservableObject {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "Monitor")
    
    private (set) var connected = false
    
    init() {
        monitor.pathUpdateHandler = { path in
            self.connected = path.status == .satisfied
            Task {
                await MainActor.run {
                    self.objectWillChange.send()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
}
