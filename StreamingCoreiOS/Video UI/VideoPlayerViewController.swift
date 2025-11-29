import UIKit
import AVKit
import StreamingCore

public final class VideoPlayerViewController: AVPlayerViewController {
    private let video: Video

    public init(video: Video) {
        self.video = video
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        configurePictureInPicture()
        configurePlayer()
    }

    private func configurePictureInPicture() {
        // Enable Picture-in-Picture
        // This allows video to continue playing in a floating window
        // when the user navigates away from the app
        allowsPictureInPicturePlayback = true
    }

    private func configurePlayer() {
        let playerItem = AVPlayerItem(url: video.url)
        player = AVPlayer(playerItem: playerItem)
    }
}
