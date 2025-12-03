//
//  BufferManager.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation

public protocol BufferSizeProvider: Sendable {
	var currentConfiguration: BufferConfiguration { get async }
}

public protocol BufferManager: BufferSizeProvider, AnyObject, Sendable {
	var configurationPublisher: AnyPublisher<BufferConfiguration, Never> { get }
	var configurationStream: AsyncStream<BufferConfiguration> { get }

	func updateMemoryState(_ state: MemoryState) async
	func updateNetworkQuality(_ quality: NetworkQuality) async
}
