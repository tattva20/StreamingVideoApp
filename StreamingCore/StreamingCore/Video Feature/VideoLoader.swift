//
//  VideoLoader.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

/// A protocol for loading video content from a data source.
///
/// `VideoLoader` fetches video metadata using structured concurrency.
/// Implementations can load from remote APIs, local storage, or combined sources.
///
/// ## Thread Safety
/// This protocol requires `@MainActor` isolation to ensure UI updates are safe.
///
/// ## Conformance Requirements
/// - Implementations load videos asynchronously and throw on failure
@MainActor
public protocol VideoLoader {
	/// Loads videos from the data source.
	/// - Returns: An array of videos.
	/// - Throws: An error if loading fails.
	func load() async throws -> [Video]
}
