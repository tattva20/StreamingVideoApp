//
//  LoaderSpy.swift
//  Tattva
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

enum AsyncResult {
	case success
	case failure
	case cancelled
}

@MainActor
class LoaderSpy<Param, Resource: Sendable> {
	private(set) var requests = [(
		param: Param,
		stream: AsyncThrowingStream<Resource, Error>,
		continuation: AsyncThrowingStream<Resource, Error>.Continuation,
		result: AsyncResult?
	)]()

	private struct NoResponse: Error {}
	private struct Timeout: Error {}

	func load(_ param: Param) async throws -> Resource {
		let (stream, continuation) = AsyncThrowingStream<Resource, Error>.makeStream()
		let index = requests.count
		requests.append((param, stream, continuation, nil))

		do {
			for try await result in stream {
				try Task.checkCancellation()
				requests[index].result = .success
				return result
			}

			try Task.checkCancellation()

			throw NoResponse()
		} catch {
			requests[index].result = Task.isCancelled ? .cancelled : .failure
			throw error
		}
	}

	func complete(with resource: Resource, at index: Int, timeout: TimeInterval = 1) async {
		requests[index].continuation.yield(resource)
		requests[index].continuation.finish()

		_ = try? await waitForResult(at: index, timeout: timeout)
	}

	func fail(with error: Error, at index: Int, timeout: TimeInterval = 1) async {
		requests[index].continuation.finish(throwing: error)

		_ = try? await waitForResult(at: index, timeout: timeout)
	}

	@discardableResult
	func result(at index: Int, timeout: TimeInterval = 1) async throws -> AsyncResult {
		try await waitForResult(at: index, timeout: timeout)
	}

	func cancelPendingRequests(timeout: TimeInterval = 1) async {
		for (index, request) in requests.enumerated() where request.result == nil {
			request.continuation.finish(throwing: CancellationError())

			_ = try? await waitForResult(at: index, timeout: timeout)
		}
	}

	private func waitForResult(at index: Int, timeout: TimeInterval) async throws -> AsyncResult {
		let maxDate = Date() + timeout

		while Date() <= maxDate {
			if let result = requests[index].result {
				return result
			}

			await Task.yield()
		}

		throw Timeout()
	}
}
