# Bluetooth Transport

Control Cubase from your phone over Bluetooth. The repository contains a minimal SwiftUI remote for iOS and a macOS host that forwards transport commands to Cubase via AppleScript keystrokes.

## Features
- Playback start/stop
- Recording start/stop
- Seek the playhead forward/back one measure

## Project layout
- `Shared/` – Bluetooth UUIDs and `TransportCommand` enum shared by both apps.
- `iOSApp/` – iOS SwiftUI app that scans for the host and sends transport commands as a Bluetooth central.
- `macOSApp/` – macOS SwiftUI app that advertises a Bluetooth peripheral, receives commands, and triggers Cubase shortcuts.

## Building
1. Open the repository in Xcode and create two targets (iOS App and macOS App). Add the corresponding source files in `iOSApp/` and `macOSApp/`, and include the shared files under both targets.
2. Set the deployment targets to iOS 16+ and macOS 13+.
3. Ensure the apps have the Bluetooth capability enabled in Signing & Capabilities.

## Usage
1. Run the macOS host app. Click **Start Advertising** to make it discoverable. Keep Cubase focused so AppleScript keystrokes land in the DAW. Update key codes in `CubaseController` if you use custom shortcuts.
2. Launch the iOS app. It will scan for the host service and connect automatically. Once connected, tap the buttons to play/stop, record, or nudge the playhead by one measure.
3. Adjust the service/characteristic UUIDs in `BluetoothTransportService` if you need to isolate communication between multiple rigs.

## Notes
- AppleScript keystrokes mimic the default Cubase shortcuts (space for play/stop, F12 for record, and Option+Arrow for measure navigation). If your shortcuts differ, change the scripts in `CubaseController`.
- For best reliability, keep both devices on the same desk for the first pairing so the iOS app can bond with the host. After pairing, Bluetooth connections can be re-established across the room.
