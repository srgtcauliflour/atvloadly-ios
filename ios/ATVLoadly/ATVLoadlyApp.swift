import SwiftUI

@main
struct ATVLoadlyApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var serviceURL = ""
    @State private var showService = false

    var body: some View {
        NavigationStack {
            Form {
                Section("ATVLoadly server") {
                    TextField("http://192.168.1.10:5533", text: $serviceURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    Button("Connect") { showService = true }
                        .disabled(URL(string: serviceURL)?.host == nil)
                }
                Section {
                    Text("Initial iOS bootstrap: connects to an existing ATVLoadly server on your local network. On-device pairing, signing and installation are not yet implemented.")
                }
            }
            .navigationTitle("ATVLoadly")
            .navigationDestination(isPresented: $showService) {
                if let url = URL(string: serviceURL) { ServiceView(url: url) }
            }
        }
    }
}

import WebKit

struct ServiceView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.load(URLRequest(url: url))
        return view
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
