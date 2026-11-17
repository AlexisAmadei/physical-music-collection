import Foundation

/// The MusicBrainz release search as a Catalog Source (port of the Android `MusicBrainz`), asked when Discogs has no answer.
struct MusicBrainzSource: CatalogSource {
    var transport: any CatalogTransport

    func lookup(barcode: String) async throws -> [Draft] {
        try await query("barcode:\(barcode)").map { draft in
            var draft = draft
            draft.barcode = barcode
            return draft
        }
    }

    func search(_ text: String) async throws -> [Draft] {
        try await query(text)
    }

    private func query(_ query: String) async throws -> [Draft] {
        var url = URLComponents(string: "https://musicbrainz.org/ws/2/release/")!
        url.queryItems = [
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "15"),
            URLQueryItem(name: "query", value: query),
        ]
        var request = URLRequest(url: url.url!)
        // MusicBrainz rejects clients that don't name themselves with a contact.
        request.setValue(
            "VinylCollectionApp/0.1 ( https://github.com/AlexisAmadei/physical-vinyle-collection )",
            forHTTPHeaderField: "User-Agent"
        )
        let (data, response) = try await transport.data(for: request)
        // 503 when busy or rate limited…: no answer.
        guard let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(Page.self, from: data).releases.map(\.draft)
    }

    private struct Page: Decodable {
        var releases: [Release]
    }

    private struct Release: Decodable {
        var id: String?
        var title: String?
        var artistCredit: [Credit]?
        var date: String?
        var barcode: String?
        var media: [Medium]?

        enum CodingKeys: String, CodingKey {
            case id, title, date, barcode, media
            case artistCredit = "artist-credit"
        }

        var draft: Draft {
            // Anything but a CD (vinyl, cassette, digital…) counts as vinyl, as on Android.
            let medium = media?.first?.format ?? ""
            var draft = Draft(format: medium.localizedCaseInsensitiveContains("CD") ? .cd : .vinyl)
            draft.title = title ?? ""
            draft.artist = (artistCredit ?? []).map { ($0.name ?? "") + ($0.joinphrase ?? "") }.joined()
            draft.year = Int((date ?? "").prefix(4))
            draft.barcode = barcode.flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 }
            if let id, !id.isEmpty {
                draft.coverURL = URL(string: "https://coverartarchive.org/release/\(id)/front-500")
            }
            return draft
        }
    }

    private struct Medium: Decodable {
        var format: String?
    }

    private struct Credit: Decodable {
        var name: String?
        var joinphrase: String?
    }
}
