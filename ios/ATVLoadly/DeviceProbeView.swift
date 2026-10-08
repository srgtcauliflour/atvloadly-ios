import SwiftUI
import Network

struct DeviceProbeView: View {
    let device: AppleTVDiscovery.Device
    @State private var state = "Not connected"
    @State private var connection: NWConnection?

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
        .onDisappear { connection?.cancel(); connection = nil }
    }

    private func probe() {
        connection?.cancel()
        let endpoint = NWEndpoint.service(name: device.bonjourName, type: device.service, domain: device.bonjourDomain, interface: nil)
        let next = NWConnection(to: endpoint, using: .tcp)
        connection = next
        state = "Connecting…"
        next.stateUpdateHandler = { status in
            DispatchQueue.main.async {
                guard connection === next else { return }
                switch status {
                case .ready: state = "TCP connection established"
                case .failed(let error): state = "Connection failed: \(error.localizedDescription)"
                case .waiting(let error): state = "Waiting: \(error.localizedDescription)"
                case .cancelled: state = "Disconnected"
                default: break
                }
            }
        }
        next.start(queue: .main)
    }
}
