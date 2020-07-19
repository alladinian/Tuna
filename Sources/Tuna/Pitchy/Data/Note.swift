public struct Note {

    /// The letter of a music note in English Notation
    public enum Letter: String, CaseIterable, CustomStringConvertible {
        case C      = "C"
        case CSharp = "C#"
        case D      = "D"
        case DSharp = "D#"
        case E      = "E"
        case F      = "F"
        case FSharp = "F#"
        case G      = "G"
        case GSharp = "G#"
        case A      = "A"
        case ASharp = "A#"
        case B      = "B"

        public var description: String { rawValue }
    }

    /// The index of the note
    public let index: Int

    /// The letter of the note in English Notation
    public let letter: Letter

    /// The octave of the note
    public let octave: Int

    /// The frequency of the note
    public let frequency: Double

    /// The corresponding wave of the note
    public let wave: AcousticWave

    /// A string description of the note including octave
    public var string: String {
        "\(self.letter)\(self.octave)"
    }

    // MARK: - Initialization

    /// Initialize a Note from an index
    /// - Parameter index: The index of the note
    /// - Throws: An error if the rest of the components cannot be calculated
    public init(index: Int) throws {
        self.index     = index
        letter         = try NoteCalculator.letter(forIndex: index)
        octave         = try NoteCalculator.octave(forIndex: index)
        frequency      = try NoteCalculator.frequency(forIndex: index)
        wave           = try AcousticWave(frequency: frequency)
    }

    /// Initialize a Note from a frequency
    /// - Parameter frequency: The frequency of the note
    /// - Throws: An error if the rest of the components cannot be calculated
    public init(frequency: Double) throws {
        index          = try NoteCalculator.index(forFrequency: frequency)
        letter         = try NoteCalculator.letter(forIndex: index)
        octave         = try NoteCalculator.octave(forIndex: index)
        self.frequency = try NoteCalculator.frequency(forIndex: index)
        wave           = try AcousticWave(frequency: frequency)
    }

    /// Initialize a Note from a Letter & Octave
    /// - Parameters:
    ///   - letter: The letter of the note
    ///   - octave: The octave of the note
    /// - Throws: An error if the rest of the components cannot be calculated
    public init(letter: Letter, octave: Int) throws {
        self.letter    = letter
        self.octave    = octave
        index          = try NoteCalculator.index(forLetter: letter, octave: octave)
        frequency      = try NoteCalculator.frequency(forIndex: index)
        wave           = try AcousticWave(frequency: frequency)
    }

    // MARK: - Neighbor Notes

    /// One semitone lower
    /// - Throws: An error if the semitone is out of bounds
    /// - Returns: A note that is one semitone lower
    public func lower() throws -> Note {
        try Note(index: index - 1)
    }

    /// One semitone higher
    /// - Throws: An error if the semitone is out of bounds
    /// - Returns: A note that is one semitone higher
    public func higher() throws -> Note {
        try Note(index: index + 1)
    }
}
