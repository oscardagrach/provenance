import Foundation
import Testing

@testable import ProvenanceCore

@Suite struct QuarantineParsingTests {
    @Test func parsesFullRecord() throws {
        let q = try #require(QuarantineInfo(raw: "0083;65f1a2b3;Safari;8F1C2D3E-0000-4000-8000-000000000000"))
        #expect(q.flags == "0083")
        #expect(q.date == Date(timeIntervalSince1970: 0x65f1_a2b3))
        #expect(q.agent == "Safari")
        #expect(q.eventID == "8F1C2D3E-0000-4000-8000-000000000000")
    }

    @Test func toleratesMissingFields() throws {
        let q = try #require(QuarantineInfo(raw: "0081;65f1a2b3;;"))
        #expect(q.agent == nil)
        #expect(q.eventID == nil)
    }

    @Test(arguments: ["", "garbage", ";65f1a2b3"])
    func rejectsMalformed(_ raw: String) {
        #expect(QuarantineInfo(raw: raw) == nil)
    }
}

@Suite struct OriginReaderTests {
    @Test func readsWhereFromsFromRealXattr() throws {
        let file = FileManager.default.temporaryDirectory.appending(path: "prov-\(UUID()).txt")
        try Data("hi".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }

        let urls = ["https://example.com/files/report.pdf", "https://example.com/downloads"]
        let plist = try PropertyListSerialization.data(fromPropertyList: urls, format: .binary, options: 0)
        #expect(ExtendedAttributes.set(OriginReader.whereFromsKey, plist, at: file))
        #expect(ExtendedAttributes.set(OriginReader.quarantineKey, Data("0083;65f1a2b3;Safari;".utf8), at: file))

        let origin = OriginReader.read(file)
        #expect(origin.whereFroms == urls)
        #expect(origin.sourceHost == "example.com")
        #expect(origin.quarantine?.agent == "Safari")
    }

    @Test func fileWithoutAttributesHasEmptyOrigin() throws {
        let file = FileManager.default.temporaryDirectory.appending(path: "prov-\(UUID()).txt")
        try Data().write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        #expect(OriginReader.read(file) == FileOrigin())
    }
}
