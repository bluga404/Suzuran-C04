//
//  LightingCondition.swift
//  Suzuran
//
//  Model: ambient lighting quality detected by the TrueDepth camera.
//

/// Describes the ambient lighting quality detected by the TrueDepth camera.
///
/// Thresholds used by `ARFaceViewModel`:
///   • Neutral indoor lighting  ≈ 1 000 lm/m²
///   • Comfortably readable     ≈ 700 – 1 500 lm/m²
///   • Too dark                 < 500 lm/m²
///   • Too bright               > 2 500 lm/m²
enum LightingCondition: Equatable {
    /// AR session running; light estimate not yet received.
    case checking
    /// Lighting is within acceptable bounds — scanning may proceed.
    case good
    /// Scene is too dim; face features will be under-exposed.
    case tooDark
    /// Scene is over-bright; glare may wash out face features.
    case tooBright
}
