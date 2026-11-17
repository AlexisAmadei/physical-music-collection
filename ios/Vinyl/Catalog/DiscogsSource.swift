import Foundation

/// The Discogs app key and secret. Without them Discogs still answers, but without covers and at 25 requests a minute.
struct DiscogsCredentials: Equatable, Sendable {
    var key: String
    var secret: String

    /// The key and secret built into the app from the git-ignored `Config/Secrets.xcconfig`; nil without a key.
    static var bundled: DiscogsCredentials? { from(Bundle.main.infoDictionary ?? [:]) }

    /// Reads `DiscogsKey` and `DiscogsSecret` from an Info.plist dictionary; nil when the key is blank.
    static func from(_ info: [String: Any]) -> DiscogsCredentials? {
        let key = (info["DiscogsKey"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        let secret = (info["DiscogsSecret"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        return key.isEmpty ? nil : DiscogsCredentials(key: key, secret: secret)
    }
}

/// The Discogs database search as a Catalog Source (port of the Android `Discogs`): releases only, CD and vinyl only,
/// one Pressing per album and Format.
struct DiscogsSource: CatalogSource {
    var transport: any CatalogTransport
    var credentials: DiscogsCredentials?

    func lookup(barcode: String) async throws -> [Draft] {
        try await query("barcode", barcode).map { draft in
            var draft = draft
            draft.barcode = barcode
            return draft
        }
    }

    func search(_ text: String) async throws -> [Draft] {
        try await query("q", text)
    }

    private func query(_ name: String, _ value: String) async throws -> [Draft] {
        var url = URLComponents(string: "https://api.discogs.com/database/search")!
        url.queryItems = [
            URLQueryItem(name: "type", value: "release"),
            URLQueryItem(name: "per_page", value: "30"),
            URLQueryItem(name: name, value: value),
        ]
        var request = URLRequest(url: url.url!)
        request.setValue("VinylCollectionApp/0.1", forHTTPHeaderField: "User-Agent")
        if let credentials, !credentials.key.isEmpty {
            request.setValue("Discogs key=\(credentials.key), secret=\(credentials.secret)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await transport.data(for: request)
        // Bad credentials, 429 rate limit…: no answer, so the Catalog asks the next Source.
        guard let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) else {
            throw URLError(.badServerResponse)
        }
        let page = try JSONDecoder().decode(Page.self, from: data)
        return Self.onePressingPerAlbum(page.results.compactMap(\.draft))
    }

    /// Discogs lists every Pressing: keep one per lowercase title, artist and Format, preferring one with a cover,
    /// at most 15.
    private static func onePressingPerAlbum(_ drafts: [Draft]) -> [Draft] {
        var groups: [[Draft]] = []
        var index: [String: Int] = [:]
        for draft in drafts {
            let key = [draft.title.lowercased(), draft.artist.lowercased(), draft.format.rawValue].joined(separator: "\u{1F}")
            if let i = index[key] {
                groups[i].append(draft)
            } else {
                index[key] = groups.count
                groups.append([draft])
            }
        }
        return groups.prefix(15).map { pressings in pressings.first { $0.coverURL != nil } ?? pressings[0] }
    }

    private struct Page: Decodable {
        var results: [Result]
    }

    private struct Result: Decodable {
        var title: String?
        var year: String?
        var format: [String]?
        var cover_image: String?

        /// Nil for anything but CD or vinyl (cassette, file, DVD…).
        var draft: Draft? {
            let formats = format ?? []
            let format: Format
            if formats.contains(where: { $0.caseInsensitiveCompare("CD") == .orderedSame }) {
                format = .cd
            } else if formats.contains(where: { $0.caseInsensitiveCompare("Vinyl") == .orderedSame }) {
                format = .vinyl
            } else {
                return nil
            }
            // "Artist - Title"; Discogs disambiguates artists as "Name (2)" and name variations as "Name*".
            let full = title ?? ""
            var draft = Draft(format: format)
            if let cut = full.range(of: " - ") {
                draft.artist = String(full[..<cut.lowerBound])
                    .replacing(/\s*\(\d+\)|\*/, with: "")
                    .trimmingCharacters(in: .whitespaces)
                draft.title = String(full[cut.upperBound...]).trimmingCharacters(in: .whitespaces)
            } else {
                draft.title = full
            }
            draft.year = year.flatMap { Int($0) }
            if let cover = cover_image, !cover.isEmpty, !cover.hasSuffix("spacer.gif") {
                draft.coverURL = URL(string: cover)
            }
            return draft
        }
    }
}
