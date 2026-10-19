import SwiftUI
import AppKit

public struct GrindTheme {
    public static let cardRadius: CGFloat = 16
    public static let rowRadius: CGFloat = 8
    public static let btnRadius: CGFloat = 10
    public static let checkboxSize: CGFloat = 20
    public static let checkboxRadius: CGFloat = 8

    public static let easeSpring = Animation.spring(response: 0.35, dampingFraction: 0.86)
    public static let snapSpring = Animation.spring(response: 0.25, dampingFraction: 0.70)
}

public enum GeistWeight {
    case regular
    case medium
    case semiBold
    case bold
    case mono
    
    var fontName: String {
        switch self {
        case .regular: return "Geist-Regular"
        case .medium: return "Geist-Medium"
        case .semiBold: return "Geist-SemiBold"
        case .bold: return "Geist-Bold"
        case .mono: return "GeistMono-Regular"
        }
    }
    
    var systemWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semiBold: return .semibold
        case .bold: return .bold
        case .mono: return .regular
        }
    }
}

public extension Font {
    static func geist(_ weight: GeistWeight = .regular, size: CGFloat) -> Font {
        if NSFont(name: weight.fontName, size: size) != nil {
            return .custom(weight.fontName, size: size)
        }
        if weight == .mono {
            return .system(size: size, weight: weight.systemWeight, design: .monospaced)
        }
        return .system(size: size, weight: weight.systemWeight, design: .rounded)
    }
}
