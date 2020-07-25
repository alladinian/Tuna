# Tuna

![Tuna](https://img.imageupload.net/2020/07/25/Tuna-hero.jpg)

---

**Disclaimer**

This project is based on [Beethoven](https://github.com/vadymmarkov/Beethoven) & [Pitchy](https://github.com/vadymmarkov/Pitchy), two excellent projects by [Vadym Markov](https://github.com/vadymmarkov) that are unfortunatelly not so actively developed any more. The code have been consolidated, modernized for Swift5, refactored and documented. I have also removed dependencies and added support for macOS. The heart of the libraries is the same and for anyone that used any of these libraries the transition should be fairly easy.

---

## Key features
- Get lower, higher and closest pitch offsets from a specified frequency.
- Get an acoustic wave with wavelength, period and harmonics.
- Create a note from a pitch index, frequency or a letter with octave number.
- Calculate a frequency, note letter and octave from a pitch index
- Find a pitch index from a specified frequency or a note letter with octave.
- Convert a frequency to wavelength and vice versa.
- Convert a wavelength to time period and vice versa.
- Audio signal tracking with `AVAudioEngine` and audio nodes.
- Pre-processing of audio buffer by one of the available "transformers".
- Pitch estimation.

## Index
* Pitch:
  * [Pitch](#pitch)
  * [Acoustic wave](#acoustic-wave)
  * [Note](#note)
  * [Calculators](#calculators)
  * [FrequencyValidator](#frequencyvalidator)
  * [Error handling](#pitch-error-handling)
    
* PitchEngine:
  * [Pitch engine](#pitch-engine)
  * [Signal tracking](#signal-tracking)
  * [Transform](#transform)
  * [Estimation](#estimation)
  * [Error handling](#pitch-engine-error-handling)
  * [Pitch detection specifics](#pitch-detection-specifics)

* [Authors](#authors)
* [License](#license)

---

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


### Pitch error handling
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

---

### Pitch engine
`PitchEngine` is the main class you are going to work with to find the pitch.
It can be instantiated with a delegate, a closure callback or both:

```swift
let pitchEngine = PitchEngine(delegate: delegate)
```

or 

```swift
let pitchEngine = PitchEngine { result in

    switch result {
    case .success(let pitch):
        // Handle the reported pitch
        
    case .failure(let error):
        // Handle the error
        
        switch error {
        case PitchEngine.Error.levelBelowThreshold: break
        case PitchEngine.Error.recordPermissionDenied: break
        
        case PitchError.invalidFrequency: break
        case PitchError.invalidWavelength: break
        case PitchError.invalidPeriod: break
        case PitchError.invalidPitchIndex: break
        case PitchError.invalidOctave: break
        default: break
        }
    }

}
```

the initializers have also the following optional parameters:

```swift
bufferSize: AVAudioFrameCount = 4096
estimationStrategy: EstimationStrategy = .yin
audioUrl: URL? = nil
signalTracker: SignalTracker? = nil
```

`PitchEngineDelegate` have a single requirement and reports back a `Result` (just like the callback):

```swift
func pitchEngine(_ pitchEngine: PitchEngine, didReceive result: Result<Pitch, Error>)
```

For reference the full init signature is:

```swift
public init(bufferSize: AVAudioFrameCount = 4096,
            estimationStrategy: EstimationStrategy = .yin,
            audioUrl: URL? = nil,
            signalTracker: SignalTracker? = nil,
            delegate: PitchEngineDelegate? = nil,
            callback: PitchEngineCallback? = nil)
```

It should be noted that both reporting mechanisms are conveniently called in the main queue, since you probably want to update your UI most of the time.

To start or stop the pitch tracking process just use the corresponding `PitchEngine` methods:

```swift
pitchEngine.start()
pitchEngine.stop()
```

### Signal tracking
There are 2 signal tracking classes:
- `InputSignalTracker` uses `AVAudioInputNode` to get an audio buffer from the
recording input (microphone) in real-time.
- `OutputSignalTracker` uses `AVAudioOutputNode` and `AVAudioFile` to play an
audio file and get the audio buffer from the playback output.


### Transform
Transform is the first step of audio processing where `AVAudioPCMBuffer` object
is converted to an array of floating numbers. Also it's a place for different
kind of optimizations. Then array is kept in the `elements` property of the
internal `Buffer` struct, which also has optional `realElements` and
`imagElements` properties that could be useful in the further calculations.

There are 3 types of transformations at the moment:
- [Fast Fourier transform](https://en.wikipedia.org/wiki/Fast_Fourier_transform)
- [YIN](http://recherche.ircam.fr/equipes/pcm/cheveign/pss/2002_JASA_YIN.pdf)
- `Simple` conversion to use raw float channel data

A new transform strategy could be easily added by implementing of `Transformer`
protocol:

```swift
public protocol Transformer {
    func transform(buffer: AVAudioPCMBuffer) -> Buffer
}
```

### Estimation
A pitch detection algorithm (PDA) is an algorithm designed to estimate the pitch
or fundamental frequency. Pitch is a psycho-acoustic phenomena, and it's
important to choose the most suitable algorithm for your kind of input source,
considering allowable error rate and needed performance.

The list of available implemented algorithms:
- `maxValue` - the index of the maximum value in the audio buffer used as a peak
- `quadradic` - [Quadratic interpolation of spectral peaks](https://ccrma.stanford.edu/%7Ejos/sasp/Quadratic_Interpolation_Spectral_Peaks.html)
- `barycentric` - [Barycentric correction](http://www.dspguru.com/dsp/howtos/how-to-interpolate-fft-peak)
- `quinnsFirst` - [Quinn's First Estimator](http://www.dspguru.com/dsp/howtos/how-to-interpolate-fft-peak)
- `quinnsSecond` - [Quinn's Second Estimator](http://www.dspguru.com/dsp/howtos/how-to-interpolate-fft-peak)
- `jains` - [Jain's Method](http://www.dspguru.com/dsp/howtos/how-to-interpolate-fft-peak)
- `hps` - [Harmonic Product Spectrum](http://musicweb.ucsd.edu/~trsmyth/analysis/Harmonic_Product_Spectrum.html)
- `yin` - [YIN](http://recherche.ircam.fr/equipes/pcm/cheveign/pss/2002_JASA_YIN.pdf)

A new estimation algorithm could be easily added by implementing of `Estimator`
or `LocationEstimator` protocol:

```swift
protocol Estimator {
    var transformer: Transformer { get }

    func estimateFrequency(sampleRate: Float, buffer: Buffer) throws -> Float
    func estimateFrequency(sampleRate: Float, location: Int, bufferCount: Int) -> Float
}

protocol LocationEstimator: Estimator {
    func estimateLocation(buffer: Buffer) throws -> Int
}
```

Then it should be added to `EstimationStrategy` enum and in the `create` method
of `EstimationFactory` struct. Normally, a buffer transformation should be
performed in a separate struct or class to keep the code base more clean and
readable.


### Pitch Engine error handling
Pitch detection is not a trivial task due to some difficulties, such as attack
transients, low and high frequencies. Also it's a real-time processing, so we
are not protected against different kinds of errors. For this purpose there is a
range of error types that should be handled properly.

**Signal tracking errors**

```swift
public enum InputSignalTrackerError: Error {
    case inputNodeMissing
}
```

**Record permission errors**

`PitchEngine` asks for `AVAudioSessionRecordPermission` on start, but if permission is denied it produces the corresponding error:

```swift
public enum PitchEngineError: Error {
    case recordPermissionDenied
}
```

**Pitch estimation errors**

Some errors could occur during the process of pitch estimation:

```swift
public enum EstimationError: Error {
    case emptyBuffer
    case unknownMaxIndex
    case unknownLocation
    case unknownFrequency
}
```

## Pitch detection specifics
At the moment **Tuna** performs only a pitch detection of a monophonic recording.

**Based on Stackoverflow** [answer](http://stackoverflow.com/a/14503090):

> Pitch detection depends greatly on the musical content you want to work with.
> Extracting the pitch of a monophonic recording (i.e. single instrument or voice)
> is not the same as extracting the pitch of a single instrument from a polyphonic
> mixture (e.g. extracting the pitch of the melody from a polyphonic recording).

> For monophonic pitch extraction there are various algorithm that could be
> implemented both in the time domain and frequency domain
> ([Wikipedia](https://en.wikipedia.org/wiki/Pitch_detection_algorithm)).

> However, neither will work well if you want to extract the melody from
> polyphonic material. Melody extraction from polyphonic music is still a
> research problem.

## Authors
Vasilis Akoinoglou, alladinian@gmail.com
Credit to original Author: Vadym Markov, markov.vadym@gmail.com

## License

**Tuna** is available under the MIT license. See the LICENSE file for more info.
