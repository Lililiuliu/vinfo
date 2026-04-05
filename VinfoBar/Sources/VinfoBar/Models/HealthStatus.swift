import Foundation
import SwiftUI

enum HealthStatus: String, Codable, CaseIterable {
    case healthy = "healthy"
    case warning = "warning"
    case error = "error"
    case notFound = "not_found"
    case unknown = "unknown"

    var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .notFound: return "minus.circle"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .healthy: return .green
        case .warning: return .yellow
        case .error: return .red
        case .notFound: return .gray
        case .unknown: return .purple
        }
    }

    var label: String {
        switch self {
        case .healthy: return "OK"
        case .warning: return "!"
        case .error: return "X"
        case .notFound: return "-"
        case .unknown: return "?"
        }
    }
}