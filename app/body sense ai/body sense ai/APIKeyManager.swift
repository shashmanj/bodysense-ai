//
//  ConnectivityMonitor.swift  (was APIKeyManager.swift)
//  body sense ai
//
//  Network connectivity monitor for BodySense AI.
//  On-device AI doesn't need API keys — this just tracks network status
//  for features like HealthKit sync and doctor appointments.
//

import Foundation
import Network

// MARK: - Network Connectivity Monitor

@MainActor
@Observable
final class ConnectivityMonitor {
    static let shared = ConnectivityMonitor()

    private(set) var isConnected: Bool = true
    private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType: String, Sendable {
        case wifi = "Wi-Fi"
        case cellular = "Cellular"
        case wired = "Wired"
        case unknown = "Unknown"
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.bodysenseai.connectivity")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { @MainActor in
                self.isConnected = path.status == .satisfied

                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wired
                } else {
                    self.connectionType = .unknown
                }
            }
        }
        monitor.start(queue: queue)
    }

    /// Human-readable status
    var statusText: String {
        if !isConnected {
            return "Offline"
        }
        return "Online (\(connectionType.rawValue))"
    }

    deinit {
        monitor.cancel()
    }
}
