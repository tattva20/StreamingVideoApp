//
//  AdaptiveBufferManager.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation

/// Thread-safe @MainActor class implementation of buffer management.
/// Uses @MainActor isolation following Essential Feed patterns for thread-safety.
@MainActor
public final class AdaptiveBufferManager: BufferManager {
	private var memoryPressure: MemoryPressureLevel = .normal
	private var networkQuality: NetworkQuality = .good
	private var _currentConfiguration: BufferConfiguration = .balanced
	private let thresholds: MemoryThresholds

	private let configurationSubject = CurrentValueSubject<BufferConfiguration, Never>(.balanced)

	public var configurationPublisher: AnyPublisher<BufferConfiguration, Never> {
		configurationSubject
			.removeDuplicates()
			.eraseToAnyPublisher()
	}

	public var configurationStream: AsyncStream<BufferConfiguration> {
		configurationPublisher.toAsyncStream()
	}

	public var currentConfiguration: BufferConfiguration {
		_currentConfiguration
	}

	public init(thresholds: MemoryThresholds = .default) {
		self.thresholds = thresholds
	}

	public func updateMemoryState(_ state: MemoryState) {
		memoryPressure = state.pressureLevel(thresholds: thresholds)
		recalculateStrategy()
	}

	public func updateNetworkQuality(_ quality: NetworkQuality) {
		networkQuality = quality
		recalculateStrategy()
	}

	private func recalculateStrategy() {
		let newConfig = calculateConfiguration(memory: memoryPressure, network: networkQuality)

		if newConfig != _currentConfiguration {
			_currentConfiguration = newConfig
			configurationSubject.send(newConfig)
		}
	}

	private func calculateConfiguration(memory: MemoryPressureLevel, network: NetworkQuality) -> BufferConfiguration {
		// Priority: Memory pressure takes precedence over network quality
		switch memory {
		case .critical:
			return .minimal

		case .warning:
			// Even with good network, stay conservative when memory is tight
			return .conservative

		case .normal:
			// Normal memory - base on network quality
			switch network {
			case .offline, .poor:
				return BufferConfiguration(
					strategy: .conservative,
					preferredForwardBufferDuration: 5.0,
					reason: "Poor network - conservative buffering to reduce rebuffering"
				)
			case .fair:
				return .balanced
			case .good, .excellent:
				return .aggressive
			}
		}
	}
}
