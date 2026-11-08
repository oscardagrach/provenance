import Foundation

/// What changed between two scans.
public struct IndexDiff: Sendable, Equatable {
    public var added: [DownloadItem] = []
    public var removed: [DownloadItem] = []
    public var modified: [DownloadItem] = []

    public var isEmpty: Bool { added.isEmpty && removed.isEmpty && modified.isEmpty }
}

/// Items that share a `Source`, newest first.
public struct SourceGroup: Sendable, Equatable, Identifiable {
    public let source: Source
    public let items: [DownloadItem]

    public var id: Source { source }
    public var totalSize: Int64 { items.reduce(0) { $0 + $1.size } }
    public var latest: Date { items.first?.dateAdded ?? .distantPast }
}

/// The current set of items. Pure value type: feed it scans, get diffs and groups.
public struct DownloadIndex: Sendable {
    public private(set) var items: [URL: DownloadItem] = [:]

    public init() {}

    /// Replaces the contents with `scanned` and reports what changed. Diff arrays are sorted
    /// by name so output is deterministic.
    @discardableResult
    public mutating func reconcile(with scanned: [DownloadItem]) -> IndexDiff {
        let next = Dictionary(scanned.map { ($0.url, $0) }, uniquingKeysWith: { _, last in last })
        var diff = IndexDiff()
        for (url, item) in next {
            if let old = items[url] {
                if old != item { diff.modified.append(item) }
            } else {
                diff.added.append(item)
            }
        }
        for (url, old) in items where next[url] == nil { diff.removed.append(old) }
        items = next

        let byName: (DownloadItem, DownloadItem) -> Bool = { $0.name < $1.name }
        diff.added.sort(by: byName)
        diff.removed.sort(by: byName)
        diff.modified.sort(by: byName)
        return diff
    }

    /// Groups by source. Groups are ordered by their most recently added item; items within
    /// a group are newest first.
    public func groups() -> [SourceGroup] {
        Dictionary(grouping: items.values, by: \.source)
            .map { source, items in
                SourceGroup(
                    source: source,
                    items: items.sorted { ($0.dateAdded, $1.name) > ($1.dateAdded, $0.name) })
            }
            .sorted { $0.latest != $1.latest ? $0.latest > $1.latest : $0.source < $1.source }
    }
}
