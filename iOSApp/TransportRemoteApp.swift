import SwiftUI

@main
struct TransportRemoteApp: App {
    @StateObject private var viewModel = TransportRemoteViewModel()

    var body: some Scene {
        WindowGroup {
            TransportRemoteView()
                .environmentObject(viewModel)
        }
    }
}

struct TransportRemoteView: View {
    @EnvironmentObject private var viewModel: TransportRemoteViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(viewModel.status)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    transportButton(.playPause, color: .green)
                    transportButton(.record, color: .red)
                }

                HStack(spacing: 12) {
                    transportButton(.seekBackward, color: .blue)
                    transportButton(.seekForward, color: .blue)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Cubase Remote")
        }
        .disabled(!viewModel.isConnected)
        .overlay(alignment: .bottom) {
            if !viewModel.isConnected {
                Text("Waiting for Bluetooth host...")
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow.opacity(0.2))
            }
        }
    }

    private func transportButton(_ command: TransportCommand, color: Color) -> some View {
        Button(action: { viewModel.send(command) }) {
            Text(command.title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(color.opacity(viewModel.isConnected ? 0.2 : 0.05))
                .foregroundColor(color)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.4), lineWidth: 1)
        )
    }
}
