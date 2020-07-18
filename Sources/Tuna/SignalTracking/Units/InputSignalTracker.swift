import AVFoundation

public enum InputSignalTrackerError: Error {
    case inputNodeMissing
}

final class InputSignalTracker: SignalTracker {
    weak var delegate: SignalTrackerDelegate?
    var levelThreshold: Float?

    private let bufferSize: AVAudioFrameCount
    private var audioChannel: AVCaptureAudioChannel?
    private let captureSession = AVCaptureSession()
    private var audioEngine: AVAudioEngine?
    #if os(iOS)
    private let session = AVAudioSession.sharedInstance()
    #endif
    private let bus = 0

    var peakLevel: Float? {
        audioChannel?.peakHoldLevel
    }

    var averageLevel: Float? {
        audioChannel?.averagePowerLevel
    }

    var mode: SignalTrackerMode {
        .record
    }

    // MARK: - Initialization

    required init(bufferSize: AVAudioFrameCount = 2048, delegate: SignalTrackerDelegate? = nil) {
        self.bufferSize = bufferSize
        self.delegate   = delegate
        setupAudio()
    }

    // MARK: - Tracking

    func start() throws {

        #if os(iOS)
        try session.setCategory(.playAndRecord)

        // check input type
        let outputs = session.currentRoute.outputs
        if !outputs.isEmpty {
            for output in outputs {
                switch output.portType {
                case .headphones:
                    // input from default (headphones)
                    try session.overrideOutputAudioPort(.none)
                default:
                    // input from speaker if port is not headphones
                    try session.overrideOutputAudioPort(.speaker)
                }
            }
        }
        #endif

        audioEngine = AVAudioEngine()

        guard let inputNode = audioEngine?.inputNode else {
            throw InputSignalTrackerError.inputNodeMissing
        }

        let format = inputNode.outputFormat(forBus: bus)

        inputNode.installTap(onBus: bus, bufferSize: bufferSize, format: format) { buffer, time in
            guard let averageLevel = self.averageLevel else { return }

            let levelThreshold = self.levelThreshold ?? -1000000.0

            DispatchQueue.main.async {
                if averageLevel > levelThreshold {
                    self.delegate?.signalTracker(self, didReceiveBuffer: buffer, atTime: time)
                } else {
                    self.delegate?.signalTrackerWentBelowLevelThreshold(self)
                }
            }
        }

        try audioEngine?.start()
        captureSession.startRunning()

        guard captureSession.isRunning == true else {
            throw InputSignalTrackerError.inputNodeMissing
        }
    }

    func stop() {
        guard audioEngine != nil else {
            return
        }

        audioEngine?.stop()
        audioEngine?.reset()
        audioEngine = nil
        captureSession.stopRunning()
    }

    private func setupAudio() {
        do {
            let audioDevice       = AVCaptureDevice.default(for: AVMediaType.audio)
            let audioCaptureInput = try AVCaptureDeviceInput(device: audioDevice!)
            let audioOutput       = AVCaptureAudioDataOutput()

            captureSession.addInput(audioCaptureInput)
            captureSession.addOutput(audioOutput)

            let connection = audioOutput.connections[0]
            audioChannel   = connection.audioChannels[0]
        } catch {
            debugPrint(error)
        }
    }
}
