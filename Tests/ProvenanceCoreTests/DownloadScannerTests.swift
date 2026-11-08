import Foundation
import Testing
import UniformTypeIdentifiers

@testable import ProvenanceCore

@Suite struct DownloadScannerTests {
    @Test func skipsHiddenAndPartialDownloads() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try makeFile("report.pdf", in: dir)
        try makeFile(".DS_Store", in: dir)
        try makeFile("big.iso.crdownload", in: dir)
        try makeFile("movie.mp4.part", in: dir)
        try FileManager.default.createDirectory(
            at: dir.appending(path: "app.dmg.download"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dir.appending(path: "Extracted"), withIntermediateDirectories: true)

        var scanner = DownloadScanner(directory: dir)
        #expect(try scanner.scan().map(\.name).sorted() == ["Extracted", "report.pdf"])
    }

    @Test func readsMetadataAndOrigin() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = try makeFile("manual.pdf", in: dir, bytes: 5_000)
        try setOrigin(of: file, whereFroms: ["https://cdn.example.net/m.pdf", "https://www.example.com/support"])

        var scanner = DownloadScanner(directory: dir)
        let item = try #require(try scanner.scan().first)
        #expect(item.contentType == .pdf)
        #expect(!item.isDirectory)
        #expect(item.size >= 5_000)
        #expect(item.source == .web(host: "example.com"))
    }

    @Test func measuresFoldersRecursively() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let folder = dir.appending(path: "Archive", directoryHint: .isDirectory)
        let nested = folder.appending(path: "nested", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try makeFile("a.bin", in: folder, bytes: 20_000)
        try makeFile("b.bin", in: nested, bytes: 30_000)

        var scanner = DownloadScanner(directory: dir)
        let item = try #require(try scanner.scan().first)
        #expect(item.isDirectory)
        #expect(item.size >= 50_000)
    }

    @Test func reusesFolderSizeUntilFolderChanges() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let folder = dir.appending(path: "Archive", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try makeFile("a.bin", in: folder, bytes: 10_000)

        var scanner = DownloadScanner(directory: dir)
        _ = try scanner.scan()
        _ = try scanner.scan()
        #expect(scanner.folderMeasurements == 1)

        try makeFile("b.bin", in: folder, bytes: 10_000)  // bumps the folder's mtime
        let item = try #require(try scanner.scan().first)
        #expect(scanner.folderMeasurements == 2)
        #expect(item.size >= 20_000)
    }

    @Test func missingDirectoryThrows() {
        var scanner = DownloadScanner(directory: URL(filePath: "/nonexistent-\(UUID())"))
        #expect(throws: (any Error).self) { try scanner.scan() }
    }
}
