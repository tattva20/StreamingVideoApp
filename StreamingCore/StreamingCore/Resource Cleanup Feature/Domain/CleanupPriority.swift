//
//  CleanupPriority.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public enum CleanupPriority: Int, Sendable, Comparable, CaseIterable {
	case low = 0       // Nice to have cleared (e.g., prefetched thumbnails)
	case medium = 1    // Should clear under memory pressure (e.g., image cache)
	case high = 2      // Must clear when critical (e.g., video buffer cache)

	public static func < (lhs: CleanupPriority, rhs: CleanupPriority) -> Bool {
		lhs.rawValue < rhs.rawValue
	}
}
