//
//  BodySenseRingManager.swift
//  body sense ai
//
//  CoreBluetooth BLE manager for BodySense Ring pairing, data sync, and background reconnection.
//  Handles heart rate, SpO2, temperature, steps, sleep state, battery, and firmware characteristics.
//

import Foundation
import CoreBluetooth
import os.log

// MARK: - BLE Service & Characteristic UUIDs

private enum BLEConstants {
    static let serviceUUID           = CBUUID(string: "A0001000-B5A3-F393-E0A9-E50E24DCCA9E")
    static let heartRateCharUUID     = CBUUID(string: "A0001001-B5A3-F393-E0A9-E50E24DCCA9E")
    static let spo2CharUUID          = CBUUID(string: "A0001002-B5A3-F393-E0A9-E50E24DCCA9E")
    static let temperatureCharUUID   = CBUUID(string: "A0001003-B5A3-F393-E0A9-E50E24DCCA9E")
    static let stepsCharUUID         = CBUUID(string: "A0001004-B5A3-F393-E0A9-E50E24DCCA9E")
    static let sleepStateCharUUID    = CBUUID(string: "A0001005-B5A3-F393-E0A9-E50E24DCCA9E")
    static let batteryCharUUID       = CBUUID(string: "A0001006-B5A3-F393-E0A9-E50E24DCCA9E")
    static let firmwareCharUUID      = CBUUID(string: "A0001007-B5A3-F393-E0A9-E50E24DCCA9E")

    static let restoreIdentifier = "com.bodysenseai.ring.central"
    static let savedRingUUIDKey  = "BodySenseRing_SavedPeripheralUUID"
    static let scanTimeout: TimeInterval = 30
    static let syncInterval: TimeInterval = 300 // 5 minutes
}

// MARK: - BodySenseRingManager

@MainActor @Observable
final class BodySenseRingManager: NSObject {
    static let shared = BodySenseRingManager()

    // MARK: - State

    var connectionState: RingConnectionState = .disconnected
    var discoveredRings: [DiscoveredRing] = []
    var connectedRing: ConnectedRing?
    var batteryLevel: Int = 0
    var firmwareVersion: String = ""
    var isScanning: Bool = false
    var bluetoothState: CBManagerState = .unknown
    var errorMessage: String?

    // MARK: - Latest Readings

    var latestHeartRate: Int = 0
    var latestSpO2: Int = 0
    var latestTemperature: Double = 0    // Celsius
    var latestSteps: Int = 0
    var latestSleepState: SleepState = .awake

    // MARK: - Private

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var scanTimer: Timer?
    private var syncTimer: Timer?
    private var lastSyncDate: Date?
    private let logger = Logger(subsystem: "com.bodysenseai", category: "RingBLE")

    // MARK: - Initialisation

    private override init() {
        super.init()
    }

