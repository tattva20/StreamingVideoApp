//
//  AVPlayerBufferAdapter.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import AVFoundation
import Combine
import StreamingCore

// MARK: - Protocol Abstractions

/// Protocol for items that can have their buffer duration configured
@MainActor
public protocol BufferConfigurableItem: AnyObject {
	var preferredForwardBufferDuration: TimeInterval { get set }
}

/// Protocol for players that provide a current item for buffer configuration
@MainActor
public protocol BufferConfigurablePlayer: AnyObject {
	associatedtype Item: BufferConfigurableItem
	var currentItem: Item? { get }
}

// MARK: - AVFoundation Conformances

extension AVPlayerItem: BufferConfigurableItem {}

extension AVPlayer: BufferConfigurablePlayer {
	public typealias Item = AVPlayerItem
}

// MARK: - AVPlayerBufferAdapter

/// Adapts BufferManager configuration changes to any BufferConfigurablePlayer
/// Observes buffer configuration updates and applies them to the player's current item
/// Uses @MainActor isolation following Essential Feed patterns for thread-safety.
@MainActor
public final class AVPlayerBufferAdapter<Player: BufferConfigurablePlayer> {
	public let player: Player
	private let bufferManager: any BufferManager
	private var cancellables = Set<AnyCancellable>()

	public init(player: Player, bufferManager: any BufferManager, observeChanges: Bool = true) {
		self.player = player
		self.bufferManager = bufferManager
		if observeChanges {
			setupObservation()
		}
	}

	private func setupObservation() {
		bufferManager.configurationPublisher
			.receive(on: RunLoop.main)
			.sink { [weak self] configuration in
				self?.applyConfiguration(configuration)
			}
			.store(in: &cancellables)
	}

	private func applyConfiguration(_ configuration: BufferConfiguration) {
		guard let currentItem = player.currentItem else { return }
		currentItem.preferredForwardBufferDuration = configuration.preferredForwardBufferDuration
	}

	/// Apply current buffer configuration to a new player item
	/// Call this when replacing the player's current item
	public func applyToNewItem(_ item: Player.Item) {
		let config = bufferManager.currentConfiguration
		item.preferredForwardBufferDuration = config.preferredForwardBufferDuration
	}
}

// MARK: - Type Alias for Concrete Usage

/// Convenience type alias for production use with AVPlayer
public typealias AVPlayerBufferAdapterConcrete = AVPlayerBufferAdapter<AVPlayer>
