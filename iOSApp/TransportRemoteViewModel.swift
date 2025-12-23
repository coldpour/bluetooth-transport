import Foundation
import CoreBluetooth
import SwiftUI

/// iOS side: acts as a central, scans for the macOS host, and writes commands.
final class TransportRemoteViewModel: NSObject, ObservableObject {
    @Published var status: String = "Scanning..."
    @Published var isConnected: Bool = false

    private let central: CBCentralManager
    private var hostPeripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?

    override init() {
        central = CBCentralManager(delegate: nil, queue: .main)
        super.init()
        central.delegate = self
    }

    func send(_ command: TransportCommand) {
        guard let characteristic = commandCharacteristic, let peripheral = hostPeripheral else {
            status = "Not connected"
            return
        }
        let data = BluetoothTransportService.encode(command: command)
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

extension TransportRemoteViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            status = "Scanning for host..."
            central.scanForPeripherals(withServices: [BluetoothTransportService.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        default:
            status = "Bluetooth unavailable"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        hostPeripheral = peripheral
        status = "Connecting to host..."
        central.stopScan()
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        status = "Discovering services..."
        peripheral.delegate = self
        peripheral.discoverServices([BluetoothTransportService.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        status = "Failed to connect"
    }
}

extension TransportRemoteViewModel: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let service = peripheral.services?.first(where: { $0.uuid == BluetoothTransportService.serviceUUID }) {
            status = "Discovering characteristics..."
            peripheral.discoverCharacteristics([BluetoothTransportService.commandCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        commandCharacteristic = service.characteristics?.first(where: { $0.uuid == BluetoothTransportService.commandCharacteristicUUID })
        isConnected = commandCharacteristic != nil
        status = isConnected ? "Ready" : "Characteristic missing"
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            status = "Send failed: \(error.localizedDescription)"
        }
    }
}
