//
//  BreathingStyles.swift
//  Clear30Sandbox
//
//  Breathing exercise. UX upgrades:
//   • Phase label centered inside the visual, tinted per phase
//   • Subtle whole-screen breath pulse behind everything
//   • Phase-change haptics (eyes-closed friendly)
//   • Round counter + elapsed time pill
//   • Cadence picker (Calm 4-4-6 / Relaxing 4-7-8 / Box 4-4-4-4)
//   • Hill ball leaves a soft trail; circle has a delayed inner ring
//   • Done → brief "Nicely done 🌿" overlay before exit
//

import SwiftUI

// MARK: - Style

enum BreathingStyle: String, CaseIterable, Identifiable {
    case circle
    case ballHill

    var id: String { rawValue }

    var title: String {
        switch self {
        case .circle:   return "Calm circle"
        case .ballHill: return "Rolling hill"
        }
    }

    var subtitle: String {
        switch self {
        case .circle:   return "Expand and release"
        case .ballHill: return "Roll up and down"
        }
    }

    var sfSymbol: String {
        switch self {
        case .circle:   return "circle.circle.fill"
        case .ballHill: return "mountain.2.fill"
        }
    }
}

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

    var sfSymbol: String {
        switch self {
        case .calm:     return "wind"
        case .relaxing: return "moon.stars.fill"
        case .box:      return "square.dashed"
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

    var tint: Color {
        switch self {
        case .inhale:           return .clear30Blue
        case .holdIn, .holdOut: return .white
        case .exhale:           return .meditation1
        }
    }
}

// MARK: - Breathing player

struct BreathingView: View {

    let style: BreathingStyle
    var onDone: () -> Void

    @State private var cadence: BreathingCadence = .calm
    @State private var phase: BreathPhase = .inhale
    @State private var progress: CGFloat = 0           // 0 = rest, 1 = full inhale
    @State private var roundCount: Int = 0
    @State private var elapsed: TimeInterval = 0
    @State private var task: Task<Void, Never>?
    @State private var tickTask: Task<Void, Never>?
    @State private var startTime = Date()
    @State private var showCadenceSheet: Bool = false
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

                Group {
                    switch style {
                    case .circle:   circleVisual
                    case .ballHill: ballHillVisual
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer()

                bottomPill
                    .padding(.bottom, GlobalData.shared.cardSpacing)

                Button {
                    GlobalData.shared.mediumImpact()
                    finishWithCelebration()
                } label: {
                    SmallText(text: "Done").foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .modifier(CardStyle(gradient: GlobalData.shared.meditationGradient))
                }
                .modifier(DefaultButtonStyle(shadow: false))
                .padding(.horizontal, GlobalData.shared.horizontalPadding)
                .padding(.bottom, GlobalData.shared.cardSpacing * 2)
            }

            if showDoneOverlay { doneOverlay }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(ConfettiCheckIn(
            colors: [.meditation1, .meditation2, .clear30Blue, .clear30Green, .clear30Yellow],
            num: 60, radius: 260, confetti: $doneConfetti
        ))
        .onAppear { startLoop() }
        .onDisappear { stop() }
        .sheet(isPresented: $showCadenceSheet) {
            CadencePickerSheet(current: cadence) { picked in
                cadence = picked
                restartLoop()
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: GlobalData.shared.cardSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                SmallText(text: style.title)
                TinyText(text: style.subtitle).opacity(0.5)
            }
            Spacer()
            Button {
                GlobalData.shared.lightImpact()
                showCadenceSheet = true
            } label: {
                HStack(spacing: GlobalData.shared.cardSpacing / 4) {
                    Image(systemName: "metronome.fill")
                    TinyText(text: cadence.pattern)
                }
                .foregroundColor(.clear30Text)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.clear30Button))
            }
            .modifier(DefaultButtonStyle(shadow: false))
        }
    }

    // MARK: Ambient pulse (whole-screen breath)

    private var ambientPulse: some View {
        ZStack {
            Color.clear30Background
            RadialGradient(
                colors: [phase.tint.opacity(0.25), Color.clear30Background.opacity(0)],
                center: .center, startRadius: 50, endRadius: 500
            )
            // Softer ambient glow — breathes between 0.25 and 0.5 (was up to 0.75).
            .opacity(0.25 + progress * 0.25)
            .animation(.easeInOut(duration: 0.6), value: progress)
        }
        .ignoresSafeArea()
    }

    // MARK: Circle visual

    private var circleVisual: some View {
        ZStack {
            // Delayed echo ring for depth
            Circle()
                .stroke(GlobalData.shared.meditationGradient, lineWidth: 2)
                .opacity(0.5)
                .frame(width: 240, height: 240)
                .scaleEffect(0.5 + progress * 0.5)
                .blur(radius: 4)

            Circle()
                .fill(GlobalData.shared.meditationGradient)
                .frame(width: 240, height: 240)
                .scaleEffect(0.5 + progress * 0.5)
                .shadow(color: .meditation1.opacity(0.5), radius: 28)

            Circle()
                .stroke(.white.opacity(0.5), lineWidth: 2)
                .frame(width: 240, height: 240)
                .scaleEffect(0.5 + progress * 0.5)

            // Phase label centered on the visual
            Text(phase.label)
                .font(.custom("Lexend", size: 22).weight(.medium))
                .foregroundColor(.white)
                .shadow(color: .meditation1.opacity(0.5), radius: 8)
                .transition(.opacity)
                .id(phase)
        }
        .frame(height: 260)
    }

    // MARK: Ball-on-hill visual

    private var ballHillVisual: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
                RollercoasterScene(
                    size: geo.size,
                    now: context.date,
                    startDate: startTime,
                    cadence: cadence,
                    phaseLabel: phase.label,
                    phaseID: phase
                )
            }
        }
        .frame(height: 260)
        .padding(.horizontal, GlobalData.shared.horizontalPadding)
    }

    private func bezierPoint(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint) -> CGPoint {
        let mt = 1 - t
        let x = mt * mt * p0.x + 2 * mt * t * p1.x + t * t * p2.x
        let y = mt * mt * p0.y + 2 * mt * t * p1.y + t * t * p2.y
        return CGPoint(x: x, y: y)
    }

    // MARK: Bottom pill (round + time)

    private var bottomPill: some View {
        HStack(spacing: GlobalData.shared.cardSpacing / 2) {
            Image(systemName: "circle.dotted").foregroundColor(.clear30Text.opacity(0.5))
            TinyText(text: "Round \(roundCount)").opacity(0.5)
            Text("·").opacity(0.25)
            TinyText(text: formatElapsed(elapsed)).opacity(0.5)
        }
        .padding(.horizontal, GlobalData.shared.cardSpacing)
        .padding(.vertical, GlobalData.shared.cardSpacing / 2)
        .background(Capsule().fill(Color.clear30Button))
    }

    private func formatElapsed(_ t: TimeInterval) -> String {
        let total = Int(t)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: Loop

    private func startLoop() {
        startTime = Date()
        task?.cancel()
        tickTask?.cancel()

        // Drive the phase machine — sets `phase`, fires haptics, bumps roundCount.
        // The rollercoaster visual reads time directly via TimelineView, so it
        // doesn't depend on this Task; the circle visual reads `progress`.
        task = Task {
            while !Task.isCancelled {
                await runPhase(phase)
                phase = phase.next(cadence)
                if phase == .inhale { roundCount += 1 }
            }
        }
        // Elapsed-time ticker for the round/time pill.
        tickTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    elapsed = Date().timeIntervalSince(startTime)
                }
            }
        }
        if roundCount == 0 { roundCount = 1 }
    }

    private func restartLoop() {
        stop()
        phase = .inhale
        progress = 0
        roundCount = 0
        startLoop()
    }

    private func runPhase(_ p: BreathPhase) async {
        let seconds = p.seconds(cadence)
        await MainActor.run {
            GlobalData.shared.lightImpact()
            withAnimation(.easeInOut(duration: seconds)) {
                switch p {
                case .inhale:           progress = 1
                case .exhale:           progress = 0
                case .holdIn, .holdOut: break
                }
            }
        }
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
        stop()
        rewardQuote = GameQuotes.randomBreathingReward()
        GlobalData.shared.successHeavy()
        withAnimation(GlobalData.shared.springAnimation) { showDoneOverlay = true }
        withAnimation(GlobalData.shared.springAnimation.delay(0.12)) { doneIconPop = true }
        doneConfetti += 1
        // Linger long enough to feel like a payoff before moving on.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            onDone()
        }
    }

    private var doneOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()

            VStack(spacing: GlobalData.shared.cardSpacing) {
                // Animated medallion
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
        HStack(spacing: GlobalData.shared.cardSpacing * 1.5) {
            breathingStat(value: "\(roundCount)", label: roundCount == 1 ? "round" : "rounds")
            Rectangle()
                .fill(Color.clear30Text.opacity(0.25))
                .frame(width: 1, height: 30)
            breathingStat(value: formatElapsed(elapsed), label: "breathed")
        }
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
// Ball is fixed at canvas centre. A wave-shaped track (one breath cycle
// fitted to the screen width) scrolls right-to-left underneath it.
// Wave shape = the breathing cadence over time:
//   • inhale  → smoothstep rise 0→1
//   • holdIn  → flat at 1
//   • exhale  → smoothstep fall 1→0
//   • holdOut → flat at 0 (skipped when 0s)
// Ball.y = wave height at the screen centre at the current instant.

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

    /// Wave height ∈ [0, 1] at cycle progress c ∈ [0, 1).
    func value(at c: CGFloat) -> CGFloat {
        let total = cycleDuration
        let t = Double(c) * total

        let endInhale  = inhale
        let endHoldIn  = inhale + holdIn
        let endExhale  = inhale + holdIn + exhale

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

    private static func smoothstep(_ x: Double) -> Double {
        let c = max(0, min(1, x))
        return c * c * (3 - 2 * c)
    }

    /// Cycle progress of the ball (always at the canvas centre / "now").
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
    let phaseLabel: String
    let phaseID: AnyHashable

    private var elapsed: Double { max(0, now.timeIntervalSince(startDate)) }

    private let ballRadius: CGFloat = 18

    var body: some View {
        let curve = BreathCurve(cadence: cadence)
        let ballX = size.width / 2
        let baseY = size.height * 0.78
        let peakY = size.height * 0.22
        let amplitude = baseY - peakY
        let scrollSpeed = size.width / CGFloat(curve.cycleDuration)
        let currentC = curve.currentCycleProgress(elapsed: elapsed)
        let ballY = baseY - curve.value(at: currentC) * amplitude

        return ZStack {
            trackCanvas(curve: curve, ballX: ballX, baseY: baseY,
                        amplitude: amplitude, scrollSpeed: scrollSpeed)
            nowLine(ballX: ballX, top: peakY - ballRadius, bottom: baseY + ballRadius)
            ball(ballX: ballX, ballY: ballY)
            phaseChip
        }
    }

    // MARK: Track

    private func trackCanvas(curve: BreathCurve, ballX: CGFloat,
                             baseY: CGFloat, amplitude: CGFloat,
                             scrollSpeed: CGFloat) -> some View {
        Canvas { ctx, canvasSize in
            let cycle = curve.cycleDuration
            let stride: CGFloat = 3   // sample every 3 pt — smooth enough, cheap

            // Build the wave top path.
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

            // Fill the area below the curve (faint blue).
            var fill = top
            fill.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height))
            fill.addLine(to: CGPoint(x: 0, y: canvasSize.height))
            fill.closeSubpath()
            ctx.fill(fill, with: .color(Color.meditation1.opacity(0.25)))

            // Stroke the wave top.
            ctx.stroke(
                top,
                with: .color(Color.meditation1),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
            )
        }
    }

    // MARK: Faint "now" line behind the ball

    private func nowLine(ballX: CGFloat, top: CGFloat, bottom: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: ballX, y: top))
            path.addLine(to: CGPoint(x: ballX, y: bottom))
        }
        .stroke(Color.meditation1.opacity(0.25),
                style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
    }

    // MARK: Ball

    private func ball(ballX: CGFloat, ballY: CGFloat) -> some View {
        ZStack {
            // Soft glow under the ball where it "touches" the track.
            Circle()
                .fill(Color.meditation1.opacity(0.25))
                .frame(width: 70, height: 70)
                .blur(radius: 12)

            // The ball itself.
            Circle()
                .fill(.white)
                .frame(width: ballRadius * 2, height: ballRadius * 2)
                .overlay {
                    Circle().strokeBorder(Color.meditation1, lineWidth: 3)
                }
                .overlay {
                    // Inner highlight so it reads as 3-D.
                    Circle()
                        .fill(.white.opacity(0.75))
                        .frame(width: 8, height: 8)
                        .offset(x: -6, y: -6)
                }
                .shadow(color: Color.meditation1.opacity(0.5), radius: 8, y: 4)
        }
        .position(x: ballX, y: ballY - ballRadius)
    }

    // MARK: Phase label

    private var phaseChip: some View {
        HStack(spacing: GlobalData.shared.cardSpacing / 4) {
            Image(systemName: "wind")
                .foregroundColor(.meditation1)
                .font(.system(size: 13, weight: .semibold))
            Text(phaseLabel)
                .font(.custom("Lexend", size: 15.5).weight(.medium))
                .foregroundColor(.clear30Text)
        }
        .padding(.horizontal, GlobalData.shared.cardSpacing)
        .padding(.vertical, GlobalData.shared.cardSpacing / 2)
        .background(Capsule().fill(Color.clear30Button))
        .overlay(Capsule().strokeBorder(Color.meditation1.opacity(0.5), lineWidth: 1))
        .shadow(color: .clear30Shadow, radius: 6, y: 2)
        .position(x: size.width - 75, y: 24)
        .transition(.opacity)
        .id(phaseID)
    }
}


