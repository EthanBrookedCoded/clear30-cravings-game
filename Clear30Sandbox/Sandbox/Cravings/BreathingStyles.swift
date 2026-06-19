//
//  BreathingStyles.swift
//  Clear30Sandbox
//
//  Breathwork. Redesign:
//   • Rolling-hill visual only (calm-circle option removed)
//   • Cadence chosen via chips at the bottom — NOT gradient hero cards
//   • Back button (top-left) mirrors the meditation player; presented as a sheet
//   • Opens on a caller-provided cadence (tapping a cadence chip in the hub)
//   • Round counter advances each cycle; Done → "found your calm" celebration
//
//  Presented as a stacked sheet from CravingInterventionFlow, so back/done both
//  dismiss via the environment.
//

import SwiftUI

// MARK: - Cadence

enum BreathingCadence: String, CaseIterable, Identifiable {
    case calm        // 4-4-6
    case relaxing    // 4-7-8
    case box         // 4-4-4-4 (inhale, hold, exhale, hold)

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm:     return "Calm"
        case .relaxing: return "Relaxing"
        case .box:      return "Box"
        }
    }

    var pattern: String {
        switch self {
        case .calm:     return "4-4-6"
        case .relaxing: return "4-7-8"
        case .box:      return "4-4-4-4"
        }
    }

    var subtitle: String {
        switch self {
        case .calm:     return "Default · gentle wind-down"
        case .relaxing: return "Popular sleep pattern"
        case .box:      return "Focus / stress reset"
        }
    }
}

// MARK: - Phase

private enum BreathPhase: Equatable {
    case inhale, holdIn, exhale, holdOut

    var label: String {
        switch self {
        case .inhale:  return "Breathe in"
        case .holdIn:  return "Hold"
        case .exhale:  return "Breathe out"
        case .holdOut: return "Hold"
        }
    }

    func seconds(_ cadence: BreathingCadence) -> Double {
        switch (self, cadence) {
        case (.inhale, .calm):     return 4
        case (.holdIn, .calm):     return 4
        case (.exhale, .calm):     return 6
        case (.holdOut, .calm):    return 0
        case (.inhale, .relaxing): return 4
        case (.holdIn, .relaxing): return 7
        case (.exhale, .relaxing): return 8
        case (.holdOut, .relaxing):return 0
        case (.inhale, .box):      return 4
        case (.holdIn, .box):      return 4
        case (.exhale, .box):      return 4
        case (.holdOut, .box):     return 4
        }
    }

    /// Next non-zero phase for the cadence.
    func next(_ cadence: BreathingCadence) -> BreathPhase {
        let order: [BreathPhase] = [.inhale, .holdIn, .exhale, .holdOut]
        let i = order.firstIndex(of: self) ?? 0
        for step in 1...4 {
            let candidate = order[(i + step) % 4]
            if candidate.seconds(cadence) > 0 { return candidate }
        }
        return .inhale
    }
}

// MARK: - Breathing player (rolling hill)

struct BreathingView: View {

    var initialCadence: BreathingCadence = .calm

    // A breathwork session is a fixed length and simply counts DOWN; reaching zero finishes.
    // TEMP: set to 5s for testing the end celebration — change back to 90 for production.
    private let sessionDuration: Double = 5

    @Environment(\.dismiss) private var dismiss

    @State private var cadence: BreathingCadence = .calm
    @State private var phase: BreathPhase = .inhale
    @State private var remaining: Double = 90
    @State private var visualOpacity: Double = 0   // fade the hill in / across cadence switches
    @State private var started = false             // intro gate
    @State private var task: Task<Void, Never>?
    @State private var tickTask: Task<Void, Never>?
    @State private var startTime = Date()          // breath-loop clock (resets on cadence switch)
    @State private var sessionStart = Date()       // session clock (does NOT reset)
    @State private var showDoneOverlay: Bool = false
    @State private var doneConfetti: Int = 0
    @State private var doneIconPop: Bool = false
    @State private var rewardQuote: String = ""

