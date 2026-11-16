import Foundation

/// The network under the Catalog. Tests pass a fake that answers with recorded JSON.
protocol CatalogTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// The real network.
struct URLSessionTransport: CatalogTransport {
    var session: URLSession = .shared

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
