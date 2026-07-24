//
//  UIView+TestHelpers.swift
//  Tattva
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
