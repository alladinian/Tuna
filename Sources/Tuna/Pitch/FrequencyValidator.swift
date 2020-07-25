public struct FrequencyValidator {
    public static var range = 20.0 ... 4190.0

    public static let minimumFrequency = range.lowerBound
    public static let maximumFrequency = range.upperBound

    public static func isValid(frequency: Double) -> Bool {
        frequency > 0.0 && range.contains(frequency)
    }

    public static func validate(frequency: Double) throws {
        if !isValid(frequency: frequency) {
            throw PitchError.invalidFrequency
        }
    }

}
