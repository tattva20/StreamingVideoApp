import Foundation
import AVFoundation

protocol AudioSessionProtocol {
    func setCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions) throws
    func setActive(_ active: Bool) throws
}

extension AVAudioSession: AudioSessionProtocol {
    func setCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions) throws {
        try setCategory(category, mode: .default, options: options)
    }

    func setActive(_ active: Bool) throws {
        try setActive(active, options: [])
    }
}
