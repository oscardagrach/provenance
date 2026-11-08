import Foundation
import Testing

@testable import ProvenanceCore

@Suite struct DownloadIndexTests {
    let dir = URL(filePath: "/tmp/fake-downloads", directoryHint: .isDirectory)

    func item(_ name: String, day: Int, size: Int64 = 1, _ origin: FileOrigin = FileOrigin()) -> DownloadItem {
        let date = Date(timeIntervalSince1970: TimeInterval(day) * 86_400)
        return DownloadItem(url: dir.appending(path: name), size: size, dateAdded: date, modified: date, origin: origin)
    }

    @Test func firstReconcileAddsEverything() {
        var index = DownloadIndex()
        let diff = index.reconcile(with: [item("b", day: 1), item("a", day: 2)])
        #expect(diff.added.map(\.name) == ["a", "b"])
        #expect(diff.removed.isEmpty && diff.modified.isEmpty)
    }

    @Test func reportsAddedRemovedAndModified() {
        var index = DownloadIndex()
        index.reconcile(with: [item("keep", day: 1), item("change", day: 1), item("drop", day: 1)])
        let diff = index.reconcile(with: [item("keep", day: 1), item("change", day: 1, size: 99), item("new", day: 2)])
        #expect(diff.added.map(\.name) == ["new"])
        #expect(diff.removed.map(\.name) == ["drop"])
        #expect(diff.modified.map(\.name) == ["change"])
        #expect(index.items.count == 3)
    }

    @Test func unchangedScanIsEmptyDiff() {
        var index = DownloadIndex()
        let items = [item("a", day: 1), item("b", day: 2)]
        index.reconcile(with: items)
        #expect(index.reconcile(with: items).isEmpty)
    }

    @Test func groupsBySourceNewestFirst() {
        var index = DownloadIndex()
        let gmail = origin(["https://mail-attachment.googleusercontent.com/x", "https://mail.google.com/"])
        index.reconcile(with: [
            item("old-mail.pdf", day: 1, size: 10, gmail),
            item("new-mail.pdf", day: 5, size: 5, gmail),
            item("airdrop.heic", day: 3, origin(agent: "sharingd")),
            item("mystery", day: 4),
        ])
        let groups = index.groups()
        #expect(groups.map(\.source.displayName) == ["Gmail", "Unknown origin", "AirDrop"])
        #expect(groups[0].items.map(\.name) == ["new-mail.pdf", "old-mail.pdf"])
        #expect(groups[0].totalSize == 15)
    }
}
