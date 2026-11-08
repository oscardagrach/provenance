import Foundation

@testable import ProvenanceCore

/// A fresh, empty directory under the system temp dir. Callers remove it with `defer`.
func makeTempDir() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appending(path: "prov-\(UUID())", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@discardableResult
func makeFile(_ name: String, in dir: URL, bytes: Int = 1) throws -> URL {
    let url = dir.appending(path: name)
    try Data(repeating: 0x41, count: bytes).write(to: url)
    return url
}

/// Writes the same xattrs a browser would.
func setOrigin(of url: URL, whereFroms: [String] = [], agent: String? = nil) throws {
    if !whereFroms.isEmpty {
        let plist = try PropertyListSerialization.data(fromPropertyList: whereFroms, format: .binary, options: 0)
        ExtendedAttributes.set(OriginReader.whereFromsKey, plist, at: url)
    }
    if let agent {
        ExtendedAttributes.set(OriginReader.quarantineKey, Data("0083;65f1a2b3;\(agent);".utf8), at: url)
    }
}

func origin(_ whereFroms: [String] = [], agent: String? = nil) -> FileOrigin {
    FileOrigin(whereFroms: whereFroms, quarantine: agent.flatMap { QuarantineInfo(raw: "0083;65f1a2b3;\($0);") })
}
