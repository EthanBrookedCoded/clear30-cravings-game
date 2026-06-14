//
//  Colors.swift
//  Clear30Sandbox
//
//  Brand colors lifted from the main Clear30 asset catalog so the sandbox
//  matches the real app's palette without needing the asset catalog itself.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch trimmed.count {
        case 6: (r, g, b, a) = ((int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff, 255)
        case 8: (r, g, b, a) = ((int >> 24) & 0xff, (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        default: (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

extension Color {
    static let clear30Blue       = Color(hex: "#5BB4A9")
    static let clear30Green      = Color(hex: "#80C97A")
    static let clear30Yellow     = Color(hex: "#FFF87E")
    static let clear30Background = Color(.systemBackground)
    static let clear30Button     = Color(.secondarySystemBackground)
    static let clear30Shadow     = Color.black.opacity(0.25)
    static let clear30Text       = Color(.label)
    static let clear30OpacityGray = Color.gray.opacity(0.25)

    static let meditation1 = Color(hex: "#5B9CF0")
    static let meditation2 = Color(hex: "#5BAEE6")
}
