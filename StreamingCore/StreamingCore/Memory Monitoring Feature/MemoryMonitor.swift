//
//  MemoryMonitor.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation

public protocol MemoryStateProvider: Sendable {
	func currentMemoryState() async -> MemoryState
}

public protocol MemoryMonitor: MemoryStateProvider, AnyObject, Sendable {
	var statePublisher: AnyPublisher<MemoryState, Never> { get }
	var stateStream: AsyncStream<MemoryState> { get }

	func startMonitoring() async
	func stopMonitoring() async
}
