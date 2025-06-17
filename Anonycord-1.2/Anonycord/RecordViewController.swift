import UIKit
import AVFoundation
import AVKit

class RecordViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    var session: AVCaptureSession?
    var output: AVCaptureMovieFileOutput?
    var isRecording = false
    var playerViewController: AVPlayerViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        UIApplication.shared.isIdleTimerDisabled = true

        playBlackLoopVideo()
        addDoubleTapToToggleRecording()
        observeAppLifecycle()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - Black Loop Video Playback
    func playBlackLoopVideo() {
        guard let path = Bundle.main.path(forResource: "blackloop", ofType:"mp4") else {
            print("❌ blackloop.mp4 not found")
            return
        }

        let player = AVPlayer(url: URL(fileURLWithPath: path))
        player.actionAtItemEnd = .none

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem,
                                               queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }

        let playerVC = AVPlayerViewController()
        playerVC.player = player
        playerVC.showsPlaybackControls = false
        playerVC.modalPresentationStyle = .fullScreen
        playerVC.view.frame = view.bounds
        playerVC.entersFullScreenWhenPlaybackBegins = true
        playerVC.exitsFullScreenWhenPlaybackEnds = false

        addChild(playerVC)
        view.addSubview(playerVC.view)
        playerVC.didMove(toParent: self)
        player.play()

        self.playerViewController = playerVC
    }

    // MARK: - Double Tap Gesture
    func addDoubleTapToToggleRecording() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleRecording))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
    }

    @objc func toggleRecording() {
        vibrate()
        if isRecording {
            stopRecording()
        } else {
            checkCameraPermission { granted in
                if granted {
                    self.startCameraAndRecording()
                } else {
                    print("Camera permission denied")
                }
            }
        }
    }

    // MARK: - Camera Permission
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }

    // MARK: - Camera Start/Stop
    func startCameraAndRecording() {
        session = AVCaptureSession()
        session?.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session?.canAddInput(input) == true else {
            print("❌ Failed to configure camera input")
            return
        }

        session?.addInput(input)

        output = AVCaptureMovieFileOutput()
        if let output = output, session?.canAddOutput(output) == true {
            session?.addOutput(output)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.session?.startRunning()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let folder = self.getVIPCDirectory()
                let filename = self.formattedDate() + ".php"
                let fileURL = folder.appendingPathComponent(filename)
                self.output?.startRecording(to: fileURL, recordingDelegate: self)
                self.isRecording = true
            }
        }
    }

    func stopRecording() {
        output?.stopRecording()
        isRecording = false
        cleanupCamera()
    }

    func cleanupCamera() {
        session?.stopRunning()
        session = nil
        output = nil
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo url: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            print("Recording error: \(error.localizedDescription)")
        } else {
            print("✅ Saved to: \(url)")
        }
    }

    // MARK: - App Background Stop
    func observeAppLifecycle() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(stopIfInBackground),
            name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc func stopIfInBackground() {
        if isRecording {
            stopRecording()
        }
    }

    // MARK: - Utilities
    func vibrate() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func getVIPCDirectory() -> URL {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let vipc = docs.appendingPathComponent("vipc")
        if !fileManager.fileExists(atPath: vipc.path) {
            try? fileManager.createDirectory(at: vipc, withIntermediateDirectories: true)
        }
        return vipc
    }

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}