    var body: some View {
        ZStack {
            ambientPulse

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, GlobalData.shared.horizontalPadding)
                    .padding(.top, GlobalData.shared.headingTopPadding * 2)

                Spacer()

                ballHillVisual
                    .frame(maxWidth: .infinity)
                    .opacity(visualOpacity)
                    .scaleEffect(0.96 + visualOpacity * 0.04)

                Spacer()

                cadenceChips
                    .padding(.horizontal, GlobalData.shared.horizontalPadding)
                    .padding(.bottom, GlobalData.shared.cardSpacing * 2.5)
            }

            if showDoneOverlay { doneOverlay }

            // Intro fades in before the breathing begins (mirrors the games).
            if !started {
                GameIntroView(
                    title: "Breathe",
                    symbol: "wind",
                    blurb: "A moment to slow everything down.",
                    lines: [
                        .init(icon: "arrow.up.and.down", text: "Follow the ball up as you inhale, down as you exhale"),
                        .init(icon: "metronome", text: "Pick a cadence that feels right"),
                        .init(icon: "timer", text: "Breathe along until the timer runs out")
                    ],
                    gradient: GlobalData.shared.meditationGradient
                ) { startSession() }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear30Background.ignoresSafeArea())
        .modifier(ConfettiCheckIn(
            colors: [.meditation1, .meditation2, .clear30Blue, .clear30Green, .clear30Yellow],
            num: 60, radius: 260, confetti: $doneConfetti
        ))
        .onAppear {
            cadence = initialCadence
            remaining = sessionDuration
        }
        .onDisappear { stop() }
    }

    // MARK: Top bar (X only — the timer lives at the bottom with the cadence chips)

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                GlobalData.shared.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.clear30Text.opacity(0.5))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.clear30Button))
            }
            .modifier(DefaultButtonStyle(shadow: false))
        }
    }

    private var timerPill: some View {
        HStack(spacing: GlobalData.shared.cardSpacing / 2) {
            Image(systemName: "timer").foregroundColor(.clear30Text.opacity(0.5))
            TinyText(text: formatTime(remaining))
                .opacity(0.6)
                .contentTransition(.numericText())
                .animation(.snappy, value: Int(remaining))
        }
        .padding(.horizontal, GlobalData.shared.cardSpacing)
        .padding(.vertical, GlobalData.shared.cardSpacing / 2)
        .background(Capsule().fill(Color.clear30Button))
    }

    // MARK: Ambient pulse (whole-screen breath)

    private var ambientPulse: some View {
        ZStack {
            Color.clear30Background
            RadialGradient(
                colors: [Color.meditation1.opacity(0.25), Color.clear30Background.opacity(0)],
                center: .center, startRadius: 50, endRadius: 500
            )
            .opacity(0.3)
        }
        .ignoresSafeArea()
    }

    // MARK: Ball-on-hill visual

    private var ballHillVisual: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
                RollercoasterScene(
                    size: geo.size,
                    now: context.date,
                    startDate: startTime,
                    cadence: cadence
                )
            }
        }
        .frame(height: 280)
        .padding(.horizontal, GlobalData.shared.horizontalPadding)
    }

    // MARK: Cadence chips (distinct visual language — not hero cards)

    private var cadenceChips: some View {
        VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing / 2) {
            HStack {
                TinyText(text: "Cadence").opacity(0.5)
                Spacer()
                timerPill
            }
            HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                ForEach(BreathingCadence.allCases) { c in
                    let selected = c == cadence
                    Button {
                        GlobalData.shared.lightImpact()
                        switchCadence(c)
                    } label: {
                        TinyText(text: "\(c.title) · \(c.pattern)")
                            .foregroundColor(selected ? .white : .clear30Text)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background {
                                if selected {
                                    Capsule().fill(GlobalData.shared.meditationGradient)
                                } else {
                                    Capsule().strokeBorder(Color.clear30OpacityGray, lineWidth: 1.5)
                                }
                            }
                    }
                    .modifier(DefaultButtonStyle(shadow: false))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let total = max(0, Int(t.rounded(.up)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: Loops

    private func startSession() {
        withAnimation(GlobalData.shared.springAnimation) { started = true }
        sessionStart = Date()
        remaining = sessionDuration
        startBreathLoop()
        startTick()
        // Ease the breathing visual in before it starts moving.
        withAnimation(.easeOut(duration: 0.7)) { visualOpacity = 1 }
    }

    private func startBreathLoop() {
        startTime = Date()
        task?.cancel()
        phase = .inhale
        task = Task {
            while !Task.isCancelled {
                await runPhase(phase)
                phase = phase.next(cadence)
            }
        }
    }

    private func startTick() {
        tickTask?.cancel()
        tickTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    remaining = max(0, sessionDuration - Date().timeIntervalSince(sessionStart))
                    if remaining <= 0 { finishWithCelebration() }
                }
            }
        }
    }

    /// Switch cadence: fade, restart the breath loop, and reset the countdown timer.
    private func switchCadence(_ c: BreathingCadence) {
        guard c != cadence else { return }
        withAnimation(.easeInOut(duration: 0.28)) { visualOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cadence = c
            sessionStart = Date()
            remaining = sessionDuration
            startBreathLoop()
            withAnimation(.easeOut(duration: 0.6)) { visualOpacity = 1 }
        }
    }

    private func runPhase(_ p: BreathPhase) async {
        let seconds = p.seconds(cadence)
        await MainActor.run { GlobalData.shared.lightImpact() }
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    private func stop() {
        task?.cancel()
        tickTask?.cancel()
        task = nil
        tickTask = nil
    }

    // MARK: Done flow (with celebration)

    private func finishWithCelebration() {
        guard !showDoneOverlay else { return }
        stop()
        rewardQuote = GameQuotes.randomBreathingReward()
        GlobalData.shared.successHeavy()
        withAnimation(GlobalData.shared.springAnimation) { showDoneOverlay = true }
        withAnimation(GlobalData.shared.springAnimation.delay(0.12)) { doneIconPop = true }
        doneConfetti += 1
        // No auto-dismiss — the overlay waits for "Go again" or "Done".
    }

    /// Restart a fresh breathing session from the celebration overlay.
    private func goAgain() {
        doneIconPop = false
        withAnimation(GlobalData.shared.springAnimation) { showDoneOverlay = false }
        startSession()
    }

    private var doneOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()

            VStack(spacing: GlobalData.shared.cardSpacing) {
                ZStack {
                    Circle().fill(.white.opacity(0.25)).frame(width: 100, height: 100)
                    Circle().fill(GlobalData.shared.meditationGradient).frame(width: 80, height: 80)
                        .shadow(color: .meditation1.opacity(0.5), radius: 20)
                    Circle().stroke(.white.opacity(0.5), lineWidth: 2).frame(width: 80, height: 80)
                    Image(systemName: "wind")
                        .resizable().aspectRatio(contentMode: .fit).frame(width: 38)
                        .foregroundColor(.white)
                }
                .scaleEffect(doneIconPop ? 1 : 0.6)

                VStack(spacing: GlobalData.shared.cardSpacing / 2) {
                    Heading3(text: "You found your calm 🌿")
                    SmallText(text: rewardQuote)
                        .opacity(0.75)
                        .multilineTextAlignment(.center)
                }

                breathingStats
                    .padding(.top, GlobalData.shared.cardSpacing / 2)

                VStack(spacing: GlobalData.shared.cardSpacing) {
                    Button {
                        GlobalData.shared.mediumImpact()
                        goAgain()
                    } label: {
                        HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                            Image(systemName: "arrow.clockwise")
                            SmallText(text: "Go again")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .modifier(CardStyle(gradient: GlobalData.shared.meditationGradient))
                    }
                    .modifier(DefaultButtonStyle(shadow: false))

                    Button {
                        GlobalData.shared.mediumImpact()
                        dismiss()
                    } label: {
                        SmallText(text: "Done")
                            .frame(maxWidth: .infinity)
                            .modifier(CardStyle(color: .clear30Button))
                    }
                    .modifier(DefaultButtonStyle(shadow: false))
                }
                .padding(.top, GlobalData.shared.cardSpacing / 2)
            }
            .padding(GlobalData.shared.cardSpacing * 2)
            .frame(maxWidth: .infinity)
            .modifier(CardStyle(
                color: .clear30Button,
                outlineGradient: GlobalData.shared.meditationGradient,
                outlineWidth: 1.5,
                outlineOpacity: 0.5
            ))
            .padding(.horizontal, GlobalData.shared.horizontalPadding)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var breathingStats: some View {
        breathingStat(value: formatTime(sessionDuration - remaining), label: "breathed")
    }

    private func breathingStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Heading3(text: value)
                .foregroundStyle(GlobalData.shared.meditationGradient)
            TinyText(text: label).opacity(0.5)
        }
    }
}

