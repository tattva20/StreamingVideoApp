//
//  PreloadableVideo.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Represents a video that can be preloaded
public struct PreloadableVideo: Equatable, Sendable {
	public let id: UUID
	public let url: URL
	public let estimatedDuration: TimeInterval?

	public init(id: UUID, url: URL, estimatedDuration: TimeInterval?) {
		self.id = id
		self.url = url
		self.estimatedDuration = estimatedDuration
	}
}
