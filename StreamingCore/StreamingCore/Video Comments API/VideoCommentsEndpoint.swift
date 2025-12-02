//
//  VideoCommentsEndpoint.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public enum VideoCommentsEndpoint {
	case get(UUID)

	public func url(baseURL: URL) -> URL {
		switch self {
		case let .get(id):
			var components = URLComponents()
			components.scheme = baseURL.scheme
			components.host = baseURL.host
			components.path = baseURL.path + "/v1/videos/\(id.uuidString)/comments"
			return components.url!
		}
	}
}
