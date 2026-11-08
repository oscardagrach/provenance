import Foundation
import UniformTypeIdentifiers

/// One top-level entry in the watched folder. Folders and bundles count as a single item.
public struct DownloadItem: Sendable, Hashable, Identifiable {
    public let url: URL
    public var name: String
    /// Allocated bytes on disk; recursive for folders and bundles.
    public var size: Int64
    public var dateAdded: Date
    public var modified: Date
    public var contentType: UTType
    public var isDirectory: Bool
    public var origin: FileOrigin

    public var id: URL { url }
    public var source: Source { Source(origin: origin) }

    public init(
        url: URL, name: String? = nil, size: Int64 = 0, dateAdded: Date = .now, modified: Date = .now,
        contentType: UTType = .data, isDirectory: Bool = false, origin: FileOrigin = FileOrigin()
    ) {
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.size = size
        self.dateAdded = dateAdded
        self.modified = modified
        self.contentType = contentType
        self.isDirectory = isDirectory
        self.origin = origin
    }

    /// Loads one item from disk, measuring folders recursively.
    public static func load(_ url: URL) throws -> DownloadItem {
        let values = try url.resourceValues(forKeys: resourceKeys)
        return DownloadItem(url: url, values: values, size: size(of: url, values: values))
    }

    // MARK: - Internals shared with DownloadScanner

    static let resourceKeys: Set<URLResourceKey> = [
        .nameKey, .isDirectoryKey, .addedToDirectoryDateKey, .creationDateKey,
        .contentModificationDateKey, .contentTypeKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey,
    ]

    init(url: URL, values: URLResourceValues, size: Int64) {
        let modified = values.contentModificationDate ?? .distantPast
        self.init(
            url: url,
            name: values.name,
            size: size,
            dateAdded: values.addedToDirectoryDate ?? values.creationDate ?? modified,
            modified: modified,
            contentType: values.contentType ?? .data,
            isDirectory: values.isDirectory ?? false,
            origin: OriginReader.read(url)
        )
    }

    static func size(of url: URL, values: URLResourceValues) -> Int64 {
        if values.isDirectory == true { return measureDirectory(url) }
        return Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
    }

    /// Sum of allocated sizes of every file inside `url`, including hidden files (bundles
    /// hide most of their content).
    static func measureDirectory(_ url: URL) -> Int64 {
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isRegularFileKey]
        guard let walker = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys) else {
            return 0
        }
        var total: Int64 = 0
        for case let file as URL in walker {
            guard let v = try? file.resourceValues(forKeys: Set(keys)), v.isRegularFile == true else { continue }
            total += Int64(v.totalFileAllocatedSize ?? 0)
        }
        return total
    }
}
