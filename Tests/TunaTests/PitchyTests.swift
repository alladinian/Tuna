import XCTest
@testable import Tuna

infix operator ≈ : ComparisonPrecedence

fileprivate func ≈ (lhs: Double, rhs: (Double, Double)) -> Bool {
    abs(lhs - rhs.0) < rhs.1
}

final class PitchyTests: XCTestCase {

    func testFrequencyValidator() {
        XCTAssertFalse(FrequencyValidator.isValid(frequency: 5_000), "should be invalid if frequency is higher than maximum")
        XCTAssertFalse(FrequencyValidator.isValid(frequency: 10), "should be invalid if frequency is lower than minimum")
        XCTAssertFalse(FrequencyValidator.isValid(frequency: 0), "should be invalid if frequency is zero")
        XCTAssertTrue(FrequencyValidator.isValid(frequency: 440), "should be valid if frequency is within valid bounds")
    }

    func testNoteCalculator() {
        let notes = [
            (index: 0, note: Note.Letter.A, octave: 4, frequency: 440.0),
            (index: 12, note: Note.Letter.A, octave: 5, frequency: 880.000),
            (index: 2, note: Note.Letter.B, octave: 4, frequency: 493.883),
            (index: -10, note: Note.Letter.B, octave: 3, frequency: 246.942),
            (index: -9, note: Note.Letter.C, octave: 4, frequency: 261.626),
            (index: -30, note: Note.Letter.DSharp, octave: 2, frequency: 77.7817),
            (index: 11, note: Note.Letter.GSharp, octave: 5, frequency: 830.609),
            (index: 29, note: Note.Letter.D, octave: 7, frequency: 2349.32)
        ]

        // Standard calculator base constant values
        XCTAssertEqual(NoteCalculator.Standard.frequency, 440)
        XCTAssertEqual(NoteCalculator.Standard.octave, 4)

        func indexBounds() {
            // Bounds based on min and max frequencies from the config
            let minimum  = try! NoteCalculator.index(forFrequency: FrequencyValidator.minimumFrequency)
            let maximum  = try! NoteCalculator.index(forFrequency: FrequencyValidator.maximumFrequency)
            let expected = (minimum: minimum, maximum: maximum)
            let result   = NoteCalculator.indexBounds

            XCTAssertEqual(result.minimum, expected.minimum)
            XCTAssertEqual(result.maximum, expected.maximum)
        }

        indexBounds()

        func octaveBounds() {
            // Bounds based on min and max frequencies from the config
            let bounds   = NoteCalculator.indexBounds
            let minimum  = try! NoteCalculator.octave(forIndex: bounds.minimum)
            let maximum  = try! NoteCalculator.octave(forIndex: bounds.maximum)
            let expected = (minimum: minimum, maximum: maximum)
            let result   = NoteCalculator.octaveBounds

            XCTAssertEqual(result.minimum, expected.minimum)
            XCTAssertEqual(result.maximum, expected.maximum)
        }

        octaveBounds()

        // Valid index
        XCTAssertFalse(NoteCalculator.isValid(index: 1_000), "is invalid if value is higher than maximum")
        XCTAssertFalse(NoteCalculator.isValid(index: -100), "is invalid if value is lower than minimum")
        XCTAssertTrue(NoteCalculator.isValid(index: 6), "is valid if value is within valid bounds")

        // Valid octave
        XCTAssertFalse(NoteCalculator.isValid(octave: 10), "is invalid if value is higher than maximum")
        XCTAssertFalse(NoteCalculator.isValid(octave: -1), "is invalid if value is lower than minimum")
        XCTAssertTrue(NoteCalculator.isValid(octave: 2), "is valid if value is within valid bounds")

        // Notes
        let letters = NoteCalculator.letters
        XCTAssertEqual(letters.count, 12)

        XCTAssertEqual(letters[0], Note.Letter.A)
        XCTAssertEqual(letters[1], Note.Letter.ASharp)
        XCTAssertEqual(letters[2], Note.Letter.B)
        XCTAssertEqual(letters[3], Note.Letter.C)
        XCTAssertEqual(letters[4], Note.Letter.CSharp)
        XCTAssertEqual(letters[5], Note.Letter.D)
        XCTAssertEqual(letters[6], Note.Letter.DSharp)
        XCTAssertEqual(letters[7], Note.Letter.E)
        XCTAssertEqual(letters[8], Note.Letter.F)
        XCTAssertEqual(letters[9], Note.Letter.FSharp)
        XCTAssertEqual(letters[10], Note.Letter.G)
        XCTAssertEqual(letters[11], Note.Letter.GSharp)

        for note in notes {
            XCTAssertTrue(try! NoteCalculator.frequency(forIndex: note.index) ≈ (note.frequency, 0.01))
            XCTAssertEqual(try! NoteCalculator.letter(forIndex: note.index), note.note)
            XCTAssertEqual(try! NoteCalculator.octave(forIndex: note.index), note.octave)
            XCTAssertEqual(try! NoteCalculator.index(forFrequency: note.frequency), note.index)
            XCTAssertEqual(try! NoteCalculator.index(forLetter: note.note, octave: note.octave), note.index)
        }
    }

