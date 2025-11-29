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

    public func load() async throws -> [Video] {
        let (data, response): (Data, HTTPURLResponse)

        do {
            (data, response) = try await client.get(from: url)
        } catch {
            throw Error.connectivity
        }

        guard response.statusCode == 200 else {
            throw Error.invalidData
        }

        guard let root = try? JSONDecoder().decode(VideosRoot.self, from: data) else {
            throw Error.invalidData
        }

        return root.videos.map { remoteVideo in
            Video(
                id: remoteVideo.id,
                title: remoteVideo.title,
                description: remoteVideo.description,
                url: remoteVideo.url,
                thumbnailURL: remoteVideo.thumbnailURL,
                duration: remoteVideo.duration
            )
        }
    }

    public func load(completion: @escaping (Result) -> Void) {
        Task {
            do {
                let videos = try await load()
                completion(.success(videos))
            } catch let error as Error {
                completion(.failure(error))
            } catch {
                completion(.failure(.connectivity))
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
