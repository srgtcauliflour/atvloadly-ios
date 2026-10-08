import Foundation
import Network

@MainActor
final class AppleTVDiscovery: ObservableObject {
    struct Device: Identifiable, Hashable {
        let id: String
        let name: String
        let service: String
        let endpoint: String
    }

    @Published private(set) var devices: [Device] = []
    @Published private(set) var status = "Not scanning"
    private var browsers: [NWBrowser] = []

    func start() {
        stop()
        status = "Searching local network…"
        for type in ["_apple-mobdev2._tcp", "_companion-link._tcp", "_airplay._tcp"] {
            let browser = NWBrowser(for: .bonjour(type: type, domain: "local."), using: .tcp)
            browser.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    guard let self else { return }
                    if case .failed(let error) = state {
                        if case .dns(let code) = error, code == -65555 {
                            self.status = "Local network access denied. Enable ATVLoadly under Settings → Privacy & Security → Local Network, then scan again."
                        } else {
                            self.status = "Discovery failed (\(error.localizedDescription)). Check Wi-Fi and local network permissions."
                        }
                    }
                }
            }
            browser.browseResultsChangedHandler = { [weak self] _, _ in
                Task { @MainActor in self?.refresh() }
            }
            browsers.append(browser)
            browser.start(queue: .main)
        }
    }

    private func refresh() {
        var found: [String: Device] = [:]
        for browser in browsers {
            for result in browser.browseResults {
                guard case let .service(name, type, domain, _) = result.endpoint else { continue }
                let key = "\(name)|\(type)|\(domain)"
                found[key] = Device(id: key, name: name, service: type, endpoint: String(describing: result.endpoint))
            }
        }
        devices = found.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        status = "Found \(devices.count) services"
    }

    func stop() {
        browsers.forEach { $0.cancel() }
        browsers.removeAll()
        devices = []
        status = "Not scanning"
    }
}
