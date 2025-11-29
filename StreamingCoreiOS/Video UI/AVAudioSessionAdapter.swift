import Foundation
import AVFoundation

public final class AVAudioSessionAdapter: AudioSessionConfiguring {
    private let session: AudioSessionProtocol

    public convenience init() {
        self.init(session: AVAudioSession.sharedInstance())
    }

    init(session: AudioSessionProtocol) {
        self.session = session
    }

    public func configureForPlayback() throws {
        try session.setCategory(.playback, options: [])
        try session.setActive(true)
    }
}
