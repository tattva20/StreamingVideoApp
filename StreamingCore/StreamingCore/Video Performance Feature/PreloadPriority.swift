//
//  PreloadPriority.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Priority levels for video preloading
public enum PreloadPriority: Int, Sendable, Comparable, CaseIterable {
	case low = 0
	case medium = 1
	case high = 2
	case immediate = 3

	public static func < (lhs: PreloadPriority, rhs: PreloadPriority) -> Bool {
		lhs.rawValue < rhs.rawValue
	}
}
