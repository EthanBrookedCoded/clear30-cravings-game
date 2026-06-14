//
//  GlobalData.swift
//  Clear30Sandbox
//
//  Mirrors the GlobalData singleton from the real Clear30 app so view code
//  can be lifted between projects unchanged.
//

import SwiftUI
import UIKit

class GlobalData {
    static let shared = GlobalData()

    public let horizontalPadding: CGFloat = 25
    public let headingTopPadding: CGFloat = 10

    public let cardSpacing: CGFloat = 14
    public let buttonHorizontalPadding: CGFloat = 25 / 1.5
    public let buttonVerticalPadding: CGFloat = 25
    public let cornerRadius: CGFloat = 21
    public let scrollShadowFix: CGFloat = 20

    public let defaultAnimation: Animation = .default.speed(1.5)
    public let springAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.4)
    public let defaultTransition: AnyTransition = .scale.animation(.spring(response: 0.175, dampingFraction: 1, blendDuration: 1))

    public let clear30Gradient = LinearGradient(colors: [.clear30Blue, .clear30Green], startPoint: .leading, endPoint: .trailing)
    public let clear30GradientBright = LinearGradient(colors: [Color(hex: "#26CD6A"), Color(hex: "#00BCA5")], startPoint: .bottomLeading, endPoint: .topTrailing)
    public let meditationGradient = LinearGradient(colors: [.meditation1, .meditation2], startPoint: .leading, endPoint: .trailing)
    public let symptomCardGradient = LinearGradient(colors: [Color(hex: "#FF8C59"), Color(hex: "#FFA372")], startPoint: .bottomLeading, endPoint: .topTrailing)
    public let claireGradient = LinearGradient(colors: [Color(hex: "#5C70EF"), Color(hex: "#8969FF")], startPoint: .leading, endPoint: .trailing)
    public let sleepGradient = LinearGradient(colors: [Color(hex: "#14435E"), Color(hex: "#1C5E80")], startPoint: .bottomLeading, endPoint: .topTrailing)

    public let redColor1: Color = Color(hex: "#f65555")
    public let redColor2: Color = Color(hex: "#fb5151")
    public let redGradient = LinearGradient(colors: [Color(hex: "#f65555"), Color(hex: "#fb5151")], startPoint: .bottomLeading, endPoint: .topTrailing)

    public let whiteGradient = LinearGradient(colors: [.white, .white], startPoint: .leading, endPoint: .trailing)
    public let clearGradient = LinearGradient(colors: [.clear, .clear], startPoint: .leading, endPoint: .trailing)
    public let almostClearGradient = LinearGradient(colors: [Color.clear30Background.opacity(0.001), Color.clear30Background.opacity(0.001)], startPoint: .leading, endPoint: .trailing)

    public let lightHaptic = UIImpactFeedbackGenerator(style: .soft)
    public let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    public let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    public let notificationHaptic = UINotificationFeedbackGenerator()

    public func lightImpact()   { lightHaptic.impactOccurred() }
    public func mediumImpact()  { mediumHaptic.impactOccurred() }
    public func heavyImpact()   { heavyHaptic.impactOccurred() }
    public func successHeavy()  { notificationHaptic.notificationOccurred(.success) }
}

// MARK: - View helpers used by Card/Button styles

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
