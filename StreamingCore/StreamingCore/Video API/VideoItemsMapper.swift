//
//  VideoItemsMapper.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public final class VideoItemsMapper {
	private struct Root: Decodable {
		private let videos: [RemoteVideo]

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

		var items: [Video] {
			videos.map { Video(id: $0.id, title: $0.title, description: $0.description, url: $0.url, thumbnailURL: $0.thumbnailURL, duration: $0.duration) }
		}
	}

	public enum Error: Swift.Error {
		case invalidData
	}

	public static func map(_ data: Data, from response: HTTPURLResponse) throws -> [Video] {
		guard response.isOK, let root = try? JSONDecoder().decode(Root.self, from: data) else {
			throw Error.invalidData
		}

		return root.items
	}
}
