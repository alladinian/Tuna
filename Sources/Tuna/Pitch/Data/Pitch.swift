/// A structure representing a Pitch
public struct Pitch {

    /// A tuple holding offset information
    public typealias Offset = (note: Note, frequency: Double, percentage: Double, cents: Double)

    /// A structure encapsulating a pair of offsets
    public struct Offsets {
        /// The lower offset
        public let lower: Pitch.Offset

        /// The higher offset
        public let higher: Pitch.Offset

        /// The closest offset
        public var closest: Pitch.Offset {
            abs(lower.frequency) < abs(higher.frequency) ? lower : higher
        }

        // MARK: - Initialization

        /// Initialize a pair of Offsets
        /// - Parameters:
        ///   - first: The first offset
        ///   - second: The second offset
        public init(_ first: Offset, _ second: Offset) {
            let lowerFirst = first.note.frequency < second.note.frequency
            self.lower     = lowerFirst ? first : second
            self.higher    = lowerFirst ? second : first
        }
    }

    /// The frequency of the pitch
    public let frequency: Double

    /// The wave of the pitch
    public let wave: AcousticWave

    /// The offsets of the pitch
    public let offsets: Offsets

    /// The closest note to the pitch
    public var note: Note {
        return offsets.closest.note
    }

    /// The closest offset to the pitch
    public var closestOffset: Offset {
        return offsets.closest
    }

    // MARK: - Initialization

    /// Initialize a Pitch from a frequency
    /// - Parameter frequency: The frequency of the Pitch
    /// - Throws: An error if the acoustic wave or the offsets cannot be calculated
    public init(frequency: Double) throws {
        try FrequencyValidator.validate(frequency: frequency)
        self.frequency = frequency
        self.wave      = try AcousticWave(frequency: frequency)
        self.offsets   = try PitchCalculator.offsets(forFrequency: frequency)
    }
}
