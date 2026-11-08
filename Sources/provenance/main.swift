import Foundation
import ProvenanceCore

// Usage: provenance [path ...]   (defaults to ~/Downloads)
let args = CommandLine.arguments.dropFirst()
let fm = FileManager.default
let targets: [URL] =
    args.isEmpty
    ? ((try? fm.contentsOfDirectory(
        at: fm.homeDirectoryForCurrentUser.appending(path: "Downloads"),
        includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? [])
    : args.map { URL(filePath: $0) }

for url in targets.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
    let origin = OriginReader.read(url)
    let host = origin.sourceHost ?? "—"
    let agent = origin.quarantine?.agent ?? "—"
    print("\(url.lastPathComponent)\t\(host)\t\(agent)")
}
