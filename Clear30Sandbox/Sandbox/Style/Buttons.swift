//
//  Buttons.swift
//  Clear30Sandbox
//
//  DefaultButtonStyle + small selection of button shells from the real app.
//

import SwiftUI

struct NoOpacityChangeButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
    }
}

struct DefaultButtonStyle: ViewModifier {
    var shadow: Bool = true
    var shadowColor: Color = Color.clear30Shadow
    var transition: Bool = true
    var animate: Bool = true
    @State private var isPressed: Bool = false

    func body(content: Content) -> some View {
        content
            .buttonStyle(NoOpacityChangeButtonStyle())
            .shadow(color: shadow ? shadowColor : Color.clear, radius: 10, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.15, dampingFraction: 0.5, blendDuration: 0), value: isPressed)
            .if(animate) { view in
                view.onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { p in
                    isPressed = p
                }, perform: {})
            }
            .if(transition) { $0.transition(GlobalData.shared.defaultTransition) }
    }
}

struct GradientActionButton: View {
    var text: String
    var sfSymbol: String
    var gradient: LinearGradient
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: GlobalData.shared.cardSpacing) {
                ZStack {
                    RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 2)
                        .fill(.white.opacity(0.25))
                        .frame(width: 36, height: 36)
                    Image(systemName: sfSymbol)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18)
                        .foregroundColor(.white)
                }
                SmallText(text: text)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12)
                    .foregroundColor(.white.opacity(0.75))
            }
            .modifier(CardStyle(gradient: gradient))
        }
        .modifier(DefaultButtonStyle(shadow: false))
    }
}

struct TinyTextButton: View {
    var text: String
    var icon: String? = nil
    var foreground: Color = .clear30Text
    var background: Color = .clear30OpacityGray
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(foreground)
                }
                TinyText(text: text)
                    .foregroundColor(foreground)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 12).fill(background)
            )
        }
        .modifier(DefaultButtonStyle(shadow: false))
    }
}
