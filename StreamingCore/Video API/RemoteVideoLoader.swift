import Foundation

public final class RemoteVideoLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error, Equatable {
        case connectivity
        case invalidData
    }

    public typealias Result = Swift.Result<[Video], Error>

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .failure:
                completion(.failure(.connectivity))
            case .success:
                break
            }
        }
    }
}
