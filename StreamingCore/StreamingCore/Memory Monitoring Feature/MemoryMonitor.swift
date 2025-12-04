//
//  MemoryMonitor.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Combine
import Foundation

@MainActor
public protocol MemoryStateProvider: AnyObject {
	func currentMemoryState() -> MemoryState
}

@MainActor
public protocol MemoryMonitor: MemoryStateProvider {
	var statePublisher: AnyPublisher<MemoryState, Never> { get }
	var stateStream: AsyncStream<MemoryState> { get }

	func startMonitoring()
	func stopMonitoring()
}
