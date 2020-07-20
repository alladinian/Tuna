public struct WaveCalculator {

    public static var wavelengthBounds: ClosedRange<Double> {
        let minimum = try! wavelength(forFrequency: FrequencyValidator.maximumFrequency)
        let maximum = try! wavelength(forFrequency: FrequencyValidator.minimumFrequency)

        return minimum ... maximum
    }

    public static var periodBounds: ClosedRange<Double> {
        let bounds = wavelengthBounds
        let minimum = try! period(forWavelength: bounds.lowerBound)
        let maximum = try! period(forWavelength: bounds.upperBound)

        return minimum ... maximum
    }

    // MARK: - Validators

    public static func isValid(wavelength: Double) -> Bool {
        wavelength > 0.0 && wavelengthBounds.contains(wavelength)
    }

    public static func validate(wavelength: Double) throws {
        if !isValid(wavelength: wavelength) {
            throw PitchError.invalidWavelength
        }
    }

    public static func isValid(period: Double) -> Bool {
        period > 0.0 && periodBounds.contains(period)
    }

    public static func validate(period: Double) throws {
        if !isValid(period: period) {
            throw PitchError.invalidPeriod
        }
    }

    // MARK: - Conversions

    public static func frequency(forWavelength wavelength: Double) throws -> Double {
        try WaveCalculator.validate(wavelength: wavelength)
        return AcousticWave.speed / wavelength
    }

    public static func wavelength(forFrequency frequency: Double) throws -> Double {
        try FrequencyValidator.validate(frequency: frequency)
        return AcousticWave.speed / frequency
    }

    public static func wavelength(forPeriod period: Double) throws -> Double {
        try WaveCalculator.validate(period: period)
        return period * AcousticWave.speed
    }

    public static func period(forWavelength wavelength: Double) throws -> Double {
        try WaveCalculator.validate(wavelength: wavelength)
        return wavelength / AcousticWave.speed
    }
}
