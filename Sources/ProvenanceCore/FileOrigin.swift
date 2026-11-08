import Foundation

/// Where a file came from, as recorded by macOS in extended attributes.
public struct FileOrigin: Sendable, Hashable {
    /// Source URLs from `kMDItemWhereFroms`, typically [download URL, referring page].
    public var whereFroms: [String]
    /// Parsed `com.apple.quarantine` record, if present.
    public var quarantine: QuarantineInfo?

    public init(whereFroms: [String] = [], quarantine: QuarantineInfo? = nil) {
        self.whereFroms = whereFroms
        self.quarantine = quarantine
    }

    /// The host the file was downloaded from, if known.
    public var sourceHost: String? {
        whereFroms.lazy.compactMap { URL(string: $0)?.host() }.first
    }
}

/// The `com.apple.quarantine` xattr: `flags;hexTimestamp;agentName;uuid`.
public struct QuarantineInfo: Sendable, Hashable {
    public var flags: String
    public var date: Date?
    public var agent: String?
    public var eventID: String?

    /// Parses the raw quarantine string. Returns nil if it is malformed.
    public init?(raw: String) {
        let parts = raw.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 2, !parts[0].isEmpty else { return nil }
        flags = parts[0]
        date = UInt64(parts[1], radix: 16).map { Date(timeIntervalSince1970: TimeInterval($0)) }
        agent = parts.count > 2 && !parts[2].isEmpty ? parts[2] : nil
        eventID = parts.count > 3 && !parts[3].isEmpty ? parts[3] : nil
    }
}

public enum OriginReader {
    static let whereFromsKey = "com.apple.metadata:kMDItemWhereFroms"
    static let quarantineKey = "com.apple.quarantine"

    /// Reads the origin attributes for the file at `url`. Missing attributes yield empty values.
    public static func read(_ url: URL) -> FileOrigin {
        var origin = FileOrigin()
        if let data = ExtendedAttributes.get(quarantineKey, at: url),
            let raw = String(data: data, encoding: .utf8)
        {
            origin.quarantine = QuarantineInfo(raw: raw)
        }
        if let data = ExtendedAttributes.get(whereFromsKey, at: url),
            let list = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String]
        {
            origin.whereFroms = list
        }
        return origin
    }
}

/// Minimal wrapper around getxattr/setxattr.
public enum ExtendedAttributes {
    public static func get(_ name: String, at url: URL) -> Data? {
        url.withUnsafeFileSystemRepresentation { path -> Data? in
            guard let path else { return nil }
            let size = getxattr(path, name, nil, 0, 0, 0)
            guard size > 0 else { return nil }
            var data = Data(count: size)
            let read = data.withUnsafeMutableBytes { getxattr(path, name, $0.baseAddress, size, 0, 0) }
            return read == size ? data : nil
        }
    }

    @discardableResult
    public static func set(_ name: String, _ data: Data, at url: URL) -> Bool {
        url.withUnsafeFileSystemRepresentation { path -> Bool in
            guard let path else { return false }
            return data.withUnsafeBytes { setxattr(path, name, $0.baseAddress, data.count, 0, 0) } == 0
        }
    }
}
