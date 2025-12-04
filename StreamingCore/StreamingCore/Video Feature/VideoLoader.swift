//
//  VideoLoader.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import Combine

/// A protocol for loading video content from a data source.
///
/// `VideoLoader` provides a reactive interface for fetching video metadata.
/// Implementations can load from remote APIs, local storage, or combined sources.
///
/// ## Thread Safety
/// This protocol requires `@MainActor` isolation to ensure UI updates are safe.
///
/// ## Conformance Requirements
/// - Implementations must return a publisher that completes after emitting videos
/// - Errors should be propagated through the publisher's failure type
@MainActor
public protocol VideoLoader {
	/// Loads videos from the data source.
	/// - Returns: A publisher emitting an array of videos or an error
	func load() -> AnyPublisher<[Video], Error>
}