    func testPichCalculator() {
        let offsets = [
            (frequency: 445.0,
             lower: Pitch.Offset(note: try! Note(index: 0), frequency: 5, percentage: 19.1, cents: 19.56),
             higher: Pitch.Offset(note: try! Note(index: 1), frequency: -21.164, percentage: -80.9, cents: -80.4338),
             closest: "A4"
            ),
            (frequency: 108.0,
             lower: Pitch.Offset(note: try! Note(index: -25), frequency: 4.174, percentage: 67.6, cents: 68.2333),
             higher: Pitch.Offset(note: try! Note(index: -24), frequency: -2, percentage: -32.39, cents: -31.76),
             closest: "A2"
            )
        ]

        for offset in offsets {
            let result = try! PitchCalculator.offsets(forFrequency: offset.frequency)

            XCTAssertTrue(result.lower.frequency ≈ (offset.lower.frequency, 0.01))
            XCTAssertTrue(result.lower.percentage ≈ (offset.lower.percentage, 0.1))
            XCTAssertEqual(result.lower.note.index, offset.lower.note.index)
            XCTAssertTrue(result.lower.cents ≈ (offset.lower.cents, 0.1))

            XCTAssertTrue(result.higher.frequency ≈ (offset.higher.frequency, 0.01))
            XCTAssertTrue(result.higher.percentage ≈ (offset.higher.percentage, 0.1))
            XCTAssertEqual(result.higher.note.index, offset.higher.note.index)
            XCTAssertTrue(result.higher.cents ≈ (offset.higher.cents, 0.1))

            XCTAssertEqual(result.closest.note.string, offset.closest)
        }
    }

