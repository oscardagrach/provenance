import Foundation
import Testing

@testable import ProvenanceCore

@Suite struct SourceTests {
    // Cases mirror patterns seen in a real ~/Downloads folder.
    @Test(
        arguments: [
            // CDN download host, meaningful referrer
            (
                ["https://release-assets.githubusercontent.com/x.dmg", "https://obsidian.md/download"], nil,
                Source.web(host: "obsidian.md")
            ),
            (
                ["https://mail-attachment.googleusercontent.com/a", "https://mail.google.com/"], nil,
                .web(host: "mail.google.com")
            ),
            // Download URL only; www. stripped, case folded, port kept
            (["https://WWW.TrendNet.com/manual.pdf"], nil, .web(host: "trendnet.com")),
            (["https://nas.home.lan:5001/share/file.iso"], nil, .web(host: "nas.home.lan:5001")),
            // In-browser exports: the blob URL wraps the site's origin
            (
                ["blob:https://app.diagrams.net/fdc9abca-2db1-4910-a49f-6374da7db964"], "Safari",
                .web(host: "app.diagrams.net")
            ),
            // Referrer that isn't a URL falls back to the download host
            (["https://archive.org/file.iso", "not a url"], nil, .web(host: "archive.org")),
            // Mail stores sender/subject, not URLs: fall back to the agent
            (["sender@example.com", "Re: invoice"], "Mail", .app(name: "Mail")),
            // No URLs: quarantine agent
            ([], "Safari", .app(name: "Safari")),
            ([], "sharingd", .app(name: "AirDrop")),
            ([], "com.apple.Safari.SandboxBroker.xpc", .app(name: "Safari")),
            ([], "com.google.Chrome", .app(name: "Chrome")),
            ([], "QuickTime Player", .app(name: "QuickTime Player")),
            // Nothing at all
            ([], nil, .unknown),
        ] as [([String], String?, Source)])
    func classifies(_ whereFroms: [String], _ agent: String?, _ expected: Source) {
        #expect(Source(origin: origin(whereFroms, agent: agent)) == expected)
    }

    @Test func displayNamesUseAliases() {
        #expect(Source.web(host: "mail.google.com").displayName == "Gmail")
        #expect(Source.web(host: "obsidian.md").displayName == "obsidian.md")
        #expect(Source.app(name: "AirDrop").displayName == "AirDrop")
        #expect(Source.unknown.displayName == "Unknown origin")
    }
}
