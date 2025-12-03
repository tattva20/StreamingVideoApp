//
//  PredictivePreloadStrategy.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Protocol for strategies that determine which videos to preload
public protocol PredictivePreloadStrategy: Sendable {
	/// Determine which videos should be preloaded based on current position
	/// - Parameters:
	///   - currentVideoIndex: Index of currently playing video
	///   - playlist: Full playlist of videos
	///   - networkQuality: Current network quality
	/// - Returns: Array of videos to preload in priority order
	func videosToPreload(
		currentVideoIndex: Int,
		playlist: [PreloadableVideo],
		networkQuality: NetworkQuality
	) -> [PreloadableVideo]
}
