//
//  RemoteVideoLoader.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import Combine

public final class RemoteVideoLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error, Equatable {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
}

extension RemoteVideoLoader: VideoLoader {
	public func load() -> AnyPublisher<[Video], Swift.Error> {
		client.getPublisher(url: url)
			.tryMap { data, response in
				do {
					return try VideoItemsMapper.map(data, from: response)
				} catch {
					throw Error.invalidData
				}
			}
			.mapError { error in
				error as? RemoteVideoLoader.Error ?? .connectivity
			}
			.eraseToAnyPublisher()
	}
}
