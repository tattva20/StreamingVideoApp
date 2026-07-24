//
//  UIButton+TestHelpers.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit

extension UIButton {
	func simulateTap() {
		simulate(event: .touchUpInside)
	}
}
