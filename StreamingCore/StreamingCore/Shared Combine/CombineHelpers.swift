//
//  CombineHelpers.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import Combine

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
