//
//  BufferManager.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation

/// A protocol providing access to the current buffer configuration.
///
/// `BufferSizeProvider` exposes read-only access to buffer settings,
/// allowing components to query buffer sizes without the ability to modify them.
///
/// ## Thread Safety
/// Requires `@MainActor` isolation for safe UI and state access.
@MainActor
public protocol BufferSizeProvider: AnyObject {
	/// The current buffer configuration settings.
	var currentConfiguration: BufferConfiguration { get }
}

/// A protocol for managing video buffer configuration dynamically.
///
/// `BufferManager` adjusts buffer sizes based on memory pressure and network
/// conditions, optimizing playback smoothness while respecting device constraints.
///
/// ## Thread Safety
/// Requires `@MainActor` isolation for safe state updates.
///
/// ## Conformance Requirements
/// - Must inherit from `BufferSizeProvider`
/// - Configuration changes should be published through `configurationPublisher`
@MainActor
public protocol BufferManager: BufferSizeProvider {
	/// A publisher emitting buffer configuration changes.
	var configurationPublisher: AnyPublisher<BufferConfiguration, Never> { get }

	/// Updates the buffer manager with current memory state.
	/// - Parameter state: The current memory state
	func updateMemoryState(_ state: MemoryState)

	/// Updates the buffer manager with current network quality.
	/// - Parameter quality: The current network quality
	func updateNetworkQuality(_ quality: NetworkQuality)
}
