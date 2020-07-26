import Foundation
import AVFoundation

#if canImport(UIKit)
import UIKit
#endif

public protocol PitchEngineDelegate: class {
    func pitchEngine(_ pitchEngine: PitchEngine, didReceive result: Result<Pitch, Error>)
}

public typealias PitchEngineCallback = (Result<Pitch, Error>) -> Void

public class PitchEngine {

    public enum Error: Swift.Error {
        case recordPermissionDenied
        case levelBelowThreshold
    }

    public let bufferSize: AVAudioFrameCount
    public private(set) var active = false
    public weak var delegate: PitchEngineDelegate?
    private var callback: PitchEngineCallback?

    private let estimator: Estimator
    private let signalTracker: SignalTracker
    private let queue = DispatchQueue(label: "TunaQueue", attributes: [])

    public var mode: SignalTrackerMode {
        return signalTracker.mode
    }

    public var levelThreshold: Float? {
        get {
            self.signalTracker.levelThreshold
        }
        set {
            self.signalTracker.levelThreshold = newValue
        }
    }

    public var signalLevel: Float {
        signalTracker.averageLevel ?? 0.0
    }

    // MARK: - Initialization

    public init(bufferSize: AVAudioFrameCount = 4096, estimationStrategy: EstimationStrategy = .yin, audioUrl: URL? = nil, signalTracker: SignalTracker? = nil, delegate: PitchEngineDelegate? = nil, callback: PitchEngineCallback? = nil) {

        self.bufferSize = bufferSize
        self.estimator  = estimationStrategy.estimator

        if let signalTracker = signalTracker {
            self.signalTracker = signalTracker
        } else {
            if let audioUrl = audioUrl {
                self.signalTracker = OutputSignalTracker(audioUrl: audioUrl, bufferSize: bufferSize)
            } else {
                self.signalTracker = InputSignalTracker(bufferSize: bufferSize)
            }
        }


        self.signalTracker.delegate = self
        self.delegate               = delegate
        self.callback               = callback
    }

    // MARK: - Processing

    public func start() {

        guard mode == .playback else {
            activate()
            return
        }

        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()

        switch audioSession.recordPermission {

        case .granted:
            activate()

        case .denied:
            DispatchQueue.main.async {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.openURL(settingsURL)
                }
            }

        case AVAudioSessionRecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                guard let self = self else { return }

                guard granted else {
                    self.delegate?.pitchEngine(self, didReceive: .failure(Error.recordPermissionDenied))
                    self.callback?(.failure(Error.recordPermissionDenied))
                    return
                }

                DispatchQueue.main.async {
                    self.activate()
                }
            }

        @unknown default:
            break
        }
        #endif
    }

    public func stop() {
        signalTracker.stop()
        active = false
    }

    func activate() {
        do {
            try signalTracker.start()
            active = true
        } catch {
            delegate?.pitchEngine(self, didReceive: .failure(error))
            callback?(.failure(error))
        }
    }
}

// MARK: - SignalTrackingDelegate

extension PitchEngine: SignalTrackerDelegate {

    public func signalTracker(_ signalTracker: SignalTracker, didReceiveBuffer buffer: AVAudioPCMBuffer, atTime time: AVAudioTime) {
        queue.async { [weak self] in
            guard let self = self else { return }

            do {
                let transformedBuffer = try self.estimator.transformer.transform(buffer: buffer)
                let frequency         = try self.estimator.estimateFrequency(sampleRate: Float(time.sampleRate), buffer: transformedBuffer)
                let pitch             = try Pitch(frequency: Double(frequency))

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.pitchEngine(self, didReceive: .success(pitch))
                    self.callback?(.success(pitch))
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.pitchEngine(self, didReceive: .failure(error))
                    self.callback?(.failure(error))
                }
            }
        }
    }

    public func signalTrackerWentBelowLevelThreshold(_ signalTracker: SignalTracker) {
        DispatchQueue.main.async {
            self.delegate?.pitchEngine(self, didReceive: .failure(Error.levelBelowThreshold))
            self.callback?(.failure(Error.levelBelowThreshold))
        }
    }

}
