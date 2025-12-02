//
//  URLSessionHTTPClient.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "URLSessionHTTPClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }

        return (data, httpResponse)
    }
}
