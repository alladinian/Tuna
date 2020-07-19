public enum EstimationStrategy : CaseIterable {
  case maxValue
  case quadradic
  case barycentric
  case quinnsFirst
  case quinnsSecond
  case jains
  case hps
  case yin
}

extension EstimationStrategy {
    var estimator: Estimator {
        switch self {
        case .maxValue:     return MaxValueEstimator()
        case .quadradic:    return QuadradicEstimator()
        case .barycentric:  return BarycentricEstimator()
        case .quinnsFirst:  return QuinnsFirstEstimator()
        case .quinnsSecond: return QuinnsSecondEstimator()
        case .jains:        return JainsEstimator()
        case .hps:          return HPSEstimator()
        case .yin:          return YINEstimator()
        }
    }
}