// MARK: - Rollercoaster scene
//
// Ball is fixed at canvas centre. A wave-shaped track (one breath cycle fitted to the
// screen width) scrolls right-to-left underneath it. Wave shape = the breathing cadence
// over time: inhale rises 0→1, holdIn flat at 1, exhale falls 1→0, holdOut flat at 0.

private struct BreathCurve {
    let inhale: Double
    let holdIn: Double
    let exhale: Double
    let holdOut: Double

    init(cadence: BreathingCadence) {
        inhale  = BreathPhase.inhale.seconds(cadence)
        holdIn  = BreathPhase.holdIn.seconds(cadence)
        exhale  = BreathPhase.exhale.seconds(cadence)
        holdOut = BreathPhase.holdOut.seconds(cadence)
    }

    var cycleDuration: Double { max(0.001, inhale + holdIn + exhale + holdOut) }

    func value(at c: CGFloat) -> CGFloat {
        let total = cycleDuration
        let t = Double(c) * total
        let endInhale = inhale
        let endHoldIn = inhale + holdIn
        let endExhale = inhale + holdIn + exhale

        if t < endInhale {
            return CGFloat(Self.smoothstep(t / max(0.001, inhale)))
        } else if t < endHoldIn {
            return 1
        } else if t < endExhale {
            let local = (t - endHoldIn) / max(0.001, exhale)
            return CGFloat(1 - Self.smoothstep(local))
        } else {
            return 0
        }
    }

