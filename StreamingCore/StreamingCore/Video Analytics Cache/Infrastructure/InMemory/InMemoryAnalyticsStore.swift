//
//  InMemoryAnalyticsStore.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

public actor InMemoryAnalyticsStore: AnalyticsStore {
    private var sessions: [UUID: LocalPlaybackSession] = [:]
    private var events: [UUID: [LocalPlaybackEvent]] = [:]

    public init() {}

    public func insert(_ session: LocalPlaybackSession) async throws {
        sessions[session.id] = session
        events[session.id] = []
    }

    public func insertEvent(_ event: LocalPlaybackEvent) async throws {
        events[event.sessionID, default: []].append(event)
    }

    public func updateSession(_ session: LocalPlaybackSession) async throws {
        sessions[session.id] = session
    }

    public func retrieve(sessionID: UUID) async throws -> (session: LocalPlaybackSession, events: [LocalPlaybackEvent])? {
        guard let session = sessions[sessionID] else { return nil }
        return (session, events[sessionID] ?? [])
    }

    public func retrieveAllSessions() async throws -> [LocalPlaybackSession] {
        Array(sessions.values)
    }

    public func deleteSession(_ sessionID: UUID) async throws {
        sessions.removeValue(forKey: sessionID)
        events.removeValue(forKey: sessionID)
    }

    public func deleteAllSessions() async throws {
        sessions.removeAll()
        events.removeAll()
    }
}
