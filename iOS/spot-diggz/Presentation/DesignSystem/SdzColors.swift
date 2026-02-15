import SwiftUI
import UIKit

/// Design system color tokens for SpotDiggz.
///
/// All colors are backed by named assets in the Asset Catalog,
/// supporting both Light and Dark appearances automatically.
extension Color {
    // MARK: - Backgrounds
    static let sdzBackground = Color("SdzBackground")
    static let sdzBgSecondary = Color("SdzBgSecondary")
    static let sdzBgTertiary = Color("SdzBgTertiary")

    // MARK: - Surfaces
    static let sdzSurface = Color("SdzSurface")
    static let sdzSurfaceElevated = Color("SdzSurfaceElevated")

    // MARK: - Text
    static let sdzTextPrimary = Color("SdzTextPrimary")
    static let sdzTextSecondary = Color("SdzTextSecondary")
    static let sdzTextTertiary = Color("SdzTextTertiary")

    // MARK: - Borders & Dividers
    static let sdzBorder = Color("SdzBorder")
    static let sdzDivider = Color("SdzDivider")

    // MARK: - Spot Types
    static let sdzPark = Color("SdzPark")
    static let sdzStreet = Color("SdzStreet")

    // MARK: - Semantic
    static let sdzSuccess = Color("SdzSuccess")
    static let sdzWarning = Color("SdzWarning")
    static let sdzError = Color("SdzError")
    static let sdzInfo = Color("SdzInfo")
}

/// UIColor bridge for MapKit annotation views and UIKit interop.
extension UIColor {
    static let sdzPark = UIColor(named: "SdzPark") ?? UIColor(red: 0.24, green: 0.72, blue: 0.36, alpha: 1)
    static let sdzStreet = UIColor(named: "SdzStreet") ?? UIColor(red: 0.20, green: 0.48, blue: 0.92, alpha: 1)
    static let sdzSuccess = UIColor(named: "SdzSuccess") ?? UIColor.systemGreen
    static let sdzWarning = UIColor(named: "SdzWarning") ?? UIColor.systemOrange
    static let sdzError = UIColor(named: "SdzError") ?? UIColor.systemRed
}
