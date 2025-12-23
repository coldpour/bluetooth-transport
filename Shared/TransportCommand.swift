import Foundation

/// Transport commands that can be sent between devices.
public enum TransportCommand: String, CaseIterable, Codable {
    case playPause
    case record
    case seekForward
    case seekBackward
}

public extension TransportCommand {
    /// Human-readable label for UI buttons.
    var title: String {
        switch self {
        case .playPause:
            return "Play / Stop"
        case .record:
            return "Record"
        case .seekForward:
            return "+1 Measure"
        case .seekBackward:
            return "-1 Measure"
        }
    }
}