// MARK: - Cadence picker sheet

struct CadencePickerSheet: View {

    let current: BreathingCadence
    var onPick: (BreathingCadence) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Heading3(text: "Cadence")
                .padding(.bottom, GlobalData.shared.cardSpacing / 2)
            SmallText(text: "Pick a breathing pattern.").opacity(0.5)
                .padding(.bottom, GlobalData.shared.cardSpacing * 2)

            VStack(spacing: GlobalData.shared.cardSpacing) {
                ForEach(BreathingCadence.allCases) { c in
                    Button {
                        GlobalData.shared.lightImpact()
                        onPick(c)
                        dismiss()
                    } label: {
                        HStack(spacing: GlobalData.shared.cardSpacing) {
                            cadenceIconCircle(symbol: c.sfSymbol)
                            VStack(alignment: .leading, spacing: 2) {
                                SmallText(text: "\(c.title) · \(c.pattern)").foregroundColor(.white)
                                TinyText(text: c.subtitle).foregroundColor(.white.opacity(0.75))
                            }
                            Spacer()
                            if c == current {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "chevron.right")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12)
                                    .foregroundColor(.white.opacity(0.75))
                            }
                        }
                        .modifier(CardStyle(gradient: GlobalData.shared.meditationGradient))
                    }
                    .modifier(DefaultButtonStyle(shadow: false))
                }
            }

            Spacer()
        }
        .padding(.horizontal, GlobalData.shared.horizontalPadding)
        .padding(.top, GlobalData.shared.headingTopPadding * 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.clear30Background.ignoresSafeArea())
    }

    private func cadenceIconCircle(symbol: String) -> some View {
        ZStack {
            Circle().fill(.white.opacity(0.25)).frame(width: 56, height: 56)
            Circle().fill(.white).frame(width: 48, height: 48)
                .shadow(color: .white.opacity(0.5), radius: 5)
                .shadow(color: .white.opacity(0.25), radius: 11)
                .overlay {
                    Image(systemName: symbol)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22)
                        .foregroundStyle(GlobalData.shared.meditationGradient)
                }
        }
    }
}

