import Foundation

public final class RemoteVideoLoader {
    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
}
