import Foundation

/// Where a download came from, at the granularity the app groups by.
public enum Source: Hashable, Sendable, Comparable {
    /// A website, named by its referring page when known (CDN hosts are rarely meaningful).
    case web(host: String)
    /// An app that saved the file without a URL (AirDrop, Safari "Save Image", Mail…).
    case app(name: String)
    case unknown

    public init(origin: FileOrigin) {
        // kMDItemWhereFroms is [download URL, referrer]; the referrer names the site, the
        // download URL is often a CDN like release-assets.githubusercontent.com.
        let hosts = origin.whereFroms.prefix(2).map(Self.normalizedHost)
        if hosts.count > 1, let referrer = hosts[1] {
            self = .web(host: referrer)
        } else if let download = hosts.first ?? nil {
            self = .web(host: download)
        } else if let agent = origin.quarantine?.agent {
            self = .app(name: Self.appName(forAgent: agent))
        } else {
            self = .unknown
        }
    }

    public var displayName: String {
        switch self {
        case .web(let host): Self.hostAliases[host] ?? host
        case .app(let name): name
        case .unknown: "Unknown origin"
        }
    }

    // MARK: - Normalization

    static let hostAliases: [String: String] = [
        "mail.google.com": "Gmail",
        "docs.google.com": "Google Docs",
        "drive.google.com": "Google Drive",
        "photos.google.com": "Google Photos",
    ]

    static let agentAliases: [String: String] = [
        "sharingd": "AirDrop",
        "com.apple.Safari.SandboxBroker.xpc": "Safari",
    ]

    /// Lowercased host without `www.`, keeping a non-default port. Nil for non-URLs
    /// (Mail stores sender addresses and subjects in kMDItemWhereFroms).
    static func normalizedHost(_ string: String) -> String? {
        // Files generated in-browser (draw.io exports etc.) are saved from
        // `blob:https://site/uuid`; the wrapped URL names the site.
        if string.lowercased().hasPrefix("blob:") { return normalizedHost(String(string.dropFirst(5))) }
        guard let url = URL(string: string), url.scheme != nil,
            var host = url.host(percentEncoded: false)?.lowercased(), !host.isEmpty
        else { return nil }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        if let port = url.port { host += ":\(port)" }
        return host
    }

    /// Friendly app name for a quarantine agent: aliases first, then the last component of
    /// a bundle-ID-like agent (`com.google.Chrome` → `Chrome`), otherwise the agent as is.
    static func appName(forAgent agent: String) -> String {
        if let alias = agentAliases[agent] { return alias }
        let trimmed = agent.hasSuffix(".xpc") ? String(agent.dropLast(4)) : agent
        let parts = trimmed.split(separator: ".")
        if parts.count >= 3, !trimmed.contains(" "), let last = parts.last { return String(last) }
        return agent
    }
}
