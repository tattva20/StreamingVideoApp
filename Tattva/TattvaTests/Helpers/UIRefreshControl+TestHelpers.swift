//
//  UIRefreshControl+TestHelpers.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import UIKit

extension UIRefreshControl {
	func simulatePullToRefresh() {
		simulate(event: .valueChanged)
	}
}
