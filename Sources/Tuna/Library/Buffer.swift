struct Buffer {
    let elements: [Float]
    let realElements: [Float]?
    let imagElements: [Float]?

    var count: Int {
        elements.count
    }

    // MARK: - Initialization

    init(elements: [Float], realElements: [Float]? = nil, imagElements: [Float]? = nil) {
        self.elements     = elements
        self.realElements = realElements
        self.imagElements = imagElements
    }
}
