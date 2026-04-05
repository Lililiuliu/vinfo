import AppKit
import SwiftUI

@main
struct VinfoBarApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        // Empty Settings scene - we use custom window
        Settings {
            EmptyView()
        }
    }
}