import Foundation
import CoreBluetooth

/// Shared Bluetooth UUIDs so the host and remote can find each other.
public enum BluetoothTransportService {
    public static let serviceUUID = CBUUID(string: "2D0E8F4A-437D-46DE-88D3-4F0B61C8C91E")
    public static let commandCharacteristicUUID = CBUUID(string: "1F3C2D8E-95BC-4EEB-A66B-3F4E3D4B5610")

    /// Convenience helper to encode commands into data.
    public static func encode(command: TransportCommand) -> Data {
        (command.rawValue + "\n").data(using: .utf8) ?? Data()
    }

    /// Convenience helper to decode commands from data.
    public static func decodeCommand(from data: Data) -> TransportCommand? {
        guard let value = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        return TransportCommand(rawValue: value)
    }
}