    func testWaveCalculator() {
        let waves = [
            (frequency: 440.0,
             wavelength: 0.7795,
             period: 0.00227259
            ),
            (frequency: 1000.0,
             wavelength: 0.343,
             period: 0.001
            )
        ]

        func indexBounds() {
            // Bounds based on min and max frequencies from the config
            let minimum = try! WaveCalculator.wavelength(forFrequency: FrequencyValidator.maximumFrequency)
            let maximum = try! WaveCalculator.wavelength(forFrequency: FrequencyValidator.minimumFrequency)
            let expected = (minimum: minimum, maximum: maximum)
            let result = WaveCalculator.wavelengthBounds

            XCTAssertEqual(result.minimum, expected.minimum)
            XCTAssertEqual(result.maximum, expected.maximum)
        }

        indexBounds()

        func octaveBounds() {
            // Bounds based on min and max frequencies from the config
            let bounds = WaveCalculator.wavelengthBounds
            let minimum = try! WaveCalculator.period(forWavelength: bounds.minimum)
            let maximum = try! WaveCalculator.period(forWavelength: bounds.maximum)
            let expected = (minimum: minimum, maximum: maximum)
            let result = WaveCalculator.periodBounds

            XCTAssertEqual(result.minimum, expected.minimum)
            XCTAssertEqual(result.maximum, expected.maximum)
        }

        octaveBounds()

        // Valid wavelength
        XCTAssertFalse(WaveCalculator.isValid(wavelength: 1_000), "is invalid if value is higher than maximum")
        XCTAssertFalse(WaveCalculator.isValid(wavelength:  0.01), "is invalid if value is lower than minimum")
        XCTAssertFalse(WaveCalculator.isValid(wavelength:  0), "is invalid if value is zero")
        XCTAssertTrue(WaveCalculator.isValid(wavelength: 16), "is valid if value is within valid bounds")

        // Valid period
        XCTAssertFalse(WaveCalculator.isValid(period: 10), "is invalid if value is higher than maximum")
        XCTAssertFalse(WaveCalculator.isValid(period: 0.0001), "is invalid if value is lower than minimum")
        XCTAssertFalse(WaveCalculator.isValid(period:  0), "is invalid if value is zero")
        XCTAssertTrue(WaveCalculator.isValid(period: 0.02), "is valid if value is within valid bounds")

        for wave in waves {
            let result1 = try! WaveCalculator.frequency(forWavelength: wave.wavelength)
            XCTAssertTrue(result1 ≈ (wave.frequency, 0.1))
            let result2 = try! WaveCalculator.wavelength(forFrequency: wave.frequency)
            XCTAssertTrue(result2 ≈ (wave.wavelength, 0.1))
            let result3 = try! WaveCalculator.wavelength(forPeriod: wave.period)
            XCTAssertTrue(result3 ≈ (wave.wavelength, 0.0001))
            let result4 = try! WaveCalculator.period(forWavelength: wave.wavelength)
            XCTAssertTrue(result4 ≈ (wave.period, 0.0001))

        }
    }

    func testAcousticWave() {
        let waves = [
            (frequency: 440.0,
             wavelength: 0.7795,
             period: 0.00227259
            ),
            (frequency: 1000.0,
             wavelength: 0.343,
             period: 0.001
            )
        ]

        XCTAssertTrue(AcousticWave.speed ≈ (343, 0.001))

        // Freq init
        waves.forEach {
            let wave = try! AcousticWave(frequency: $0.frequency)

            XCTAssertTrue(wave.frequency ≈ ($0.frequency, 0.01))
            XCTAssertTrue(wave.wavelength ≈ ($0.wavelength, 0.01))
            XCTAssertTrue(wave.period ≈ ($0.period, 0.01))

            for (index, value) in wave.harmonics.enumerated() {
                XCTAssertTrue(value.frequency ≈ (Double(index + 1) * $0.frequency, 0.01))
            }
        }

        // Wave init
        waves.forEach {
            let wave = try! AcousticWave(wavelength: $0.wavelength)

            XCTAssertTrue(wave.frequency ≈ ($0.frequency, 0.1))
            XCTAssertTrue(wave.wavelength ≈ ($0.wavelength, 0.01))
            XCTAssertTrue(wave.period ≈ ($0.period, 0.01))

            for (index, value) in wave.harmonics.enumerated() {
                XCTAssertTrue(value.frequency ≈ (Double(index + 1) * $0.frequency, 1))
            }
        }

        // Period init
        waves.forEach {
            let wave = try! AcousticWave(period: $0.period)

            XCTAssertTrue(wave.frequency ≈ ($0.frequency, 0.1))
            XCTAssertTrue(wave.wavelength ≈ ($0.wavelength, 0.01))
            XCTAssertTrue(wave.period ≈ ($0.period, 0.01))

            for (index, value) in wave.harmonics.enumerated() {
                XCTAssertTrue(value.frequency ≈ (Double(index + 1) * $0.frequency, 1))
            }
        }
    }

