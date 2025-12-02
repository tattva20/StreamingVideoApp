//
//  VideoPlayerViewController.swift
//  StreamingCoreiOS
//
//  Created by Octavio Rojas on 02/12/25.
//

import UIKit
import StreamingCore

public final class VideoPlayerViewController: UIViewController {
	private let viewModel: VideoPlayerViewModel
	private let player: VideoPlayer

	public private(set) lazy var playButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "play.fill"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var playerView: PlayerView = {
		let view = PlayerView()
		view.backgroundColor = .black
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()

	public init(viewModel: VideoPlayerViewModel, player: VideoPlayer) {
		self.viewModel = viewModel
		self.player = player
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		setupUI()
		configurePlayer()
	}

	private func setupUI() {
		title = viewModel.title
		view.backgroundColor = .black

		view.addSubview(playerView)
		view.addSubview(playButton)

		NSLayoutConstraint.activate([
			playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 9.0/16.0),

			playButton.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
			playButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			playButton.widthAnchor.constraint(equalToConstant: 60),
			playButton.heightAnchor.constraint(equalToConstant: 60)
		])
	}

	private func configurePlayer() {
		player.load(url: viewModel.videoURL)
	}

	@objc private func playButtonTapped() {
		if player.isPlaying {
			player.pause()
			playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
		} else {
			player.play()
			playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
		}
	}
}
