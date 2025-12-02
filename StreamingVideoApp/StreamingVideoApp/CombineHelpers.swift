//
//  CombineHelpers.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import Combine
import StreamingCore
import UIKit

extension Publisher {
    func dispatchOnMainThread() -> AnyPublisher<Output, Failure> {
        receive(on: DispatchQueue.immediateWhenOnMainThreadScheduler).eraseToAnyPublisher()
    }
}

extension DispatchQueue {
    static var immediateWhenOnMainThreadScheduler: ImmediateWhenOnMainThreadScheduler {
        ImmediateWhenOnMainThreadScheduler()
    }

    struct ImmediateWhenOnMainThreadScheduler: Scheduler {
        typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
        typealias SchedulerOptions = DispatchQueue.SchedulerOptions

        var now: SchedulerTimeType {
            DispatchQueue.main.now
        }

        var minimumTolerance: SchedulerTimeType.Stride {
            DispatchQueue.main.minimumTolerance
        }

        func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
            guard Thread.isMainThread else {
                return DispatchQueue.main.schedule(options: options, action)
            }

            action()
        }

        func schedule(after date: SchedulerTimeType, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
            DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: options, action)
        }

        func schedule(after date: SchedulerTimeType, interval: SchedulerTimeType.Stride, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
            DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: options, action)
        }
    }
}

extension NotificationCenter {
	func addObserver(of object: AnyObject, for notification: UIApplication.Notification, using block: @escaping (Notification) -> Void) -> Any {
		addObserver(forName: notification.name, object: object, queue: .main, using: block)
	}
}

extension UIApplication {
	enum Notification {
		case willEnterForeground

		var name: NSNotification.Name {
			switch self {
			case .willEnterForeground:
				return UIApplication.willEnterForegroundNotification
			}
		}
	}
}
