//
//  ControlsVisibilityController.swift
//  StreamingCoreiOS
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public protocol ControlsVisibilityDelegate: AnyObject {
	func controlsDidShow()
	func controlsDidHide()
	func scheduleTimer(withDelay delay: TimeInterval, callback: @escaping () -> Void)
	func cancelTimer()
}

public final class ControlsVisibilityController {
	public private(set) var areControlsVisible: Bool = true

	private let hideDelay: TimeInterval
	private weak var delegate: ControlsVisibilityDelegate?

	public init(hideDelay: TimeInterval, delegate: ControlsVisibilityDelegate) {
		self.hideDelay = hideDelay
		self.delegate = delegate
	}

	public func show() {
		areControlsVisible = true
		delegate?.controlsDidShow()
		scheduleHide()
	}

	public func hide() {
		areControlsVisible = false
		delegate?.cancelTimer()
		delegate?.controlsDidHide()
	}

	public func toggle() {
		if areControlsVisible {
			hide()
		} else {
			show()
		}
	}

	public func scheduleHide() {
		delegate?.cancelTimer()
		delegate?.scheduleTimer(withDelay: hideDelay) { [weak self] in
			self?.hide()
		}
	}

	public func cancelTimer() {
		delegate?.cancelTimer()
	}
}
