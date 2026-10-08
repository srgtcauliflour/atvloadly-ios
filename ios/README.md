# ATVLoadly iPhone bootstrap

This first milestone compiles a native SwiftUI iPhone shell that connects to an **existing** ATVLoadly Linux server. It does not run the Linux backend on iOS or independently pair/install apps yet. The unsigned IPA artifact is for CI verification only and must be signed with an appropriate iOS provisioning profile before device installation.

Run the **iOS build** GitHub Actions workflow to build. The workflow uses XcodeGen and does not require a checked-in Xcode project.

Next milestone: native Bonjour discovery and Apple TV pairing, followed by porting signing and installation protocols without requiring a Linux server.
