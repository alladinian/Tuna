public struct AcousticWave {

    /// The speed of sound in air (m/s)
    public static let speed: Double = 343

    /// The frequency of the wave
    public let frequency: Double

    /// The wavelength
    public let wavelength: Double

    /// The period of the wave
    public let period: Double

    /// Up to 16 harmonic pitches
    public var harmonics: [Pitch] {
        var pitches = [Pitch]()

        do {
            for index in 1...16 {
                try pitches.append(Pitch(frequency: Double(index) * frequency))
            }
        } catch {
            debugPrint(error)
        }

        return pitches
    }

    // MARK: - Initialization

    /// Initialize a wave with a frequency
    /// - Parameter frequency: The frequency of the wave
    /// - Throws: An error in case wavelength or period cannot be calculated
    public init(frequency: Double) throws {
        try FrequencyValidator.validate(frequency: frequency)
        self.frequency = frequency
        wavelength     = try WaveCalculator.wavelength(forFrequency: frequency)
        period         = try WaveCalculator.period(forWavelength: wavelength)
    }

    /// Initialize a wave with a wavelength
    /// - Parameter wavelength: The wavelength
    /// - Throws: An error in case frequency or period cannot be calculated
    public init(wavelength: Double) throws {
        try WaveCalculator.validate(wavelength: wavelength)
        self.wavelength = wavelength
        frequency       = try WaveCalculator.frequency(forWavelength: wavelength)
        period          = try WaveCalculator.period(forWavelength: wavelength)
    }

    /// Initialize a wave with a period
    /// - Parameter period: The period of the wave
    /// - Throws: An error in case wavelength or frequency cannot be calculated
    public init(period: Double) throws {
        try WaveCalculator.validate(period: period)
        self.period = period
        wavelength  = try WaveCalculator.wavelength(forPeriod: period)
        frequency   = try WaveCalculator.frequency(forWavelength: wavelength)
    }
}
