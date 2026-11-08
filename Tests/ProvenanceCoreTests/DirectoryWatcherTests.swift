import Foundation
import Testing

@testable import ProvenanceCore

@Suite struct DirectoryWatcherTests {
    /// Waits for the first tick on `changes`, or gives up after `timeout`.
    func firstTick(_ changes: AsyncStream<Void>, timeout: Duration = .seconds(5)) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                for await _ in changes { return true }
                return false
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return false
            }
            let result = await group.next() ?? false
            group.cancelAll()
            return result
        }
    }

    @Test func ticksWhenAFileIsAdded() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let watcher = DirectoryWatcher(directory: dir, latency: 0.1)

        try makeFile("new.pdf", in: dir)
        let ticked = await firstTick(watcher.changes)
        withExtendedLifetime(watcher) {}
        #expect(ticked)
    }

    @Test func quietDirectoryDoesNotTick() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let watcher = DirectoryWatcher(directory: dir, latency: 0.1)

        let ticked = await firstTick(watcher.changes, timeout: .milliseconds(800))
        withExtendedLifetime(watcher) {}
        #expect(!ticked)
    }

    @Test func streamFinishesWhenWatcherIsReleased() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        var watcher: DirectoryWatcher? = DirectoryWatcher(directory: dir)
        let changes = try #require(watcher?.changes)
        watcher = nil

        var ticks = 0
        for await _ in changes { ticks += 1 }  // returns only because the stream finished
        #expect(ticks == 0)
    }
}