    /// Phase label at cycle progress c — derived from the same curve as the ball, so the
    /// label always matches what the ball is doing (no separate timer to drift out of sync).
    func phaseLabel(at c: CGFloat) -> String {
        let t = Double(c) * cycleDuration
        let endInhale = inhale
        let endHoldIn = inhale + holdIn
        let endExhale = inhale + holdIn + exhale
        if t < endInhale { return "Breathe in" }
        else if t < endHoldIn { return "Hold" }
        else if t < endExhale { return "Breathe out" }
        else { return "Hold" }
    }

    private static func smoothstep(_ x: Double) -> Double {
        let c = max(0, min(1, x))
        return c * c * (3 - 2 * c)
    }

    func currentCycleProgress(elapsed: Double) -> CGFloat {
        let mod = elapsed.truncatingRemainder(dividingBy: cycleDuration)
        return CGFloat(mod < 0 ? mod + cycleDuration : mod) / CGFloat(cycleDuration)
    }
}

private struct RollercoasterScene: View {

    let size: CGSize
    let now: Date
    let startDate: Date
    let cadence: BreathingCadence

    private var elapsed: Double { max(0, now.timeIntervalSince(startDate)) }
    private let ballRadius: CGFloat = 18

    var body: some View {
        let curve = BreathCurve(cadence: cadence)
        let ballX = size.width / 2
        // Sit the wave a touch lower in the canvas.
        let baseY = size.height * 0.85
        let peakY = size.height * 0.29
        let amplitude = baseY - peakY
        let scrollSpeed = size.width / CGFloat(curve.cycleDuration)
        let currentC = curve.currentCycleProgress(elapsed: elapsed)
        let ballY = baseY - curve.value(at: currentC) * amplitude
        let label = curve.phaseLabel(at: currentC)

        return ZStack {
            trackCanvas(curve: curve, ballX: ballX, baseY: baseY,
                        amplitude: amplitude, scrollSpeed: scrollSpeed)
            nowLine(ballX: ballX, top: peakY - ballRadius, bottom: baseY + ballRadius)
            ball(ballX: ballX, ballY: ballY)
            phaseChip(label: label)
        }
    }

