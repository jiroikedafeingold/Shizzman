import SwiftUI

enum Theme {
    static let felt     = Color(red: 0.07, green: 0.12, blue: 0.09)
    static let surface  = Color(red: 0.11, green: 0.17, blue: 0.13)
    static let elevated = Color(red: 0.16, green: 0.23, blue: 0.18)
    static let cardFace = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let cardBack = Color(red: 0.16, green: 0.22, blue: 0.38)
    static let border   = Color.white.opacity(0.09)

    static let primary   = Color.white.opacity(0.97)
    static let secondary = Color.white.opacity(0.88)
    static let tertiary  = Color.white.opacity(0.68)

    static let burn  = Color(red: 0.90, green: 0.34, blue: 0.24)
    static let reset = Color(red: 0.34, green: 0.66, blue: 0.92)
    static let low   = Color(red: 0.92, green: 0.72, blue: 0.24)
    static let valid = Color(red: 0.32, green: 0.78, blue: 0.50)
    static let hint  = Color(red: 0.92, green: 0.78, blue: 0.30)
    static let warn  = Color(red: 0.92, green: 0.55, blue: 0.20)

    static func display(_ s: CGFloat = 52) -> Font { .system(size: s, weight: .ultraLight, design: .rounded) }
    static func title(_ s: CGFloat = 28) -> Font   { .system(size: s, weight: .light,      design: .rounded) }
    static func headline(_ s: CGFloat = 17) -> Font { .system(size: s, weight: .semibold,  design: .rounded) }
    static func label(_ s: CGFloat = 16) -> Font   { .system(size: s, weight: .medium,     design: .rounded) }
    static func caption(_ s: CGFloat = 13) -> Font { .system(size: s, weight: .medium,     design: .rounded) }
    static func mono(_ s: CGFloat = 14) -> Font    { .system(size: s, weight: .medium, design: .monospaced) }

    static let cW: CGFloat  = 46
    static let cH: CGFloat  = 65
    static let rSm: CGFloat = 6
    static let rMd: CGFloat = 12
    static let rLg: CGFloat = 18
}

extension View {
    func cShadow() -> some View { shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2) }
    func pShadow() -> some View { shadow(color: .black.opacity(0.28), radius: 8, x: 0, y: 4) }
}
