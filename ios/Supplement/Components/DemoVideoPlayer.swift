import SwiftUI
import AVKit
import AVFoundation

/// Describes a bundled demo clip shown from a page's tutorial.
struct TutorialDemo {
    let resource: String   // bundled <resource>.mp4
    let title: String
    let caption: String
}

/// Hosts an AVPlayerLayer so the demo plays without the system transport chrome.
private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> PlayerUIView { PlayerUIView(player: player) }
    func updateUIView(_ uiView: PlayerUIView, context: Context) {}
}

private final class PlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// Full-screen demo pop-up: a muted, looping bundled MP4 with a caption and close button.
struct DemoVideoView: View {
    let demo: TutorialDemo
    @Environment(\.dismiss) private var dismiss

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player {
                PlayerLayerView(player: player)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "play.slash.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Demo unavailable")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            VStack {
                HStack {
                    Text(demo.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.white.opacity(0.18), in: Circle())
                    }
                    .accessibilityLabel("Close demo")
                }
                .padding()

                Spacer()

                Text(demo.caption)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
            }
        }
        .onAppear(perform: start)
        .onDisappear { player?.pause() }
    }

    private func start() {
        guard player == nil,
              let url = Bundle.main.url(forResource: demo.resource, withExtension: "mp4") else { return }
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        queue.isMuted = true
        looper = AVPlayerLooper(player: queue, templateItem: item)
        player = queue
        queue.play()
    }
}
