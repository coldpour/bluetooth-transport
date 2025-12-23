import SwiftUI

@main
struct TransportHostApp: App {
    @StateObject private var viewModel = TransportHostViewModel()

    var body: some Scene {
        WindowGroup {
            TransportHostView()
                .environmentObject(viewModel)
        }
    }
}

struct TransportHostView: View {
    @EnvironmentObject private var viewModel: TransportHostViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bluetooth Host")
                .font(.title2)

            Text(viewModel.stateDescription)
                .font(.headline)

            HStack {
                Button("Start Advertising") { viewModel.startAdvertising() }
                Button("Stop") { viewModel.stopAdvertising() }
            }

            if let last = viewModel.lastCommand {
                Text("Last command: \(last.title)")
            } else {
                Text("No commands yet")
            }

            Text("Make sure Cubase is frontmost so AppleScript keystrokes land in the DAW.")
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .frame(minWidth: 360, minHeight: 240)
    }
}
