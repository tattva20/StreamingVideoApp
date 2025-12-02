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

	public private(set) lazy var seekForwardButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "goforward.10"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(seekForwardButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var seekBackwardButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "gobackward.10"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(seekBackwardButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var progressSlider: UISlider = {
		let slider = UISlider()
		slider.minimumValue = 0
		slider.maximumValue = 1
		slider.minimumTrackTintColor = .white
		slider.maximumTrackTintColor = .gray
		slider.addTarget(self, action: #selector(progressSliderValueChanged), for: .valueChanged)
		slider.translatesAutoresizingMaskIntoConstraints = false
		return slider
	}()

	public private(set) lazy var currentTimeLabel: UILabel = {
		let label = UILabel()
		label.textColor = .white
		label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
		label.text = "0:00"
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

	public private(set) lazy var durationLabel: UILabel = {
		let label = UILabel()
		label.textColor = .white
		label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
		label.text = "0:00"
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

	public private(set) lazy var muteButton: UIButton = {
		let button = UIButton(type: .system)
		button.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
		button.tintColor = .white
		button.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	public private(set) lazy var volumeSlider: UISlider = {
		let slider = UISlider()
		slider.minimumValue = 0
		slider.maximumValue = 1
		slider.value = 1
		slider.minimumTrackTintColor = .white
		slider.maximumTrackTintColor = .gray
		slider.addTarget(self, action: #selector(volumeSliderValueChanged), for: .valueChanged)
		slider.translatesAutoresizingMaskIntoConstraints = false
		return slider
	}()

	public private(set) lazy var playbackSpeedButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle("1x", for: .normal)
		button.setTitleColor(.white, for: .normal)
		button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
		button.addTarget(self, action: #selector(playbackSpeedButtonTapped), for: .touchUpInside)
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
		view.addSubview(seekForwardButton)
		view.addSubview(seekBackwardButton)
		view.addSubview(progressSlider)
		view.addSubview(currentTimeLabel)
		view.addSubview(durationLabel)
		view.addSubview(muteButton)
		view.addSubview(volumeSlider)
		view.addSubview(playbackSpeedButton)

		NSLayoutConstraint.activate([
			playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 9.0/16.0),

			playButton.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
			playButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			playButton.widthAnchor.constraint(equalToConstant: 60),
			playButton.heightAnchor.constraint(equalToConstant: 60),

			seekBackwardButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			seekBackwardButton.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -40),
			seekBackwardButton.widthAnchor.constraint(equalToConstant: 44),
			seekBackwardButton.heightAnchor.constraint(equalToConstant: 44),

			seekForwardButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
			seekForwardButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 40),
			seekForwardButton.widthAnchor.constraint(equalToConstant: 44),
			seekForwardButton.heightAnchor.constraint(equalToConstant: 44),

			currentTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
			currentTimeLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -16),

			durationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
			durationLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -16),

			progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 8),
			progressSlider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
			progressSlider.centerYAnchor.constraint(equalTo: currentTimeLabel.centerYAnchor),

			muteButton.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 16),
			muteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
			muteButton.widthAnchor.constraint(equalToConstant: 44),
			muteButton.heightAnchor.constraint(equalToConstant: 44),

			volumeSlider.centerYAnchor.constraint(equalTo: muteButton.centerYAnchor),
			volumeSlider.leadingAnchor.constraint(equalTo: muteButton.trailingAnchor, constant: 8),
			volumeSlider.widthAnchor.constraint(equalToConstant: 120),

			playbackSpeedButton.centerYAnchor.constraint(equalTo: muteButton.centerYAnchor),
			playbackSpeedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
			playbackSpeedButton.widthAnchor.constraint(equalToConstant: 50)
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

	@objc private func seekForwardButtonTapped() {
		player.seekForward(by: 10)
	}

	@objc private func seekBackwardButtonTapped() {
		player.seekBackward(by: 10)
	}

	@objc private func progressSliderValueChanged() {
		let targetTime = TimeInterval(progressSlider.value) * player.duration
		player.seek(to: targetTime)
	}

	@objc private func muteButtonTapped() {
		player.toggleMute()
		updateMuteButtonIcon()
	}

	@objc private func volumeSliderValueChanged() {
		player.setVolume(volumeSlider.value)
	}

	private func updateMuteButtonIcon() {
		let iconName = player.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
		muteButton.setImage(UIImage(systemName: iconName), for: .normal)
	}

	private static let playbackSpeeds: [Float] = [1.0, 1.25, 1.5, 2.0, 0.5]

	@objc private func playbackSpeedButtonTapped() {
		let currentSpeed = player.playbackSpeed
		let currentIndex = Self.playbackSpeeds.firstIndex(of: currentSpeed) ?? 0
		let nextIndex = (currentIndex + 1) % Self.playbackSpeeds.count
		let newSpeed = Self.playbackSpeeds[nextIndex]
		player.setPlaybackSpeed(newSpeed)
		updatePlaybackSpeedButtonTitle()
	}

	private func updatePlaybackSpeedButtonTitle() {
		let speed = player.playbackSpeed
		let title = speed == 1.0 ? "1x" : String(format: "%.2gx", speed)
		playbackSpeedButton.setTitle(title, for: .normal)
	}

	public func updateTimeDisplay() {
		currentTimeLabel.text = formatTime(player.currentTime)
		durationLabel.text = formatTime(player.duration)

		if player.duration > 0 {
			progressSlider.value = Float(player.currentTime / player.duration)
		}
	}

	private func formatTime(_ time: TimeInterval) -> String {
		guard time.isFinite && !time.isNaN else { return "0:00" }

		let totalSeconds = Int(time)
		let hours = totalSeconds / 3600
		let minutes = (totalSeconds % 3600) / 60
		let seconds = totalSeconds % 60

		if hours > 0 {
			return String(format: "%d:%02d:%02d", hours, minutes, seconds)
		} else {
			return String(format: "%d:%02d", minutes, seconds)
		}
	}
}
