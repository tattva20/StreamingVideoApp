//
//  CombineHelpers.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import Combine

public extension Publisher {
    func fallback(to fallbackPublisher: @escaping () -> AnyPublisher<Output, Failure>) -> AnyPublisher<Output, Failure> {
        self.catch { _ in fallbackPublisher() }.eraseToAnyPublisher()
    }
}

public extension Publisher where Output == [Video] {
    func caching(to cache: VideoCache) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: { videos in
            try? cache.save(videos)
        }).eraseToAnyPublisher()
    }
}

public extension Publisher where Output == Paginated<Video> {
    func caching(to cache: VideoCache) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: { page in
            try? cache.save(page.items)
        }).eraseToAnyPublisher()
    }
}

public extension Publisher {
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

public typealias AnyDispatchQueueScheduler = AnyScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>

public extension AnyDispatchQueueScheduler {
    static func scheduler(for store: CoreDataVideoStore) -> AnyDispatchQueueScheduler {
        CoreDataVideoStoreScheduler(store: store).eraseToAnyScheduler()
    }

    @MainActor
    private struct CoreDataVideoStoreScheduler: Scheduler {
        let store: CoreDataVideoStore

        var now: SchedulerTimeType { .init(.now()) }

        var minimumTolerance: SchedulerTimeType.Stride { .zero }

        func schedule(options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
            if store.contextQueue == .main, Thread.isMainThread {
                action()
            } else {
                nonisolated(unsafe) let uncheckedAction = action
                Task.immediate {
                    await store.perform { uncheckedAction() }
                }
            }
        }

        func schedule(after date: DispatchQueue.SchedulerTimeType, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
            if store.contextQueue == .main, Thread.isMainThread {
                action()
            } else {
                nonisolated(unsafe) let uncheckedAction = action
                Task.immediate {
                    await store.perform { uncheckedAction() }
                }
            }
        }

        func schedule(after date: DispatchQueue.SchedulerTimeType, interval: DispatchQueue.SchedulerTimeType.Stride, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) -> any Cancellable {
            if store.contextQueue == .main, Thread.isMainThread {
                action()
            } else {
                nonisolated(unsafe) let uncheckedAction = action
                Task.immediate {
                    await store.perform { uncheckedAction() }
                }
            }
            return AnyCancellable {}
        }
    }
}

public extension Scheduler {
    func eraseToAnyScheduler() -> AnyScheduler<SchedulerTimeType, SchedulerOptions> {
        AnyScheduler(self)
    }
}

public struct AnyScheduler<SchedulerTimeType: Strideable, SchedulerOptions>: Scheduler where SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {
    private let _now: () -> SchedulerTimeType
    private let _minimumTolerance: () -> SchedulerTimeType.Stride
    private let _schedule: (SchedulerOptions?, @escaping () -> Void) -> Void
    private let _scheduleAfter: (SchedulerTimeType, SchedulerTimeType.Stride, SchedulerOptions?, @escaping () -> Void) -> Void
    private let _scheduleAfterInterval: (SchedulerTimeType, SchedulerTimeType.Stride, SchedulerTimeType.Stride, SchedulerOptions?, @escaping () -> Void) -> Cancellable

    init<S>(_ scheduler: S) where SchedulerTimeType == S.SchedulerTimeType, SchedulerOptions == S.SchedulerOptions, S: Scheduler {
        _now = { scheduler.now }
        _minimumTolerance = { scheduler.minimumTolerance }
        _schedule = scheduler.schedule(options:_:)
        _scheduleAfter = scheduler.schedule(after:tolerance:options:_:)
        _scheduleAfterInterval = scheduler.schedule(after:interval:tolerance:options:_:)
    }

    public var now: SchedulerTimeType { _now() }

    public var minimumTolerance: SchedulerTimeType.Stride { _minimumTolerance() }

    public func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        _schedule(options, action)
    }

    public func schedule(after date: SchedulerTimeType, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
        _scheduleAfter(date, tolerance, options, action)
    }

    public func schedule(after date: SchedulerTimeType, interval: SchedulerTimeType.Stride, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
        _scheduleAfterInterval(date, interval, tolerance, options, action)
    }
}

public extension HTTPClient {
    typealias Publisher = AnyPublisher<(Data, HTTPURLResponse), Error>

    @MainActor
    func getPublisher(url: URL) -> Publisher {
        var task: Task<Void, Never>?

        return Deferred {
            Future { completion in
                nonisolated(unsafe) let uncheckedCompletion = completion
                task = Task.immediate {
                    do {
                        let result = try await self.get(from: url)
                        uncheckedCompletion(.success(result))
                    } catch {
                        uncheckedCompletion(.failure(error))
                    }
                }
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToAnyPublisher()
    }
}

public extension LocalVideoLoader {
	typealias Publisher = AnyPublisher<[Video], Error>

	func loadPublisher() -> Publisher {
		Deferred {
			Future { completion in
				completion(Result { try self.load() })
			}
		}
		.eraseToAnyPublisher()
	}
}

public extension VideoImageDataLoader {
    typealias Publisher = AnyPublisher<Data, Error>

    func loadImageDataPublisher(from url: URL) -> Publisher {
        Deferred {
            Future { completion in
                completion(Result { try self.loadImageData(from: url) })
            }
        }
        .eraseToAnyPublisher()
    }
}

public extension Publisher where Output == Data {
    func caching(to cache: VideoImageDataCache, for url: URL) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: { data in
            try? cache.save(data, for: url)
        }).eraseToAnyPublisher()
    }
}
