//
//  BufferConfiguration.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public struct BufferConfiguration: Equatable, Sendable {
	public let strategy: BufferStrategy
	public let preferredForwardBufferDuration: TimeInterval
	public let reason: String

	public static let minimal = BufferConfiguration(
		strategy: .minimal,
		preferredForwardBufferDuration: 2.0,
		reason: "Memory critical - minimal buffering"
	)

	public static let conservative = BufferConfiguration(
		strategy: .conservative,
		preferredForwardBufferDuration: 5.0,
		reason: "Limited resources - conservative buffering"
	)

	public static let balanced = BufferConfiguration(
		strategy: .balanced,
		preferredForwardBufferDuration: 10.0,
		reason: "Normal conditions - balanced buffering"
	)

	public static let aggressive = BufferConfiguration(
		strategy: .aggressive,
		preferredForwardBufferDuration: 30.0,
		reason: "Optimal conditions - aggressive buffering"
	)

	public init(strategy: BufferStrategy, preferredForwardBufferDuration: TimeInterval, reason: String) {
		self.strategy = strategy
		self.preferredForwardBufferDuration = preferredForwardBufferDuration
		self.reason = reason
	}
}
