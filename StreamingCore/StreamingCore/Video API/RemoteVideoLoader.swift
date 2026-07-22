//
//  RemoteVideoLoader.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

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
	public func load() async throws -> [Video] {
		let data: Data
		let response: HTTPURLResponse
		do {
			(data, response) = try await client.get(from: url)
		} catch {
			throw Error.connectivity
		}
		do {
			return try VideoItemsMapper.map(data, from: response)
		} catch {
			throw Error.invalidData
		}
	}
}
