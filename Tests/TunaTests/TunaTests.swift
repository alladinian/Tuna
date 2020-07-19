import XCTest
import Accelerate
import AVFoundation
@testable import Tuna

final class TunaTests: XCTestCase {

    var estimator: Estimator!

    override func setUp() {
        super.setUp()
        estimator = HPSEstimator()
    }

    func testConfig() {
        let config = Config()
        XCTAssertEqual(config.bufferSize, 4096)
        XCTAssertEqual(config.estimationStrategy, EstimationStrategy.yin)
        XCTAssertNil(config.audioUrl)
    }

    func testEstimationFactory() {

        // QuadradicEstimator
        XCTAssertTrue(EstimationStrategy.quadradic.estimator is QuadradicEstimator)

        // Barycentric
        XCTAssertTrue(EstimationStrategy.barycentric.estimator is BarycentricEstimator)

        // QuinnsFirst
        XCTAssertTrue(EstimationStrategy.quinnsFirst.estimator is QuinnsFirstEstimator)


        // QuinnsSecond
        XCTAssertTrue(EstimationStrategy.quinnsSecond.estimator is QuinnsSecondEstimator)


        // Jains
        XCTAssertTrue(EstimationStrategy.jains.estimator is JainsEstimator)


        // HPS
        XCTAssertTrue(EstimationStrategy.hps.estimator is HPSEstimator)


        // YIN
        XCTAssertTrue(EstimationStrategy.yin.estimator is YINEstimator)


        // MaxValue
        XCTAssertTrue(EstimationStrategy.maxValue.estimator is MaxValueEstimator)
    }

    func testEstimatorBuffer() {
        let array: [Float] = [0.1, 0.3, 0.2]
        let result = try! estimator.maxBufferIndex(from: array)

        XCTAssertEqual(result, 1, "returns the index of the max element in the array")
    }

    func testEstimatorSanitizeInBounds() {
        let array: [Float] = [0.1, 0.3, 0.2]
        let result = estimator.sanitize(location: 1, reserveLocation: 0, elements: array)

        XCTAssertEqual(result, 1, "returns the passed location if it doesn't extend array bounds")
    }

    func testEstimatorOutOfBounds() {
        let array: [Float] = [0.1, 0.3, 0.2]
        let result = estimator.sanitize(location: 4, reserveLocation: 0, elements: array)

        XCTAssertEqual(result, 0, "returns the reserve location if the passed location extends array bounds")
    }

    func testArrayExtensions() {
        var array = [0.1, 0.3, 0.2]
        let result = Array.fromUnsafePointer(&array, count: 3)

        XCTAssertEqual(result, array)
        XCTAssertEqual(array.maxIndex, 1)
    }

    func testBuffer() {
        let buffer = Buffer(elements: [0.1, 0.2, 0.3])
        XCTAssertEqual(buffer.count, 3)
    }

    func testFFT() {
        let transformer = FFTTransformer()
        let array: [Float] = [0.1, 0.2, 0.3]
        var expected = [Float](repeating: 0.0, count: array.count)
        vvsqrtf(&expected, array, [Int32(array.count)])

        XCTAssertEqual(transformer.sqrtq(array), expected, "returns the array's square")
    }

    static var allTests = [
        ("testConfig", testConfig),
        ("testEstimationFactory", testEstimationFactory),
        ("testEstimatorBuffer", testEstimatorBuffer),
        ("testEstimatorSanitizeInBounds", testEstimatorSanitizeInBounds),
        ("testEstimatorOutOfBounds", testEstimatorOutOfBounds),
        ("testArrayExtensions", testArrayExtensions),
        ("testBuffer", testBuffer),
        ("testFFT", testFFT),
    ]
}
