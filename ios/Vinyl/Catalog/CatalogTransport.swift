import Foundation

/// The network under the Catalog. Tests pass a fake that answers with recorded JSON.
protocol CatalogTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension CatalogTransport {
    /// The body of a 2xx answer. Any other status (bad credentials, rate limit, busy…) throws: the Source has
    /// no answer and the Catalog asks the next one.
    func okData(for request: URLRequest) async throws -> Data {
        let (data, response) = try await data(for: request)
        guard let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

/// The real network.
struct URLSessionTransport: CatalogTransport {
    var session: URLSession = .shared

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