    /// Call this to set up BLE — deferred so it doesn't crash on app launch
    func setup() {
        guard centralManager == nil else { return }
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
        )
    }

    // MARK: - Public API

    func startScanning() {
        setup()
        guard centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth is not available. Please enable Bluetooth in Settings."
            logger.warning("Cannot scan — Bluetooth not powered on (state: \(self.centralManager.state.rawValue))")
            return
        }

        discoveredRings = []
        isScanning = true
        connectionState = .scanning
        errorMessage = nil

        centralManager.scanForPeripherals(
            withServices: [BLEConstants.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        logger.info("Started scanning for BodySense Rings")

        // Auto-stop after timeout
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: BLEConstants.scanTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.stopScanning()
            }
        }
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil

        if connectionState == .scanning {
            connectionState = .disconnected
        }

        logger.info("Stopped scanning")
    }

    func connect(to ring: DiscoveredRing) {
        stopScanning()
        connectionState = .connecting

        // Find the CBPeripheral from the central manager's known peripherals
        let peripherals = centralManager.retrievePeripherals(withIdentifiers: [ring.id])
        guard let peripheral = peripherals.first else {
            errorMessage = "Ring no longer available. Please scan again."
            connectionState = .disconnected
            logger.error("Could not retrieve peripheral for UUID: \(ring.id)")
            return
        }

        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            CBConnectPeripheralOptionNotifyOnNotificationKey: true
        ])

        // Save UUID for auto-reconnect
        UserDefaults.standard.set(ring.id.uuidString, forKey: BLEConstants.savedRingUUIDKey)

        logger.info("Connecting to ring: \(ring.name) (\(ring.id))")
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }

        cleanUpConnection()
        UserDefaults.standard.removeObject(forKey: BLEConstants.savedRingUUIDKey)

        logger.info("Disconnected from ring")
    }

    func syncDataToHealthStore(_ store: HealthStore) {
        guard connectionState == .connected else { return }
        let now = Date()

        // Heart rate
        if latestHeartRate > 0 && InputValidator.isValidHeartRate(latestHeartRate) {
            let reading = HeartRateReading(
                value: latestHeartRate,
                date: now,
                context: latestSleepState == .awake ? .rest : .sleep,
                notes: "BodySense Ring"
            )
            store.heartRateReadings.append(reading)
        }

        // SpO2
        if latestSpO2 > 0 {
            let reading = SpO2Reading(value: Double(latestSpO2), date: now)
            store.spo2Readings.append(reading)
        }

        // Temperature
        if latestTemperature > 0 && InputValidator.isValidBodyTemp(latestTemperature) {
            let reading = BodyTempReading(value: latestTemperature, date: now)
            store.bodyTempReadings.append(reading)
        }

        // Steps — update today's entry or create new
        if latestSteps > 0 {
            let calendar = Calendar.current
            if let idx = store.stepEntries.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: now) && $0.source == "ring" }) {
                store.stepEntries[idx].steps = latestSteps
            } else {
                let entry = StepEntry(date: now, steps: latestSteps, source: "ring")
                store.stepEntries.append(entry)
            }
        }

        // Update connected ring's last sync date
        connectedRing?.lastSyncDate = now
        lastSyncDate = now

        // Update wearable device in store
        if let ringId = connectedRing?.id,
           let idx = store.wearableDevices.firstIndex(where: { $0.type == .bodySenseRing }) {
            store.wearableDevices[idx].lastSync = now
            store.wearableDevices[idx].batteryLevel = batteryLevel
            store.wearableDevices[idx].isConnected = true
        }

        store.save()
        logger.info("Synced ring data to HealthStore — HR:\(self.latestHeartRate) SpO2:\(self.latestSpO2) Temp:\(self.latestTemperature) Steps:\(self.latestSteps)")
    }

    /// Attempt to reconnect to a previously paired ring on app launch.
    func attemptAutoReconnect() {
        guard centralManager.state == .poweredOn else { return }
        guard let savedUUIDString = UserDefaults.standard.string(forKey: BLEConstants.savedRingUUIDKey),
              let savedUUID = UUID(uuidString: savedUUIDString) else {
            return
        }

        let peripherals = centralManager.retrievePeripherals(withIdentifiers: [savedUUID])
        if let peripheral = peripherals.first {
            connectionState = .reconnecting
            connectedPeripheral = peripheral
            peripheral.delegate = self
            centralManager.connect(peripheral, options: [
                CBConnectPeripheralOptionNotifyOnConnectionKey: true,
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
                CBConnectPeripheralOptionNotifyOnNotificationKey: true
            ])
            logger.info("Attempting auto-reconnect to saved ring: \(savedUUID)")
        } else {
            // Try connected peripherals with our service
            let connected = centralManager.retrieveConnectedPeripherals(withServices: [BLEConstants.serviceUUID])
            if let peripheral = connected.first(where: { $0.identifier == savedUUID }) {
                connectionState = .reconnecting
                connectedPeripheral = peripheral
                peripheral.delegate = self
                centralManager.connect(peripheral, options: nil)
                logger.info("Found already-connected ring, re-establishing: \(savedUUID)")
            }
        }
    }

    // MARK: - Private Helpers

    private func cleanUpConnection() {
        syncTimer?.invalidate()
        syncTimer = nil
        connectionState = .disconnected
        connectedPeripheral = nil
        connectedRing = nil
        batteryLevel = 0
        firmwareVersion = ""
        latestHeartRate = 0
        latestSpO2 = 0
        latestTemperature = 0
        latestSteps = 0
        latestSleepState = .awake
    }

    private func startPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: BLEConstants.syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.syncDataToHealthStore(HealthStore.shared)
            }
        }
    }

    nonisolated private func parseCharacteristic(_ characteristic: CBCharacteristic) {
        guard let data = characteristic.value else { return }

        Task { @MainActor in
            switch characteristic.uuid {
            case BLEConstants.heartRateCharUUID:
                if let byte = data.first {
                    let bpm = Int(byte)
                    if InputValidator.isValidHeartRate(bpm) {
                        self.latestHeartRate = bpm
                        self.logger.debug("Heart rate: \(bpm) bpm")
                    }
                }

            case BLEConstants.spo2CharUUID:
                if let byte = data.first {
                    let spo2 = Int(byte)
                    if (50...100).contains(spo2) {
                        self.latestSpO2 = spo2
                        self.logger.debug("SpO2: \(spo2)%")
                    }
                }

            case BLEConstants.temperatureCharUUID:
                if data.count >= 2 {
                    let raw = data.withUnsafeBytes { $0.load(as: UInt16.self) }
                    let celsius = Double(raw) / 100.0
                    if InputValidator.isValidBodyTemp(celsius) {
                        self.latestTemperature = celsius
                        self.logger.debug("Temperature: \(celsius)C")
                    }
                }

            case BLEConstants.stepsCharUUID:
                if data.count >= 4 {
                    let steps = data.withUnsafeBytes { $0.load(as: UInt32.self) }
                    self.latestSteps = Int(steps)
                    self.logger.debug("Steps: \(steps)")
                }

            case BLEConstants.sleepStateCharUUID:
                if let byte = data.first, let state = SleepState(rawValue: Int(byte)) {
                    self.latestSleepState = state
                    self.logger.debug("Sleep state: \(state.label)")
                }

            case BLEConstants.batteryCharUUID:
                if let byte = data.first {
                    self.batteryLevel = min(Int(byte), 100)
                    self.connectedRing?.batteryLevel = self.batteryLevel
                    self.logger.debug("Battery: \(self.batteryLevel)%")
                }

            case BLEConstants.firmwareCharUUID:
                if let version = String(data: data, encoding: .utf8) {
                    self.firmwareVersion = version
                    self.connectedRing?.firmwareVersion = version
                    self.logger.debug("Firmware: \(version)")
                }

            default:
                break
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BodySenseRingManager: @preconcurrency CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            self.bluetoothState = central.state
            self.logger.info("Bluetooth state: \(central.state.rawValue)")

            switch central.state {
            case .poweredOn:
                self.errorMessage = nil
                self.attemptAutoReconnect()
            case .poweredOff:
                self.errorMessage = "Bluetooth is turned off. Enable it in Settings to use your Ring."
                self.cleanUpConnection()
            case .unauthorized:
                self.errorMessage = "Bluetooth permission denied. Go to Settings > BodySense AI > Bluetooth."
                self.cleanUpConnection()
            case .unsupported:
                self.errorMessage = "This device does not support Bluetooth LE."
                self.cleanUpConnection()
            default:
                break
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let ring = DiscoveredRing(
            id: peripheral.identifier,
            name: peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "BodySense Ring",
            rssi: RSSI.intValue
        )

        Task { @MainActor in
            // Update existing or add new
            if let idx = self.discoveredRings.firstIndex(where: { $0.id == ring.id }) {
                self.discoveredRings[idx] = ring
            } else {
                self.discoveredRings.append(ring)
            }
            self.logger.info("Discovered ring: \(ring.name) RSSI: \(ring.rssi)")
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.connectionState = .connected
            self.errorMessage = nil

            self.connectedRing = ConnectedRing(
                id: peripheral.identifier,
                name: peripheral.name ?? "BodySense Ring",
                firmwareVersion: "",
                batteryLevel: 0,
                lastSyncDate: nil,
                color: nil,
                size: nil
            )

            // Discover our service
            peripheral.discoverServices([BLEConstants.serviceUUID])

            // Start periodic sync timer
            self.startPeriodicSync()

            self.logger.info("Connected to ring: \(peripheral.name ?? "Unknown")")
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        Task { @MainActor in
            self.connectionState = .disconnected
            self.errorMessage = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
            self.connectedPeripheral = nil
            self.logger.error("Failed to connect: \(error?.localizedDescription ?? "Unknown")")
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        Task { @MainActor in
            self.logger.info("Disconnected from ring: \(peripheral.name ?? "Unknown")")

            // If we have a saved ring UUID, attempt automatic reconnection
            if let savedUUID = UserDefaults.standard.string(forKey: BLEConstants.savedRingUUIDKey),
               peripheral.identifier.uuidString == savedUUID {
                self.connectionState = .reconnecting
                self.syncTimer?.invalidate()
                self.syncTimer = nil

                // Attempt reconnect after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if central.state == .poweredOn {
                        central.connect(peripheral, options: [
                            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
                            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
                        ])
                        self.logger.info("Attempting automatic reconnection...")
                    }
                }
            } else {
                self.cleanUpConnection()
            }
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BodySenseRingManager: @preconcurrency CBPeripheralDelegate {

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard error == nil else {
            Task { @MainActor in
                self.errorMessage = "Service discovery failed: \(error!.localizedDescription)"
                self.logger.error("Service discovery error: \(error!.localizedDescription)")
            }
            return
        }

        guard let services = peripheral.services else { return }
        for service in services where service.uuid == BLEConstants.serviceUUID {
            peripheral.discoverCharacteristics([
                BLEConstants.heartRateCharUUID,
                BLEConstants.spo2CharUUID,
                BLEConstants.temperatureCharUUID,
                BLEConstants.stepsCharUUID,
                BLEConstants.sleepStateCharUUID,
                BLEConstants.batteryCharUUID,
                BLEConstants.firmwareCharUUID
            ], for: service)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard error == nil, let characteristics = service.characteristics else {
            Task { @MainActor in
                self.logger.error("Characteristic discovery error: \(error?.localizedDescription ?? "nil")")
            }
            return
        }

        for characteristic in characteristics {
            switch characteristic.uuid {
            case BLEConstants.heartRateCharUUID,
                 BLEConstants.spo2CharUUID,
                 BLEConstants.temperatureCharUUID,
                 BLEConstants.stepsCharUUID,
                 BLEConstants.sleepStateCharUUID,
                 BLEConstants.batteryCharUUID:
                // Subscribe to notifications
                peripheral.setNotifyValue(true, for: characteristic)
                // Also read initial value
                peripheral.readValue(for: characteristic)

            case BLEConstants.firmwareCharUUID:
                // Read-only characteristic
                peripheral.readValue(for: characteristic)

            default:
                break
            }
        }

        Task { @MainActor in
            self.logger.info("Subscribed to \(characteristics.count) characteristics")
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard error == nil else {
            Task { @MainActor in
                self.logger.error("Value update error for \(characteristic.uuid): \(error!.localizedDescription)")
            }
            return
        }
        parseCharacteristic(characteristic)
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error {
            Task { @MainActor in
                self.logger.error("Notification state error for \(characteristic.uuid): \(error.localizedDescription)")
            }
        }
    }
}
