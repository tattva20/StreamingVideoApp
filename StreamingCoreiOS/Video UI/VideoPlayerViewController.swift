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

        let playerItem = AVPlayerItem(url: video.url)
        player = AVPlayer(playerItem: playerItem)
    }
}
