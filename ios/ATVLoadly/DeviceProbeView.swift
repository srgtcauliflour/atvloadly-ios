import SwiftUI
import Network

struct DeviceProbeView: View {
    let device: AppleTVDiscovery.Device
    @State private var state = "Not connected"
    @State private var connection: NWConnection?
    @State private var connectionPath = "Not connected"
    @State private var timeoutTask: Task<Void, Never>?
    @State private var resolvedEndpoint = "Not resolved"
    @State private var resolver = BonjourEndpointResolver()

    var body: some View {
        Form {
            Section("Discovered device") {
                LabeledContent("Name", value: device.name)
                LabeledContent("Service", value: device.service)
                Text(device.endpoint).font(.caption).textSelection(.enabled)
                LabeledContent("Interface", value: device.interfaceName.isEmpty ? "Unspecified" : device.interfaceName)
                if !device.txtRecords.isEmpty {
                    ForEach(device.txtRecords, id: \.self) { entry in
                        Text(entry).font(.caption2).textSelection(.enabled)
                    }
                }
            }
            Section("Bonjour resolution") {
                Text(resolvedEndpoint).font(.footnote).textSelection(.enabled)
                Button("Resolve host and port") { resolveEndpoint() }
            }
            Section("TCP connection") {
                Text(state)
                Text(connectionPath).font(.footnote).textSelection(.enabled)
                Button("Test connection") { probe() }
            }
            Section {
                Text("This is a transport diagnostic, not a pairing request. A successful TCP connection does not grant installation access.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Device diagnostics")
        .onDisappear {
            resolver.cancel()
            timeoutTask?.cancel()
            connection?.cancel()
            connection = nil
        }
    }

    private func resolveEndpoint() {
        resolvedEndpoint = "Resolving…"
        resolver.resolve(name: device.bonjourName, type: device.service, domain: device.bonjourDomain) { result in
            DispatchQueue.main.async { resolvedEndpoint = result }
        }
    }

    private func probe() {
        timeoutTask?.cancel()
        connection?.cancel()
        let endpoint = NWEndpoint.service(name: device.bonjourName, type: device.service, domain: device.bonjourDomain, interface: nil)
        let next = NWConnection(to: endpoint, using: .tcp)
        connection = next
        state = "Connecting…"
        connectionPath = "Awaiting network path"
        next.stateUpdateHandler = { status in
            DispatchQueue.main.async {
                guard connection === next else { return }
                switch status {
                case .ready:
                    timeoutTask?.cancel()
                    state = "TCP connection established"
                    if let path = next.currentPath {
                        let interfaces = path.availableInterfaces.map { "\($0.name) (\($0.type))" }.joined(separator: ", ")
                        connectionPath = "Path: \(path.status)\nInterfaces: \(interfaces)\nUses Wi-Fi: \(path.usesInterfaceType(.wifi))\nUses cellular: \(path.usesInterfaceType(.cellular))"
                    } else {
                        connectionPath = "No connection path available"
                    }
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
            connectionPath = "No established network path"
            connection = nil
            next.cancel()
        }
    }
}
