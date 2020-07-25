# Tuna

---

**Disclaimer**

This project is based on [Beethoven](https://github.com/vadymmarkov/Beethoven) & [Pitchy](https://github.com/vadymmarkov/Pitchy), two excellent projects by [Vadym Markov](https://github.com/vadymmarkov) that are unfortunatelly not so actively developed any more. The code have been modernized for Swift5, refactored and documented. I have also removed dependencies and added support for macOS. The heart of the libraries is the same and for anyone that used any of these libraries the transition should be fairly easy.

---

## Key features
- Get lower, higher and closest pitch offsets from a specified frequency.
- Get an acoustic wave with wavelength, period and harmonics.
- Create a note from a pitch index, frequency or a letter with octave number.
- Calculate a frequency, note letter and octave from a pitch index
- Find a pitch index from a specified frequency or a note letter with octave.
- Convert a frequency to wavelength and vice versa.
- Convert a wavelength to time period and vice versa.

## Index
* [Pitch](#pitch)
* [Acoustic wave](#acoustic-wave)
* [Note](#note)
* [Calculators](#calculators)
* [FrequencyValidator](#frequencyvalidator)
* [Error handling](#error-handling)


### Pitch
Create `Pitch` struct with a specified frequency to get lower, higher and
closest pitch offsets:

```swift
do {
    // Frequency = 445 Hz
    let pitch = try Pitch(frequency: 445.0)
    let pitchOffsets = pitch.offsets

    print(pitchOffsets.lower.frequency)     // 5 Hz
    print(pitchOffsets.lower.percentage)    // 19.1%
    print(pitchOffsets.lower.note.index)    // 0
    print(pitchOffsets.lower.cents)         // 19.56

    print(pitchOffsets.higher.frequency)    // -21.164 Hz
    print(pitchOffsets.higher.percentage)   // -80.9%
    print(pitchOffsets.higher.note.index)   // 1
    print(pitchOffsets.higher.cents)        // -80.4338

    print(pitchOffsets.closest.note)        // "A4"

    // You could also use acoustic wave
    print(pitch.wave.wavelength)            // 0.7795 meters
} catch {
    // Handle errors
}
```


### Acoustic wave
Get an acoustic wave with wavelength, period and harmonics.

```swift
do {
    // AcousticWave(wavelength: 0.7795)
    // AcousticWave(period: 0.00227259)
    let wave = try AcousticWave(frequency: 440.0)

    print(wave.frequency)       // 440 Hz
    print(wave.wavelength)      // 0.7795 meters
    print(wave.period)          // 0.00227259 s
    print(wave.harmonics[0])    // 440 Hz
    print(wave.harmonics[1])    // 880 Hz
} catch {
    // Handle errors
}
```


### Note
Note could be created with a corresponding frequency, letter + octave number or
a pitch index.

```swift
do {
    // Note(frequency: 261.626)
    // Note(letter: .C, octave: 4)
    let note = try Note(index: -9)

    print(note.index)           // -9
    print(note.letter)          // .C
    print(note.octave)          // 4
    print(note.frequency)       // 261.626 Hz
    print(note)                 // "C4"
    print(try note.lower())     // "B3"
    print(try note.higher())    // "C#4"
} catch {
    // Handle errors
}
```


### Calculators

Calculators are used in the initialization of `Pitch`, `AcousticWave`
and `Note`, but also are included in the public API.

```swift
do {
    // PitchCalculator
    let pitchOffsets = try PitchCalculator.offsets(445.0)
    let cents        = try PitchCalculator.cents(frequency1: 440.0, frequency2: 440.0)  // 19.56

    // NoteCalculator
    let frequency1   = try NoteCalculator.frequency(forIndex: 0)                        // 440.0 Hz
    let letter       = try NoteCalculator.letter(forIndex: 0)                           // .A
    let octave       = try NoteCalculator.octave(forIndex: 0)                           // 4
    let index1       = try NoteCalculator.index(forFrequency: 440.0)                    // 0
    let index2       = try NoteCalculator.index(forLetter: .A, octave: 4)               // 0

    // WaveCalculator
    let f            = try WaveCalculator.frequency(forWavelength: 0.7795)              // 440.0 Hz
    let wl1          = try WaveCalculator.wavelength(forFrequency: 440.0)               // 0.7795 meters
    let wl2          = try WaveCalculator.wavelength(forPeriod: 0.00227259)             // 0.7795 meters
    let period       = try WaveCalculator.period(forWavelength: 0.7795)                 // 0.00227259 s
} catch {
    // Handle errors
}
```


### FrequencyValidator

With a help of `FrequencyValidator` it's possible to adjust the range of frequencies that are used for validations in all calculations:

```swift
FrequencyValidator.range = 20.0 ... 4190.0      // This btw is the default range
```


### Error handling

Almost everything is covered with tests, but it's important to pass valid
values, such as frequencies and pitch indexes. That's why there is a list of errors that should be handled properly.

```swift
enum PitchError: Error {
    case invalidFrequency
    case invalidWavelength
    case invalidPeriod
    case invalidPitchIndex
    case invalidOctave
}
```


## Authors

Vasilis Akoinoglou, alladinian@gmail.com

Credit to original Author: Vadym Markov, markov.vadym@gmail.com

## License

**Tuna** is available under the MIT license. See the LICENSE file for more info.
