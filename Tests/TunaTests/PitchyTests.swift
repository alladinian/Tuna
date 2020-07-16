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

    static var allTests = [
        ("testFrequencyValidator", testFrequencyValidator),
    ]
}
