import Foundation

/// Resolves a Bonjour service to its advertised host and TCP port.
/// This does not authenticate the remote host or establish a pairing session.
final class BonjourEndpointResolver: NSObject, NetServiceDelegate {
    private var service: NetService?
    private var completion: ((String) -> Void)?

    func resolve(name: String, type: String, domain: String, completion: @escaping (String) -> Void) {
        cancel()
        self.completion = completion
        let next = NetService(domain: domain, type: type, name: name)
        service = next
        next.delegate = self
        next.resolve(withTimeout: 8)
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        guard sender === service else { return }
        let host = sender.hostName ?? "Unknown host"
        let port = sender.port
        finish("Host: \(host)\nPort: \(port)")
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        guard sender === service else { return }
        finish("Resolution failed: \(errorDict)")
    }

    private func finish(_ result: String) {
        let callback = completion
        completion = nil
        service?.stop()
        service = nil
        callback?(result)
    }

    func cancel() {
        completion = nil
        service?.stop()
        service = nil
    }
}
