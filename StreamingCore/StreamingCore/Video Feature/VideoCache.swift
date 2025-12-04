//
//  VideoCache.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

/// A protocol for caching video metadata locally.
///
/// `VideoCache` provides persistence for video data, enabling offline access
/// and reducing network requests. Implementations can use CoreData, file system,
/// or other storage mechanisms.
///
/// ## Conformance Requirements
/// - Implementations should handle concurrent save operations safely
/// - Throwing behavior should indicate storage failures (disk full, corruption, etc.)
public protocol VideoCache {
	/// Saves videos to the local cache.
	/// - Parameter videos: The videos to persist
	/// - Throws: An error if the save operation fails
	func save(_ videos: [Video]) throws
}
