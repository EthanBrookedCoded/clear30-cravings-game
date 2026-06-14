//
//  Cards.swift
//  Clear30Sandbox
//
//  CardStyle modifier copied from the real Clear30 app.
//

import SwiftUI

struct CardStyle: ViewModifier {
    var color: Color = Color.clear30Button
    var shadowColor: Color = Color.clear30Shadow
    var cornerRadius: CGFloat = GlobalData.shared.cornerRadius
    var gradient: LinearGradient?
    var outlineGradient: LinearGradient?
    var outlineWidth: CGFloat = 3
    var outlineTrim: CGFloat? = nil
    var outlineOpacity: CGFloat = 1
    var foregroundColor: Color = Color.clear30Text
    var shadowXOffset: CGFloat = 0
    var shadowYOffset: CGFloat = 0
    var glowGradient: LinearGradient? = nil
    var transition: Bool = true
    var padding: Bool = true

    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(padding ? 16 : 0)
            .background(gradient ?? LinearGradient(colors: [color], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(gradient != nil ? Color.white : foregroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: 7, x: shadowXOffset, y: shadowYOffset)
            .overlay(
                Group {
                    if let outlineTrim {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .trim(from: 0.0, to: outlineTrim)
                            .stroke(outlineGradient ?? GlobalData.shared.clearGradient, lineWidth: outlineWidth)
                            .padding(outlineWidth / 2)
                            .rotationEffect(.degrees(180))
                            .opacity(outlineOpacity)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(outlineGradient ?? GlobalData.shared.clearGradient, lineWidth: outlineWidth)
                            .opacity(outlineOpacity)
                    }
                }
            )
            .background {
                Group {
                    if let glowGradient {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(glowGradient, lineWidth: colorScheme == .dark ? 2.5 : 2)
                            .blur(radius: colorScheme == .dark ? 4 : 3.5)
                            .opacity(colorScheme == .dark ? 0.75 : 0.5)
                    }
                }
            }
            .if(transition) { $0.transition(GlobalData.shared.defaultTransition) }
    }
}
