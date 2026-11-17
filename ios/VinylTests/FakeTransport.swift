import Foundation
import Synchronization
@testable import Vinyl

/// A Catalog network that never leaves the test: it answers each request with `answer` and remembers the requests.
final class FakeTransport: CatalogTransport {
    typealias Answer = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    private let answer: Answer
    private let sent = Mutex<[URLRequest]>([])

    /// The requests the Catalog sent, in order.
    var requests: [URLRequest] { sent.withLock { $0 } }

    init(_ answer: @escaping Answer = { request in (Data(#"{"results":[]}"#.utf8), .ok(request)) }) {
        self.answer = answer
    }

    /// Answers every request with a recorded fixture from the test bundle.
    convenience init(fixture name: String, status: Int = 200) {
        let data = Fixture.data(name)
        self.init { request in (data, HTTPURLResponse.status(status, for: request)) }
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        sent.withLock { $0.append(request) }
        return try await answer(request)
    }
}

/// Recorded JSON in `VinylTests/Fixtures`.
enum Fixture {
    private final class Token {}

    static func data(_ name: String) -> Data {
        guard let url = Bundle(for: Token.self).url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { fatalError("Missing fixture \(name).json") }
        return data
    }
}

extension URLResponse {
    static func ok(_ request: URLRequest) -> URLResponse { HTTPURLResponse.status(200, for: request) }
}

extension HTTPURLResponse {
    static func status(_ code: Int, for request: URLRequest) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: "HTTP/1.1", headerFields: nil)!
    }
}
