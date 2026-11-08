import ProvenanceCore
import SwiftUI

@main
struct ProvenanceApp: App {
    var body: some Scene {
        MenuBarExtra("Provenance", systemImage: "tray.and.arrow.down") {
            Text("Provenance — scaffold")
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
