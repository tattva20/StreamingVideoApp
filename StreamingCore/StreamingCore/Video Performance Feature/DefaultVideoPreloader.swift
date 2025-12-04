//
//  DefaultVideoPreloader.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

/// Default implementation of VideoPreloader using an actor for thread-safety.
/// Following Essential Feed patterns for clean architecture and async/await.
public actor DefaultVideoPreloader: VideoPreloader {
	private var activeTasks: [UUID: Task<Void, Never>] = [:]
	private let httpClient: HTTPClient

	public init(httpClient: HTTPClient) {
		self.httpClient = httpClient
	}

	public func preload(_ video: PreloadableVideo, priority: PreloadPriority) async {
		// Cancel existing task for this video if any
		activeTasks[video.id]?.cancel()

		let task = Task { [httpClient] in
			guard !Task.isCancelled else { return }

			do {
				_ = try await httpClient.get(from: video.url)
			} catch {
				// Preload failures are expected (network issues, cancellation)
				// We silently ignore them as preloading is opportunistic
			}
		}

		activeTasks[video.id] = task

		// For immediate priority, await completion
		if priority == .immediate {
			await task.value
		}
	}

	nonisolated public func cancelPreload(for videoID: UUID) {
		Task {
			await cancelPreloadAsync(for: videoID)
		}
	}

	private func cancelPreloadAsync(for videoID: UUID) {
		activeTasks[videoID]?.cancel()
		activeTasks[videoID] = nil
	}

	nonisolated public func cancelAllPreloads() {
		Task {
			await cancelAllPreloadsAsync()
		}
	}

	private func cancelAllPreloadsAsync() {
		for task in activeTasks.values {
			task.cancel()
		}
		activeTasks.removeAll()
	}
}
