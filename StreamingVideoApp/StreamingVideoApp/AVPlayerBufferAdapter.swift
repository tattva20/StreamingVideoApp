//
//  AVPlayerBufferAdapter.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import AVFoundation
import Combine
import StreamingCore

/// Adapts BufferManager configuration changes to AVPlayer/AVPlayerItem
/// Observes buffer configuration updates and applies them to the player's current item
public final class AVPlayerBufferAdapter: @unchecked Sendable {
	public let player: AVPlayer
	private let bufferManager: any BufferManager
	private var cancellables = Set<AnyCancellable>()

	public init(player: AVPlayer, bufferManager: any BufferManager) {
		self.player = player
		self.bufferManager = bufferManager
		setupObservation()
	}

	private func setupObservation() {
		bufferManager.configurationPublisher
			.receive(on: DispatchQueue.main)
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
	@MainActor
	public func applyToNewItem(_ item: AVPlayerItem) {
		let config = bufferManager.currentConfiguration
		item.preferredForwardBufferDuration = config.preferredForwardBufferDuration
	}
}
