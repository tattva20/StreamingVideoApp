//
//  ControlsVisibilityControllerTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCoreiOS

class ControlsVisibilityControllerTests: XCTestCase {

	func test_init_controlsAreVisible() {
		let (sut, _) = makeSUT()

		XCTAssertTrue(sut.areControlsVisible)
	}

	func test_hide_setsControlsToNotVisible() {
		let (sut, _) = makeSUT()

		sut.hide()

		XCTAssertFalse(sut.areControlsVisible)
	}

	func test_show_setsControlsToVisible() {
		let (sut, _) = makeSUT()
		sut.hide()

		sut.show()

		XCTAssertTrue(sut.areControlsVisible)
	}

	func test_toggle_hidesControlsWhenVisible() {
		let (sut, _) = makeSUT()

		sut.toggle()

		XCTAssertFalse(sut.areControlsVisible)
	}

	func test_toggle_showsControlsWhenHidden() {
		let (sut, _) = makeSUT()
		sut.hide()

		sut.toggle()

		XCTAssertTrue(sut.areControlsVisible)
	}

	func test_hide_notifiesDelegate() {
		let (sut, delegate) = makeSUT()

		sut.hide()

		XCTAssertEqual(delegate.messages, [.didHide])
	}

	func test_show_notifiesDelegate() {
		let (sut, delegate) = makeSUT()
		sut.hide()
		delegate.messages.removeAll()

		sut.show()

		XCTAssertEqual(delegate.messages, [.didShow, .didScheduleTimer(5.0)])
	}

	func test_scheduleHide_hidesAfterDelay() {
		let (sut, delegate) = makeSUT()

		sut.scheduleHide()
		delegate.timerCallback?()

		XCTAssertFalse(sut.areControlsVisible)
		XCTAssertEqual(delegate.messages, [.didScheduleTimer(5.0), .didHide])
	}

	func test_scheduleHide_cancelsExistingTimer() {
		let (sut, delegate) = makeSUT()

		sut.scheduleHide()
		sut.scheduleHide()

		XCTAssertEqual(delegate.cancelTimerCallCount, 2)
	}

	func test_show_schedulesAutoHide() {
		let (sut, delegate) = makeSUT()
		sut.hide()
		delegate.messages.removeAll()

		sut.show()

		XCTAssertTrue(delegate.messages.contains(.didScheduleTimer(5.0)))
	}

	func test_hide_cancelsTimer() {
		let (sut, delegate) = makeSUT()
		sut.scheduleHide()

		sut.hide()

		XCTAssertEqual(delegate.cancelTimerCallCount, 2) // Once from scheduleHide, once from hide
	}

	// MARK: - Helpers

	private func makeSUT(
		delay: TimeInterval = 5.0,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: ControlsVisibilityController, delegate: ControlsVisibilityDelegateSpy) {
		let delegate = ControlsVisibilityDelegateSpy()
		let sut = ControlsVisibilityController(hideDelay: delay, delegate: delegate)
		trackForMemoryLeaks(sut, file: file, line: line)
		trackForMemoryLeaks(delegate, file: file, line: line)
		return (sut, delegate)
	}

	private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
		}
	}

	private class ControlsVisibilityDelegateSpy: ControlsVisibilityDelegate {
		enum Message: Equatable {
			case didShow
			case didHide
			case didScheduleTimer(TimeInterval)
		}

		var messages = [Message]()
		private(set) var cancelTimerCallCount = 0
		var timerCallback: (() -> Void)?

		func controlsDidShow() {
			messages.append(.didShow)
		}

		func controlsDidHide() {
			messages.append(.didHide)
		}

		func scheduleTimer(withDelay delay: TimeInterval, callback: @escaping () -> Void) {
			messages.append(.didScheduleTimer(delay))
			timerCallback = callback
		}

		func cancelTimer() {
			cancelTimerCallCount += 1
		}
	}
}
