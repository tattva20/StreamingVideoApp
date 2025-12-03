//
//  VideoPreloader.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Protocol for video preloading implementations
public protocol VideoPreloader: AnyObject, Sendable {
	/// Preload a video with given priority
	/// - Parameters:
	///   - video: The video to preload
	///   - priority: Priority level for preloading
	func preload(_ video: PreloadableVideo, priority: PreloadPriority) async

	/// Cancel preloading for a specific video
	/// - Parameter videoID: ID of the video to cancel
	func cancelPreload(for videoID: UUID)

	/// Cancel all ongoing preloads
	func cancelAllPreloads()
}
