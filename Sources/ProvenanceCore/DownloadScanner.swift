import Foundation

/// Lists the top level of a folder as `DownloadItem`s.
///
/// Folder sizes are expensive to measure, so they are cached and reused while the folder's
/// modification date is unchanged. A folder's mtime only changes when its direct children
/// change, so edits deep inside an extracted folder can leave its size stale until the next
/// direct change — acceptable for a Downloads folder. Origins are always re-read (two xattr
/// reads), since a browser can set them after the file first appears.
public struct DownloadScanner: Sendable {
    /// In-progress downloads: Chrome, Safari (a bundle), Firefox, and generic partials.
    public static let partialExtensions: Set<String> = ["crdownload", "download", "part", "partial"]

    public let directory: URL
    private var folderSizes: [URL: CachedSize] = [:]
    /// Number of recursive folder measurements performed; exposed for tests.
    private(set) var folderMeasurements = 0

    private struct CachedSize: Sendable {
        var modified: Date
        var size: Int64
    }

    public init(directory: URL) {
        self.directory = directory.standardizedFileURL
    }

    public mutating func scan() throws -> [DownloadItem] {
        let children = try FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: Array(DownloadItem.resourceKeys), options: .skipsHiddenFiles)

        var items: [DownloadItem] = []
        var nextSizes: [URL: CachedSize] = [:]
        for url in children where !Self.partialExtensions.contains(url.pathExtension.lowercased()) {
            // A file can vanish between listing and reading; skip it, the next scan settles.
            guard let values = try? url.resourceValues(forKeys: DownloadItem.resourceKeys) else { continue }

            var size: Int64
            if values.isDirectory == true {
                let modified = values.contentModificationDate ?? .distantPast
                if let cached = folderSizes[url], cached.modified == modified {
                    size = cached.size
                } else {
                    size = DownloadItem.measureDirectory(url)
                    folderMeasurements += 1
                }
                nextSizes[url] = CachedSize(modified: modified, size: size)
            } else {
                size = DownloadItem.size(of: url, values: values)
            }
            items.append(DownloadItem(url: url, values: values, size: size))
        }
        folderSizes = nextSizes  // drops entries for folders that are gone
        return items
    }
}
