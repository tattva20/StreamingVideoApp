//
//  BufferStrategy.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public enum BufferStrategy: Int, Sendable, CaseIterable, Comparable {
	case minimal = 0
	case conservative = 1
	case balanced = 2
	case aggressive = 3

	public static func < (lhs: BufferStrategy, rhs: BufferStrategy) -> Bool {
		lhs.rawValue < rhs.rawValue
	}

	public var description: String {
		switch self {
		case .minimal: return "Minimal (memory critical)"
		case .conservative: return "Conservative (low resources)"
		case .balanced: return "Balanced (normal)"
		case .aggressive: return "Aggressive (optimal conditions)"
		}
	}
}
