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
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case .failure:
                completion(.failure(.connectivity))
            case let .success((data, response)):
                if response.statusCode == 200, let root = try? JSONDecoder().decode(VideosRoot.self, from: data) {
                    let videos = root.videos.map { remoteVideo in
                        Video(
                            id: remoteVideo.id,
                            title: remoteVideo.title,
                            description: remoteVideo.description,
                            url: remoteVideo.url,
                            thumbnailURL: remoteVideo.thumbnailURL,
                            duration: remoteVideo.duration
                        )
                    }
                    completion(.success(videos))
                } else {
                    completion(.failure(.invalidData))
                }
            }
        }
    }
}

private struct VideosRoot: Decodable {
    let videos: [RemoteVideo]
}

private struct RemoteVideo: Decodable {
    let id: UUID
    let title: String
    let description: String?
    let url: URL
    let thumbnailURL: URL
    let duration: TimeInterval

    enum CodingKeys: String, CodingKey {
        case id, title, description, url, duration
        case thumbnailURL = "thumbnail_url"
    }
}
