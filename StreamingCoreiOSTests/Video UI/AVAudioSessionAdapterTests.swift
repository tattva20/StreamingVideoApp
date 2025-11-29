import XCTest
import AVFoundation
@testable import StreamingCoreiOS

final class AVAudioSessionAdapterTests: XCTestCase {

    func test_configureForPlayback_setsPlaybackCategory() {
        let audioSession = AudioSessionSpy()
        let sut = makeSUT(session: audioSession)

        try? sut.configureForPlayback()

        XCTAssertTrue(audioSession.messages.contains(.setCategory(.playback, [])))
    }

    func test_configureForPlayback_activatesSession() {
        let audioSession = AudioSessionSpy()
        let sut = makeSUT(session: audioSession)

        try? sut.configureForPlayback()

        XCTAssertTrue(audioSession.messages.contains(.setActive(true)))
    }

    func test_configureForPlayback_setsActivatedAfterCategory() {
        let audioSession = AudioSessionSpy()
        let sut = makeSUT(session: audioSession)

        try? sut.configureForPlayback()

        XCTAssertEqual(audioSession.messages, [
            .setCategory(.playback, []),
            .setActive(true)
        ])
    }

    func test_configureForPlayback_throwsErrorOnCategoryFailure() {
        let audioSession = AudioSessionSpy()
        audioSession.setCategoryError = anyNSError()
        let sut = makeSUT(session: audioSession)

        XCTAssertThrowsError(try sut.configureForPlayback())
    }

    func test_configureForPlayback_throwsErrorOnActivationFailure() {
        let audioSession = AudioSessionSpy()
        audioSession.setActiveError = anyNSError()
        let sut = makeSUT(session: audioSession)

        XCTAssertThrowsError(try sut.configureForPlayback())
    }

    func test_configureForPlayback_doesNotActivateWhenCategoryFails() {
        let audioSession = AudioSessionSpy()
        audioSession.setCategoryError = anyNSError()
        let sut = makeSUT(session: audioSession)

        _ = try? sut.configureForPlayback()

        XCTAssertEqual(audioSession.messages, [.setCategory(.playback, [])])
    }

    // MARK: - Helpers

    private func makeSUT(session: AudioSessionProtocol) -> AVAudioSessionAdapter {
        return AVAudioSessionAdapter(session: session)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}

// MARK: - Test Doubles

private class AudioSessionSpy: AudioSessionProtocol {
    enum Message: Equatable {
        case setCategory(AVAudioSession.Category, AVAudioSession.CategoryOptions)
        case setActive(Bool)
    }

    var messages = [Message]()
    var setCategoryError: Error?
    var setActiveError: Error?

    func setCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions) throws {
        messages.append(.setCategory(category, options))
        if let error = setCategoryError {
            throw error
        }
    }

    func setActive(_ active: Bool) throws {
        messages.append(.setActive(active))
        if let error = setActiveError {
            throw error
        }
    }
}
