//
//  CleanupResult.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public struct CleanupResult: Equatable, Sendable {
	public let resourceName: String
	public let bytesFreed: UInt64
	public let itemsRemoved: Int
	public let success: Bool
	public let error: String?

	public var freedMB: Double {
		Double(bytesFreed) / 1_048_576.0
	}

	public init(resourceName: String, bytesFreed: UInt64, itemsRemoved: Int, success: Bool, error: String? = nil) {
		self.resourceName = resourceName
		self.bytesFreed = bytesFreed
		self.itemsRemoved = itemsRemoved
		self.success = success
		self.error = error
	}

	public static func failure(resourceName: String, error: String) -> CleanupResult {
		CleanupResult(resourceName: resourceName, bytesFreed: 0, itemsRemoved: 0, success: false, error: error)
	}
}
