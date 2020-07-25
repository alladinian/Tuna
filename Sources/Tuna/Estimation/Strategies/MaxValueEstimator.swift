import Foundation

struct MaxValueEstimator: LocationEstimator {

    func estimateLocation(buffer: Buffer) throws -> Int {
        try maxBufferIndex(from: buffer.elements)
    }

}
