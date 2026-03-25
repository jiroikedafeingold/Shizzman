import SwiftUI

// MARK: - Texture style

enum FeltTexture {
    case plain, grain, crosshatch, diagonal, grid, horizontal
}

// MARK: - Felt colour + texture palette

enum FeltColor: String, CaseIterable {
    // Original solid colours
    case green    = "green"
    case blue     = "blue"
    case burgundy = "burgundy"
    case charcoal = "charcoal"
    case teal     = "teal"
    case navy     = "navy"
    // Textured themes
    case classicFelt = "classicFelt"
    case baizeGreen  = "baizeGreen"
    case linen       = "linen"
    case onyx        = "onyx"
    case mahogany    = "mahogany"
    case plum        = "plum"

    var label: String {
        switch self {
        case .green:       return "Green"
        case .blue:        return "Blue"
        case .burgundy:    return "Burgundy"
        case .charcoal:    return "Charcoal"
        case .teal:        return "Teal"
        case .navy:        return "Navy"
        case .classicFelt: return "Felt"
        case .baizeGreen:  return "Baize"
        case .linen:       return "Linen"
        case .onyx:        return "Onyx"
        case .mahogany:    return "Mahogany"
        case .plum:        return "Plum"
        }
    }

    var felt: Color {
        switch self {
        case .green:       return Color(red: 0.07, green: 0.12, blue: 0.09)
        case .blue:        return Color(red: 0.06, green: 0.09, blue: 0.18)
        case .burgundy:    return Color(red: 0.14, green: 0.06, blue: 0.08)
        case .charcoal:    return Color(red: 0.09, green: 0.09, blue: 0.11)
        case .teal:        return Color(red: 0.05, green: 0.13, blue: 0.14)
        case .navy:        return Color(red: 0.05, green: 0.07, blue: 0.16)
        case .classicFelt: return Color(red: 0.05, green: 0.16, blue: 0.07)
        case .baizeGreen:  return Color(red: 0.04, green: 0.20, blue: 0.10)
        case .linen:       return Color(red: 0.15, green: 0.11, blue: 0.08)
        case .onyx:        return Color(red: 0.04, green: 0.04, blue: 0.06)
        case .mahogany:    return Color(red: 0.16, green: 0.07, blue: 0.03)
        case .plum:        return Color(red: 0.12, green: 0.05, blue: 0.18)
        }
    }

    // Slightly lighter surface tone for each colour
    var surface: Color {
        switch self {
        case .green:       return Color(red: 0.11, green: 0.17, blue: 0.13)
        case .blue:        return Color(red: 0.10, green: 0.14, blue: 0.24)
        case .burgundy:    return Color(red: 0.20, green: 0.10, blue: 0.12)
        case .charcoal:    return Color(red: 0.14, green: 0.14, blue: 0.16)
        case .teal:        return Color(red: 0.09, green: 0.18, blue: 0.20)
        case .navy:        return Color(red: 0.09, green: 0.12, blue: 0.22)
        case .classicFelt: return Color(red: 0.09, green: 0.21, blue: 0.11)
        case .baizeGreen:  return Color(red: 0.08, green: 0.26, blue: 0.14)
        case .linen:       return Color(red: 0.22, green: 0.16, blue: 0.12)
        case .onyx:        return Color(red: 0.11, green: 0.11, blue: 0.13)
        case .mahogany:    return Color(red: 0.24, green: 0.12, blue: 0.06)
        case .plum:        return Color(red: 0.20, green: 0.09, blue: 0.26)
        }
    }

    var texture: FeltTexture {
        switch self {
        case .green, .blue, .burgundy, .charcoal, .teal, .navy:
            return .plain
        case .classicFelt: return .grain
        case .baizeGreen:  return .diagonal
        case .linen:       return .crosshatch
        case .onyx:        return .grid
        case .mahogany:    return .horizontal
        case .plum:        return .grain
        }
    }

    var textureOpacity: Double {
        switch self {
        case .green, .blue, .burgundy, .charcoal, .teal, .navy:
            return 0
        case .classicFelt, .baizeGreen, .mahogany, .plum:
            return 0.12
        case .linen, .onyx:
            return 0.10
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
