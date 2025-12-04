//
//  BufferManager.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation

@MainActor
public protocol BufferSizeProvider: AnyObject {
	var currentConfiguration: BufferConfiguration { get }
}

@MainActor
public protocol BufferManager: BufferSizeProvider {
	var configurationPublisher: AnyPublisher<BufferConfiguration, Never> { get }
	var configurationStream: AsyncStream<BufferConfiguration> { get }

	func updateMemoryState(_ state: MemoryState)
	func updateNetworkQuality(_ quality: NetworkQuality)
}