    private func trackCanvas(curve: BreathCurve, ballX: CGFloat,
                             baseY: CGFloat, amplitude: CGFloat,
                             scrollSpeed: CGFloat) -> some View {
        Canvas { ctx, canvasSize in
            let cycle = curve.cycleDuration
            let stride: CGFloat = 3

            var top = Path()
            var px: CGFloat = 0
            var first = true
            while px <= canvasSize.width {
                let waveTime = elapsed + Double((px - ballX) / scrollSpeed)
                var mod = waveTime.truncatingRemainder(dividingBy: cycle)
                if mod < 0 { mod += cycle }
                let c = CGFloat(mod / cycle)
                let y = baseY - curve.value(at: c) * amplitude
                let p = CGPoint(x: px, y: y)
                if first { top.move(to: p); first = false } else { top.addLine(to: p) }
                px += stride
            }

            var fill = top
            fill.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height))
            fill.addLine(to: CGPoint(x: 0, y: canvasSize.height))
            fill.closeSubpath()
            ctx.fill(fill, with: .color(Color.meditation1.opacity(0.25)))

            ctx.stroke(
                top,
                with: .color(Color.meditation1),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func nowLine(ballX: CGFloat, top: CGFloat, bottom: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: ballX, y: top))
            path.addLine(to: CGPoint(x: ballX, y: bottom))
        }
        .stroke(Color.meditation1.opacity(0.25),
                style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
    }

    private func ball(ballX: CGFloat, ballY: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.meditation1.opacity(0.25))
                .frame(width: 70, height: 70)
                .blur(radius: 12)

            Circle()
                .fill(.white)
                .frame(width: ballRadius * 2, height: ballRadius * 2)
                .overlay { Circle().strokeBorder(Color.meditation1, lineWidth: 3) }
                .overlay {
                    Circle()
                        .fill(.white.opacity(0.75))
                        .frame(width: 8, height: 8)
                        .offset(x: -6, y: -6)
                }
                .shadow(color: Color.meditation1.opacity(0.5), radius: 8, y: 4)
        }
        // Sit the ball ON the line (centre near the track) rather than floating above it.
        .position(x: ballX, y: ballY - ballRadius * 0.35)
    }

    private func phaseChip(label: String) -> some View {
        HStack(spacing: GlobalData.shared.cardSpacing / 4) {
            Image(systemName: "wind")
                .foregroundColor(.meditation1)
                .font(.system(size: 13, weight: .semibold))
            Text(label)
                .font(.custom("Lexend", size: 15.5).weight(.medium))
                .foregroundColor(.clear30Text)
        }
        .padding(.horizontal, GlobalData.shared.cardSpacing)
        .padding(.vertical, GlobalData.shared.cardSpacing / 2)
        .background(Capsule().fill(Color.clear30Button))
        .overlay(Capsule().strokeBorder(Color.meditation1.opacity(0.5), lineWidth: 1))
        .shadow(color: .clear30Shadow, radius: 6, y: 2)
        .position(x: size.width / 2, y: 24)
        .transition(.opacity)
        .id(label)
    }
}
