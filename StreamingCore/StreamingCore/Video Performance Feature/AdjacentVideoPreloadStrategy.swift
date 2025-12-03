//
//  AdjacentVideoPreloadStrategy.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Preloads adjacent videos in the playlist based on network quality
/// - Excellent/Good: Preloads next 2 videos
/// - Fair: Preloads next 1 video
/// - Poor: Preloads next 1 video (lower priority)
/// - Offline: No preloading
public struct AdjacentVideoPreloadStrategy: PredictivePreloadStrategy, Sendable {

	public init() {}

	public func videosToPreload(
		currentVideoIndex: Int,
		playlist: [PreloadableVideo],
		networkQuality: NetworkQuality
	) -> [PreloadableVideo] {
		// Validate index
		guard currentVideoIndex >= 0,
			  currentVideoIndex < playlist.count,
			  !playlist.isEmpty else {
			return []
		}

		// No preloading when offline
		guard networkQuality != .offline else {
			return []
		}

		// Determine how many videos to preload based on network quality
		let preloadCount: Int
		switch networkQuality {
		case .offline:
			preloadCount = 0
		case .poor:
			preloadCount = 1
		case .fair:
			preloadCount = 1
		case .good:
			preloadCount = 2
		case .excellent:
			preloadCount = 2
		}

		// Collect next videos
		var videosToPreload: [PreloadableVideo] = []
		let startIndex = currentVideoIndex + 1
		let endIndex = min(startIndex + preloadCount, playlist.count)

		for index in startIndex..<endIndex {
			videosToPreload.append(playlist[index])
		}

		return videosToPreload
	}
}
