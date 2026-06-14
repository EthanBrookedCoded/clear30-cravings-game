//
//  ConfettiPresets.swift
//  Clear30Sandbox
//
//  Lightweight in-app confetti shim. The real Clear30 app uses the
//  ConfettiSwiftUI Swift Package; the modifier names/signatures here match
//  it so games swap back unchanged. When you copy these files into the main
//  project, delete this file — the real ConfettiPresets there already
//  exists with the same surface.
//

import SwiftUI

// MARK: - Particle Model

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let emoji: String?
    let angle: Double
    let distance: CGFloat
    let rotation: Double
    let size: CGFloat
}

// MARK: - Burst View

private struct ConfettiBurst: View {
    let trigger: Int
    let colors: [Color]
    let emojis: [String]
    let num: Int
    let radius: CGFloat
    let yOffset: CGFloat

    @State private var particles: [ConfettiParticle] = []
    @State private var animate: Bool = false
    @State private var lastTrigger: Int = 0

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Group {
                    if let emoji = particle.emoji {
                        Text(emoji).font(.system(size: particle.size))
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size * 0.4)
                    }
                }
                .rotationEffect(.degrees(animate ? particle.rotation : 0))
                .offset(
                    x: animate ? cos(particle.angle) * particle.distance : 0,
                    y: animate ? sin(particle.angle) * particle.distance + yOffset : 0
                )
                .opacity(animate ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            guard newValue != lastTrigger else { return }
            lastTrigger = newValue
            fire()
        }
    }

    private func fire() {
        particles = (0..<num).map { _ in
            let color = colors.randomElement() ?? .white
            let emoji = emojis.isEmpty ? nil : emojis.randomElement()
            return ConfettiParticle(
                color: color,
                emoji: emoji,
                angle: .random(in: 0...(2 * .pi)),
                distance: .random(in: radius * 0.4...radius),
                rotation: .random(in: -720...720),
                size: emoji != nil ? 20 : .random(in: 8...14)
            )
        }
        animate = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            withAnimation(.easeOut(duration: 1.4)) {
                animate = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            particles = []
        }
    }
}

// MARK: - Modifiers (signatures match ConfettiSwiftUI presets in the main app)

struct ConfettiPop: ViewModifier {
    var colors: [Color] = [.clear30Blue, .clear30Green, .clear30Yellow]
    var num: Int = 25
    var radius: CGFloat = 100
    @Binding var confetti: Int

    func body(content: Content) -> some View {
        content.overlay(
            ConfettiBurst(trigger: confetti, colors: colors, emojis: [], num: num, radius: radius, yOffset: 0)
        )
    }
}

struct ConfettiPopEmoji: ViewModifier {
    var emojis: [String] = []
    var num: Int = 25
    var radius: CGFloat = 100
    var size: CGFloat = 20
    @Binding var confetti: Int

    func body(content: Content) -> some View {
        content.overlay(
            ConfettiBurst(trigger: confetti, colors: [.white], emojis: emojis, num: num, radius: radius, yOffset: 0)
        )
    }
}

struct ConfettiCheckIn: ViewModifier {
    var colors: [Color] = [.clear30Blue, .clear30Green, .clear30Yellow]
    var num: Int = 50
    var radius: CGFloat = 200
    var offset: CGFloat = 200
    @Binding var confetti: Int

    func body(content: Content) -> some View {
        content.overlay(
            ConfettiBurst(trigger: confetti, colors: colors, emojis: [], num: num, radius: radius, yOffset: offset)
        )
    }
}
