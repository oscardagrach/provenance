import CoreServices
import Foundation

/// Emits a tick on `changes` whenever something inside `directory` changes. Bursts within
/// `latency` seconds are coalesced into one tick; callers rescan on each tick.
///
/// Owns an FSEvents stream, which stops when the watcher is deinitialized. Not `Sendable`:
/// keep it on one task or actor and hand out `changes` (which is `Sendable`) instead.
public final class DirectoryWatcher {
    public let changes: AsyncStream<Void>

    private let box: ContinuationBox
    private var stream: FSEventStreamRef?
    private let queue = DispatchQueue(label: "dev.provenance.directory-watcher")

    /// Lets the C callback reach the continuation. `final` with a single `let` of a
    /// `Sendable` type, so it is genuinely `Sendable` without `@unchecked`.
    private final class ContinuationBox: Sendable {
        let continuation: AsyncStream<Void>.Continuation
        init(_ continuation: AsyncStream<Void>.Continuation) { self.continuation = continuation }
    }

    public init(directory: URL, latency: TimeInterval = 1.0) {
        let (changes, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let box = ContinuationBox(continuation)
        self.changes = changes
        self.box = box

        // `self` owns `box` and invalidates the stream in deinit, so an unretained pointer is safe.
        var context = FSEventStreamContext(
            version: 0, info: Unmanaged.passUnretained(box).toOpaque(), retain: nil, release: nil,
            copyDescription: nil)
        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            Unmanaged<ContinuationBox>.fromOpaque(info).takeUnretainedValue().continuation.yield()
        }
        guard
            let stream = FSEventStreamCreate(
                kCFAllocatorDefault, callback, &context, [Self.realPath(directory)] as CFArray,
                FSEventStreamEventId(kFSEventStreamEventIdSinceNow), latency,
                FSEventStreamCreateFlags(kFSEventStreamCreateFlagNoDefer))
        else {
            continuation.finish()
            return
        }
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
        self.stream = stream
    }

    deinit {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        box.continuation.finish()
    }

    /// FSEvents reports real paths (`/private/var/...`), so watch the real path. Foundation's
    /// `resolvingSymlinksInPath` strips `/private`, hence `realpath(3)`.
    private static func realPath(_ url: URL) -> String {
        url.withUnsafeFileSystemRepresentation { path in
            guard let path, let resolved = realpath(path, nil) else { return nil }
            defer { free(resolved) }
            return String(cString: resolved)
        } ?? url.path
    }
}
