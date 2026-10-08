import SwiftUI

struct DiscoveryView: View {
    @StateObject private var discovery = AppleTVDiscovery()

    var body: some View {
        List {
            Section {
                Text(discovery.status)
                Button("Scan again") { discovery.start() }
            }
            Section("Discovered services") {
                if discovery.devices.isEmpty {
                    Text("No Apple TV services found yet. Ensure both devices are on the same Wi-Fi network.")
                        .foregroundStyle(.secondary)
                }
                ForEach(discovery.devices) { device in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name).font(.headline)
                        Text(device.service).font(.caption)
                        Text(device.endpoint).font(.caption2).foregroundStyle(.secondary)
                        NavigationLink("Inspect connection") { DeviceProbeView(device: device) }
                    }
                }
            }
            Section {
                Text("Discovery only: pairing and IPA installation are not implemented yet.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Find Apple TV")
        .onAppear { discovery.start() }
        .onDisappear { discovery.stop() }
    }
}
