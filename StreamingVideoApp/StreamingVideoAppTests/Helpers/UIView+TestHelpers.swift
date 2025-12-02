//
//  UIView+TestHelpers.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit

extension UIView {
	func enforceLayoutCycle() {
		layoutIfNeeded()
		RunLoop.current.run(until: Date())
	}
}
