import Foundation
import CoreText
import AppKit

public final class FontManager {
    public static let shared = FontManager()
    private var registered = false
    
    public func registerCustomFonts() {
        guard !registered else { return }
        registered = true
        
        let bundle = Bundle.main
        let fontNames = [
            "Geist-Regular.otf",
            "Geist-Medium.otf",
            "Geist-SemiBold.otf",
            "Geist-Bold.otf",
            "GeistMono-Regular.otf",
            "GeistMono-Medium.otf",
            "GeistMono-SemiBold.otf",
            "GeistMono-Bold.otf",
            "GeistPixel-Square.otf"
        ]
        
        for name in fontNames {
            if let url = bundle.url(forResource: name, withExtension: nil) {
                var errorRef: Unmanaged<CFError>?
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, &errorRef)
            }
        }
    }
}
