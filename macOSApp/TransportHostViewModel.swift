import Foundation
import CoreBluetooth
import Combine
import OSLog
#if os(macOS)
import AppKit
#endif

/// macOS side: acts as a peripheral that advertises a characteristic for commands.
final class TransportHostViewModel: NSObject, ObservableObject {
    @Published var stateDescription: String = "Idle"
    @Published var lastCommand: TransportCommand?

    private let peripheralManager: CBPeripheralManager
    private var commandCharacteristic: CBMutableCharacteristic?
    private var subscriptions = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "BluetoothTransport", category: "host")

    override init() {
        peripheralManager = CBPeripheralManager(delegate: nil, queue: .main)
        super.init()
        peripheralManager.delegate = self
    }

    func startAdvertising() {
        guard peripheralManager.state == .poweredOn else {
            stateDescription = "Bluetooth not powered on"
            return
        }

        let characteristic = CBMutableCharacteristic(
            type: BluetoothTransportService.commandCharacteristicUUID,
            properties: [.write, .writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )
        let service = CBMutableService(type: BluetoothTransportService.serviceUUID, primary: true)
        service.characteristics = [characteristic]

        commandCharacteristic = characteristic
        peripheralManager.removeAllServices()
        peripheralManager.add(service)
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [BluetoothTransportService.serviceUUID],
            CBAdvertisementDataLocalNameKey: "Cubase Remote Host"
        ])
        stateDescription = "Advertising for remotes..."
    }

    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        stateDescription = "Advertising stopped"
    }

    private func handle(command: TransportCommand) {
        lastCommand = command
        logger.info("Received command: \(command.rawValue)")
        #if os(macOS)
        CubaseController().perform(command: command)
        #endif
    }
}

extension TransportHostViewModel: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            stateDescription = "Ready to advertise"
        case .poweredOff:
            stateDescription = "Bluetooth off"
        case .resetting:
            stateDescription = "Resetting"
        case .unauthorized:
            stateDescription = "Unauthorized"
        case .unsupported:
            stateDescription = "Unsupported"
        case .unknown:
            fallthrough
        @unknown default:
            stateDescription = "Unknown"
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        requests.forEach { request in
            guard request.characteristic.uuid == BluetoothTransportService.commandCharacteristicUUID, let value = request.value else { return }
            peripheral.respond(to: request, withResult: .success)
            if let command = BluetoothTransportService.decodeCommand(from: value) {
                handle(command: command)
            }
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            stateDescription = "Failed to add service: \(error.localizedDescription)"
        }
    }
}

#if os(macOS)
/// Minimal Cubase control via AppleScript keystrokes.
/// Adjust the key mappings to match your Cubase transport shortcuts.
struct CubaseController {
    func perform(command: TransportCommand) {
        let script: String
        switch command {
        case .playPause:
            script = "tell application \"System Events\" to keystroke space"
        case .record:
            // Default Cubase record key is * on numeric keypad; map to F12 if customized
            script = "tell application \"System Events\" to key code 111" // F12
        case .seekForward:
            script = "tell application \"System Events\" to key code 124 using option down" // -> with option for bar step
        case .seekBackward:
            script = "tell application \"System Events\" to key code 123 using option down" // <- with option
        }
        runAppleScript(script)
    }

    private func runAppleScript(_ script: String) {
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                Logger(subsystem: "BluetoothTransport", category: "host").error("AppleScript failed: \(String(describing: error))")
            }
        }
    }
}
#endif
