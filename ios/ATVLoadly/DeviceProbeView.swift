import SwiftUI
import Network

struct DeviceProbeView: View {
    let device: AppleTVDiscovery.Device
    @State private var state = "Not connected"
    @State private var connection: NWConnection?
    @State private var timeoutTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section("Discovered device") {
                LabeledContent("Name", value: device.name)
                LabeledContent("Service", value: device.service)
                Text(device.endpoint).font(.caption).textSelection(.enabled)
            }
            Section("TCP connection") {
                Text(state)
                Button("Test connection") { probe() }
            }
            Section {
                Text("This is a transport diagnostic, not a pairing request. A successful TCP connection does not grant installation access.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Device diagnostics")
        .onDisappear {
            timeoutTask?.cancel()
            connection?.cancel()
            connection = nil
        }
    }

    private func probe() {
        timeoutTask?.cancel()
        connection?.cancel()
        let endpoint = NWEndpoint.service(name: device.bonjourName, type: device.service, domain: device.bonjourDomain, interface: nil)
        let next = NWConnection(to: endpoint, using: .tcp)
        connection = next
        state = "Connecting…"
        next.stateUpdateHandler = { status in
            DispatchQueue.main.async {
                guard connection === next else { return }
                switch status {
                case .ready:
                    timeoutTask?.cancel()
                    state = "TCP connection established"
                case .failed(let error):
                    timeoutTask?.cancel()
                    state = "Connection failed: \(error.localizedDescription)"
                case .waiting(let error): state = "Waiting: \(error.localizedDescription)"
                case .cancelled: state = "Disconnected"
                default: break
                }
            }
        }
        next.start(queue: .main)
        timeoutTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard !Task.isCancelled, connection === next else { return }
            if case .ready = next.state { return }
            state = "Connection timed out after 10 seconds. Device may be offline or Bonjour data cached."
            connection = nil
            next.cancel()
        }
    }
}
