//
//  AdaptiveBufferManager.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation

public actor AdaptiveBufferManager: BufferManager {
	private var memoryPressure: MemoryPressureLevel = .normal
	private var networkQuality: NetworkQuality = .good
	private var _currentConfiguration: BufferConfiguration = .balanced
	private let thresholds: MemoryThresholds

	private nonisolated(unsafe) let configurationSubject = CurrentValueSubject<BufferConfiguration, Never>(.balanced)

	public nonisolated var configurationPublisher: AnyPublisher<BufferConfiguration, Never> {
		configurationSubject
			.removeDuplicates()
			.eraseToAnyPublisher()
	}

	public nonisolated var configurationStream: AsyncStream<BufferConfiguration> {
		configurationPublisher.toAsyncStream()
	}

	public var currentConfiguration: BufferConfiguration {
		_currentConfiguration
	}

	public init(thresholds: MemoryThresholds = .default) {
		self.thresholds = thresholds
	}

	public func updateMemoryState(_ state: MemoryState) async {
		memoryPressure = state.pressureLevel(thresholds: thresholds)
		await recalculateStrategy()
	}

	public func updateNetworkQuality(_ quality: NetworkQuality) async {
		networkQuality = quality
		await recalculateStrategy()
	}

	private func recalculateStrategy() async {
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
