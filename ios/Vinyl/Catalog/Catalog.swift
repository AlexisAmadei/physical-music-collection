import Foundation

/// One provider the Catalog asks (Discogs, MusicBrainz). Throwing means "no answer": the Catalog asks the next Source.
protocol CatalogSource: Sendable {
    /// Releases with this barcode, as prefilled Drafts.
    func lookup(barcode: String) async throws -> [Draft]
    /// Releases matching the text, as prefilled Drafts.
    func search(_ text: String) async throws -> [Draft]
}

/// The outside knowledge of existing releases, asked to prefill a Draft by barcode or by text.
/// It asks its Sources in order; the first non-empty answer wins. A failing Source counts as empty.
struct Catalog: Sendable {
    var sources: [any CatalogSource]
    /// How long one Source may take before it counts as empty.
    var timeout: Duration = .seconds(8)

    /// Prefilled Drafts for a scanned barcode; empty when no Source knows it.
    func lookup(barcode: String) async -> [Draft] {
        await firstAnswer { try await $0.lookup(barcode: barcode) }
    }

    /// Prefilled Drafts for a text search; empty when no Source finds anything.
    func search(_ text: String) async -> [Draft] {
        await firstAnswer { try await $0.search(text) }
    }

    private func firstAnswer(_ ask: @escaping @Sendable (any CatalogSource) async throws -> [Draft]) async -> [Draft] {
        for source in sources {
            let answer = await withinTimeout { try await ask(source) }
            if !answer.isEmpty { return answer }
        }
        return []
    }

    /// The Source's answer, or empty when it fails or takes longer than `timeout` (it is then cancelled).
    private func withinTimeout(_ ask: @escaping @Sendable () async throws -> [Draft]) async -> [Draft] {
        await withTaskGroup(of: [Draft]?.self) { group in
            group.addTask { (try? await ask()) ?? [] }
            group.addTask { [timeout] in
                try? await Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first ?? []
        }
    }
}

extension Catalog {
    /// The app's Catalog: Discogs first, MusicBrainz when Discogs finds nothing or fails.
    static func standard(transport: any CatalogTransport, discogs: DiscogsCredentials? = .bundled) -> Catalog {
        Catalog(sources: [
            DiscogsSource(transport: transport, credentials: discogs),
            MusicBrainzSource(transport: transport),
        ])
    }
}
