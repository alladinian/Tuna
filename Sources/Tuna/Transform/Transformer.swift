import AVFoundation

/// A protocol for Buffer transoformers
protocol Transformer {
    /// Transform an AVAudioPCMBuffer to a Buffer
    /// - Parameter buffer: The AVAudioPCMBuffer input
    func transform(buffer: AVAudioPCMBuffer) throws -> Buffer
}