    func testNotes() {
        let letters = Note.Letter.allCases
        XCTAssertEqual(letters.count, 12)

        XCTAssertEqual(letters[0], Note.Letter.C)
        XCTAssertEqual(letters[1], Note.Letter.CSharp)
        XCTAssertEqual(letters[2], Note.Letter.D)
        XCTAssertEqual(letters[3], Note.Letter.DSharp)
        XCTAssertEqual(letters[4], Note.Letter.E)
        XCTAssertEqual(letters[5], Note.Letter.F)
        XCTAssertEqual(letters[6], Note.Letter.FSharp)
        XCTAssertEqual(letters[7], Note.Letter.G)
        XCTAssertEqual(letters[8], Note.Letter.GSharp)
        XCTAssertEqual(letters[9], Note.Letter.A)
        XCTAssertEqual(letters[10], Note.Letter.ASharp)
        XCTAssertEqual(letters[11], Note.Letter.B)

        var note: Note!

        let notes = [
            (index: -9, letter: Note.Letter.C, octave: 4, frequency: 261.626,
             string: "C4", lower: "B3", higher: "C#4"),
            (index: 16, letter: Note.Letter.CSharp, octave: 6, frequency: 1108.73,
             string: "C#6", lower: "C6", higher: "D6"),
            (index: 5, letter: Note.Letter.D, octave: 5, frequency: 587.330,
             string: "D5", lower: "C#5", higher: "D#5"),
            (index: 18, letter: Note.Letter.DSharp, octave: 6, frequency: 1244.51,
             string: "D#6", lower: "D6", higher: "E6"),
            (index: 31, letter: Note.Letter.E, octave: 7, frequency: 2637.02,
             string: "E7", lower: "D#7", higher: "F7"),
            (index: -16, letter: Note.Letter.F, octave: 3, frequency: 174.614,
             string: "F3", lower: "E3", higher: "F#3"),
            (index: -27, letter: Note.Letter.FSharp, octave: 2, frequency: 92.4986,
             string: "F#2", lower: "F2", higher: "G2"),
            (index: -38, letter: Note.Letter.G, octave: 1, frequency: 48.9994,
             string: "G1", lower: "F#1", higher: "G#1"),
            (index: -13, letter: Note.Letter.GSharp, octave: 3, frequency: 207.652,
             string: "G#3", lower: "G3", higher: "A3"),
            (index: 0, letter: Note.Letter.A, octave: 4, frequency: 440,
             string: "A4", lower: "G#4", higher: "A#4"),
            (index: -47, letter: Note.Letter.ASharp, octave: 0, frequency: 29.1352,
             string: "A#0", lower: "A0", higher: "B0"),
            (index: 2, letter: Note.Letter.B, octave: 4, frequency: 493.883,
             string: "B4", lower: "A#4", higher: "C5")
        ]

        // Index
        notes.forEach {
            note = try! Note(index: $0.index)
            XCTAssertNotNil(note)

            XCTAssertEqual(note.index, $0.index)
            XCTAssertEqual(note.letter, $0.letter)
            XCTAssertEqual(note.octave, $0.octave)
            XCTAssertTrue(note.frequency ≈ ($0.frequency, 0.01))
            XCTAssertTrue(note.wave.frequency ≈ ($0.frequency, 0.01))
            XCTAssertEqual(note.string, $0.string)
            XCTAssertEqual(try! note.lower().string, $0.lower)
            XCTAssertEqual(try! note.higher().string, $0.higher)
        }

        // Frequency
        notes.forEach {
            note = try! Note(frequency: $0.frequency)
            XCTAssertNotNil(note)

            XCTAssertEqual(note.index, $0.index)
            XCTAssertEqual(note.letter, $0.letter)
            XCTAssertEqual(note.octave, $0.octave)
            XCTAssertTrue(note.frequency ≈ ($0.frequency, 0.01))
            XCTAssertTrue(note.wave.frequency ≈ ($0.frequency, 0.01))
            XCTAssertEqual(note.string, $0.string)
            XCTAssertEqual(try! note.lower().string, $0.lower)
            XCTAssertEqual(try! note.higher().string, $0.higher)
        }

        // Letter & Octave
        notes.forEach {
            note = try! Note(letter: $0.letter, octave: $0.octave)
            XCTAssertNotNil(note)

            XCTAssertEqual(note.index, $0.index)
            XCTAssertEqual(note.letter, $0.letter)
            XCTAssertEqual(note.octave, $0.octave)
            XCTAssertTrue(note.frequency ≈ ($0.frequency, 0.01))
            XCTAssertTrue(note.wave.frequency ≈ ($0.frequency, 0.01))
            XCTAssertEqual(note.string, $0.string)
            XCTAssertEqual(try! note.lower().string, $0.lower)
            XCTAssertEqual(try! note.higher().string, $0.higher)
        }
    }

