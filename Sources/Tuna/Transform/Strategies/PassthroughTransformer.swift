import AVFoundation

struct PassthroughTransformer: Transformer {

    enum PassthroughTransformerError: Error {
        case floatChannelDataIsNil
    }

    func transform(buffer: AVAudioPCMBuffer) throws -> Buffer {
        guard let pointer = buffer.floatChannelData else {
            throw PassthroughTransformerError.floatChannelDataIsNil
        }

        let elements = Array.fromUnsafePointer(pointer.pointee, count: Int(buffer.frameLength))
        return Buffer(elements: elements)
    }

}
