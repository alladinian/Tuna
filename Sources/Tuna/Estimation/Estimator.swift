protocol Estimator {
    var transformer: Transformer { get }
    func estimateFrequency(sampleRate: Float, buffer: Buffer) throws -> Float
    func estimateFrequency(sampleRate: Float, location: Int, bufferCount: Int) -> Float
}

// MARK: - Default implementations

extension Estimator {
    func estimateFrequency(sampleRate: Float, location: Int, bufferCount: Int) -> Float {
        Float(location) * sampleRate / (Float(bufferCount) * 2)
    }

    func maxBufferIndex(from buffer: [Float]) throws -> Int {
        guard !buffer.isEmpty else {
            throw EstimationError.emptyBuffer
        }

        guard let index = buffer.maxIndex else {
            throw EstimationError.unknownMaxIndex
        }

        return index
    }

    func sanitize(location: Int, reserveLocation: Int, elements: [Float]) -> Int {
        (location >= 0 && location < elements.count) ? location : reserveLocation
    }
}
