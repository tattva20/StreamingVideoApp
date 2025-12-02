//
//  VideoEndpoint.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public enum VideoEndpoint {
    case get(after: Video? = nil)

    public func url(baseURL: URL) -> URL {
        switch self {
        case let .get(video):
            var components = URLComponents()
            components.scheme = baseURL.scheme
            components.host = baseURL.host
            components.path = baseURL.path + "/v1/videos"
            components.queryItems = [
                URLQueryItem(name: "limit", value: "10"),
                video.map { URLQueryItem(name: "after_id", value: $0.id.uuidString) },
            ].compactMap { $0 }
            return components.url!
        }
    }
}
