import AVFoundation
import Accelerate

/// An FFT Transformer
struct FFTTransformer: Transformer {

    func transform(buffer: AVAudioPCMBuffer) throws -> Buffer {
        let frameCount    = Double(buffer.frameLength)
        let log2n         = UInt(round(log2(frameCount)))
        let bufferSizePOT = Int(1 << log2n)
        let inputCount    = bufferSizePOT / 2
        let fftSetup      = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))

        var realp = [Float](repeating: 0, count: inputCount)
        var imagp = [Float](repeating: 0, count: inputCount)

        let windowSize     = bufferSizePOT
        var transferBuffer = [Float](repeating: 0, count: windowSize)
        var window         = [Float](repeating: 0, count: windowSize)

        var normalizedMagnitudes = [Float](repeating: 0.0, count: inputCount)

        realp.withUnsafeMutableBufferPointer { realBP in
            imagp.withUnsafeMutableBufferPointer { imaginaryBP in
                var output = DSPSplitComplex(realp: realBP.baseAddress!, imagp: imaginaryBP.baseAddress!)

                // Hann windowing to reduce the frequency leakage
                vDSP_hann_window(&window, vDSP_Length(windowSize), Int32(vDSP_HANN_NORM))
                vDSP_vmul((buffer.floatChannelData?.pointee)!, 1, window, 1, &transferBuffer, 1, vDSP_Length(windowSize))

                // Transforming the [Float] buffer into a UnsafePointer<Float> object for the vDSP_ctoz method
                // And then pack the input into the complex buffer (output)
                let temp = UnsafePointer<Float>(transferBuffer)
                temp.withMemoryRebound(to: DSPComplex.self, capacity: transferBuffer.count) { typeConvertedTransferBuffer in
                    vDSP_ctoz(typeConvertedTransferBuffer, 2, &output, 1, vDSP_Length(inputCount))
                }

                // Perform the FFT
                vDSP_fft_zrip(fftSetup!, &output, 1, log2n, FFTDirection(FFT_FORWARD))

                var magnitudes = [Float](repeating: 0.0, count: inputCount)
                vDSP_zvmags(&output, 1, &magnitudes, 1, vDSP_Length(inputCount))

                // Normalising
                vDSP_vsmul(sqrtq(magnitudes), 1, [2.0 / Float(inputCount)], &normalizedMagnitudes, 1, vDSP_Length(inputCount))
            }
        }

        let buffer = Buffer(elements: normalizedMagnitudes)

        vDSP_destroy_fftsetup(fftSetup)

        return buffer
    }

    @available(iOS 13.0, OSX 10.15, *)
    func fft(buffer: AVAudioPCMBuffer) throws -> Buffer {
        let frameCount        = buffer.frameLength
        let log2n             = vDSP_Length(log2(Float(frameCount)))
        let halfN             = Int(frameCount / 2)
        var forwardInputReal  = [Float](repeating: 0, count: halfN)
        var forwardInputImag  = [Float](repeating: 0, count: halfN)
        var forwardOutputReal = [Float](repeating: 0, count: halfN)
        var forwardOutputImag = [Float](repeating: 0,  count: halfN)

        let data        = buffer.floatChannelData?[0]
        let arrayOfData = Array(UnsafeBufferPointer(start: data, count: Int(buffer.frameLength)))

        let tau: Float = .pi * 2
        let signal: [Float] = (0 ... frameCount).map { index in
            arrayOfData.reduce(0) { accumulator, frequency in
                let normalizedIndex = Float(index) / Float(frameCount)
                return accumulator + sin(normalizedIndex * frequency * tau)
            }
        }

        guard let fftSetUp = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self) else {
            fatalError("Can't create FFT Setup.")
        }

        forwardInputReal.withUnsafeMutableBufferPointer { forwardInputRealPtr in
            forwardInputImag.withUnsafeMutableBufferPointer { forwardInputImagPtr in
                forwardOutputReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
                    forwardOutputImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in

                        // 1: Create a `DSPSplitComplex` to contain the signal.
                        var forwardInput = DSPSplitComplex(realp: forwardInputRealPtr.baseAddress!, imagp: forwardInputImagPtr.baseAddress!)

                        // 2: Convert the real values in `signal` to complex numbers.
                        signal.withUnsafeBytes {
                            vDSP.convert(interleavedComplexVector: [DSPComplex]($0.bindMemory(to: DSPComplex.self)), toSplitComplexVector: &forwardInput)
                        }

                        // 3: Create a `DSPSplitComplex` to receive the FFT result.
                        var forwardOutput = DSPSplitComplex(realp: forwardOutputRealPtr.baseAddress!, imagp: forwardOutputImagPtr.baseAddress!)

                        // 4: Perform the forward FFT.
                        fftSetUp.forward(input: forwardInput, output: &forwardOutput)
                    }
                }
            }
        }

        return Buffer(elements: forwardOutputReal)
    }

    // MARK: - Helpers

    /// Calculate the square roots of the elements in a [Float]
    /// - Parameter x: The float array
    /// - Returns: An array with the square roots
    func sqrtq(_ x: [Float]) -> [Float] {
        var results = [Float](repeating: 0.0, count: x.count)
        vvsqrtf(&results, x, [Int32(x.count)])
        return results
    }

}
