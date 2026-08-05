//
//  LightingWarningBanner.swift
//  Suzuran — Views/Components/
//
//  Glassmorphic overlay card shown inside the face oval when ambient
//  lighting is outside acceptable bounds. Scanning is paused while visible.
//

import SwiftUI

/// Glassmorphic card overlaid on the scan ring when lighting is inadequate.
/// Displays a contextual icon, headline, and actionable detail text.
struct LightingWarningBanner: View {

    let condition:  LightingCondition
    let ovalWidth:  CGFloat

    // MARK: - Content

    private var icon: String {
        switch condition {
        case .tooDark:   return "moon.fill"
        case .tooBright: return "sun.max.fill"
        default:         return "exclamationmark.triangle.fill"
        }
    }

    private var headline: String {
        switch condition {
        case .tooDark:   return "Too Dark"
        case .tooBright: return "Too Bright"
        case .checking:  return "Checking…"
        case .good:      return ""
        }
    }

    private var detail: String {
        switch condition {
        case .tooDark:   return "Move to a well-lit area\nto continue scanning"
        case .tooBright: return "Step out of direct sunlight\nor reduce glare"
        case .checking:  return "Reading ambient light…"
        case .good:      return ""
        }
    }

    private var iconColor: Color {
        condition == .tooDark
            ? Color(red: 0.55, green: 0.75, blue: 1.0)   // cool blue for dark
            : Color(red: 1.0,  green: 0.80, blue: 0.20)  // warm amber for bright
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(iconColor)
                .shadow(color: iconColor.opacity(0.60), radius: 12)

            Text(headline)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(detail)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.70))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(iconColor.opacity(0.30), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.40), radius: 20)
        .frame(maxWidth: ovalWidth * 0.72)
    }
}
