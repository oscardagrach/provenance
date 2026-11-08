import Foundation
import ProvenanceCore

let usage = """
    usage: provenance [list|groups|watch] [directory]

      list    every item with its source and size (default)
      groups  items grouped by where they came from
      watch   print changes as they happen (Ctrl-C to stop)

    directory defaults to ~/Downloads
    """

/// Unbuffered, so `watch` output appears immediately even when piped.
func emit(_ line: String = "", to handle: FileHandle = .standardOutput) {
    handle.write(Data((line + "\n").utf8))
}

func fail(_ message: String, code: Int32 = 1) -> Never {
    emit(message, to: .standardError)
    exit(code)
}

func formatSize(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
}

// MARK: - Arguments

var args = Array(CommandLine.arguments.dropFirst())
if args.contains(where: { ["-h", "--help", "help"].contains($0) }) {
    emit(usage)
    exit(0)
}
let command = ["list", "groups", "watch"].contains(args.first ?? "") ? args.removeFirst() : "list"
guard args.count <= 1 else { fail(usage, code: 64) }
let directory =
    args.first.map { URL(filePath: $0, directoryHint: .isDirectory) }
    ?? FileManager.default.homeDirectoryForCurrentUser.appending(path: "Downloads", directoryHint: .isDirectory)

// MARK: - Run

var scanner = DownloadScanner(directory: directory)
var index = DownloadIndex()
do {
    index.reconcile(with: try scanner.scan())
} catch {
    fail("provenance: can't read \(directory.path): \(error.localizedDescription)")
}

switch command {
case "groups":
    for group in index.groups() {
        emit("\(group.source.displayName)  (\(group.items.count), \(formatSize(group.totalSize)))")
        for item in group.items { emit("    \(item.name)") }
    }

case "watch":
    emit("Watching \(directory.path) (\(index.items.count) items). Ctrl-C to stop.")
    let watcher = DirectoryWatcher(directory: directory)
    for await _ in watcher.changes {
        guard let scanned = try? scanner.scan() else { continue }
        let diff = index.reconcile(with: scanned)
        for item in diff.added { emit("+ \(item.name)  [\(item.source.displayName)]") }
        for item in diff.removed { emit("- \(item.name)") }
        for item in diff.modified { emit("~ \(item.name)") }
    }

default:
    for item in index.items.values.sorted(by: { $0.name.localizedStandardCompare($1.name) == .orderedAscending }) {
        emit("\(item.name)\t\(item.source.displayName)\t\(formatSize(item.size))")
    }
}