// MARK: - After-round style picker

struct BreathingPickerView: View {

    var onPick: (BreathingStyle) -> Void
    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing / 2) {
                Heading2(text: "Nice and slow 🌿")
                SmallText(text: "Go again, or try a different style.").opacity(0.5)
            }
            .padding(.bottom, GlobalData.shared.cardSpacing * 2)

            Spacer()

            VStack(spacing: GlobalData.shared.cardSpacing) {
                ForEach(BreathingStyle.allCases) { style in
                    GradientActionButton(
                        text: style.title,
                        sfSymbol: style.sfSymbol,
                        gradient: GlobalData.shared.meditationGradient
                    ) {
                        GlobalData.shared.lightImpact()
                        onPick(style)
                    }
                }

                Button {
                    GlobalData.shared.mediumImpact()
                    onDone()
                } label: {
                    HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                        Image(systemName: "checkmark")
                        SmallText(text: "I'm good")
                    }
                    .frame(maxWidth: .infinity)
                    .modifier(CardStyle(color: .clear30Button))
                }
                .modifier(DefaultButtonStyle(shadow: false))
            }
        }
        .padding(.horizontal, GlobalData.shared.horizontalPadding)
        .padding(.vertical, GlobalData.shared.cardSpacing * 3)
    }
}