    func testPitch() {
        let offsets = [
            (frequency: 445.0,
             lower: Pitch.Offset(note: try! Note(index: 0), frequency: 5, percentage: 19.1, cents: 19.56),
             higher: Pitch.Offset(note: try! Note(index: 1), frequency: -21.164, percentage: -80.9, cents: -80.4338),
             closest: "A4"
            ),
            (frequency: 108.0,
             lower: Pitch.Offset(note: try! Note(index: -25), frequency: 4.174, percentage: 67.6, cents: 68.2333),
             higher: Pitch.Offset(note: try! Note(index: -24), frequency: -2, percentage: -32.39, cents: -31.76),
             closest: "A2"
            )
        ]

        func offsetInit() {
            // Rearrange offsets based on frequency
            let sample = offsets[0]
            let offsets = Pitch.Offsets(sample.higher, sample.lower)

            XCTAssertEqual(offsets.lower.note.index, sample.lower.note.index)
            XCTAssertEqual(offsets.higher.note.index, sample.higher.note.index)
        }

        offsetInit()

        offsets.forEach {
            let pitch = try! Pitch(frequency: $0.frequency)

            XCTAssertTrue(pitch.frequency ≈ ($0.frequency, 0.01))
            XCTAssertTrue(pitch.wave.frequency ≈ ($0.frequency, 0.01))
        }

        offsets.forEach {
            let pitch = try! Pitch(frequency: $0.frequency)
            let result = pitch.offsets

            XCTAssertTrue(result.lower.frequency ≈ ($0.lower.frequency, 0.01))
            XCTAssertTrue(result.lower.percentage ≈ ($0.lower.percentage, 0.1))
            XCTAssertEqual(result.lower.note.index, $0.lower.note.index)
            XCTAssertTrue(result.lower.cents ≈ ($0.lower.cents, 0.01))

            XCTAssertTrue(result.higher.frequency ≈ ($0.higher.frequency, 0.01))
            XCTAssertTrue(result.higher.percentage ≈ ($0.higher.percentage, 0.1))
            XCTAssertEqual(result.higher.note.index, $0.higher.note.index)
            XCTAssertTrue(result.higher.cents ≈ ($0.higher.cents, 0.01))

            XCTAssertEqual(result.closest.note.string, $0.closest)
        }
    }

    static var allTests = [
        ("testFrequencyValidator", testFrequencyValidator),
        ("testNoteCalculator", testNoteCalculator),
        ("testPichCalculator", testPichCalculator),
        ("testWaveCalculator", testWaveCalculator),
        ("testAcousticWave", testAcousticWave),
        ("testNotes", testNotes),
        ("testPitch", testPitch),
    ]
}
