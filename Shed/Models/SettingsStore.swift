import SwiftUI

// MARK: - Felt colour palette

enum FeltColor: String, CaseIterable {
    case green    = "green"
    case blue     = "blue"
    case burgundy = "burgundy"
    case charcoal = "charcoal"
    case teal     = "teal"
    case navy     = "navy"

    var label: String {
        switch self {
        case .green:    return "Green"
        case .blue:     return "Blue"
        case .burgundy: return "Burgundy"
        case .charcoal: return "Charcoal"
        case .teal:     return "Teal"
        case .navy:     return "Navy"
        }
    }

    var felt: Color {
        switch self {
        case .green:    return Color(red: 0.07, green: 0.12, blue: 0.09)
        case .blue:     return Color(red: 0.06, green: 0.09, blue: 0.18)
        case .burgundy: return Color(red: 0.14, green: 0.06, blue: 0.08)
        case .charcoal: return Color(red: 0.09, green: 0.09, blue: 0.11)
        case .teal:     return Color(red: 0.05, green: 0.13, blue: 0.14)
        case .navy:     return Color(red: 0.05, green: 0.07, blue: 0.16)
        }
    }

    // Slightly lighter surface tone for each colour
    var surface: Color {
        switch self {
        case .green:    return Color(red: 0.11, green: 0.17, blue: 0.13)
        case .blue:     return Color(red: 0.10, green: 0.14, blue: 0.24)
        case .burgundy: return Color(red: 0.20, green: 0.10, blue: 0.12)
        case .charcoal: return Color(red: 0.14, green: 0.14, blue: 0.16)
        case .teal:     return Color(red: 0.09, green: 0.18, blue: 0.20)
        case .navy:     return Color(red: 0.09, green: 0.12, blue: 0.22)
        }
    }
}

// MARK: - Settings store

final class SettingsStore: ObservableObject {
    @AppStorage("dig_enabled")        var digEnabled:      Bool   = false
    @AppStorage("pile_peek_enabled")  var pilePeekEnabled: Bool   = false
    @AppStorage("haptics_enabled")    var hapticsEnabled:  Bool   = true
    @AppStorage("felt_color")         var feltColorKey:    String = FeltColor.green.rawValue

    var feltColor: FeltColor {
        get { FeltColor(rawValue: feltColorKey) ?? .green }
        set { feltColorKey = newValue.rawValue }
    }

    var felt:    Color { feltColor.felt    }
    var surface: Color { feltColor.surface }
}
