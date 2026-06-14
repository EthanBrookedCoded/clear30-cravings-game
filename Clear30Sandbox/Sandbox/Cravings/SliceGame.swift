//
//  SliceGame.swift
//  Clear30Sandbox
//
//  Mapped to "A lot" and "Extreme" intensities (Discharge removed).
//  Fruit-Ninja style: craving cues (red) = slice, Clear30 things (green)
//  = avoid. Targets never spawn overlapping.
//
//  12 levels — timed sessions:
//   Easy 1–4   : 30s,  slow spawns, 20–30% green
//   Normal 5–8 : 60s,  medium spawns + occasional waves, 35–45% green
//   Hard 9–12  : 90s,  fast multi-spawns, 50–60% green
//   Infinite   : no timer, plays until user ends.
//

import SwiftUI

enum TargetIcon: Equatable {
    case sfSymbol(String)
    case image(String)             // full-color image (e.g. Clear30 logo)
    case templateImage(String)     // monochrome image rendered like an SF Symbol (white tint)
}

struct SliceTarget: Identifiable, Equatable {
    enum Kind { case craving, clear30 }
    let id = UUID()
    let kind: Kind
    let icon: TargetIcon
    var position: CGPoint
    var radius: CGFloat
    var spawnedAt: Date = Date()
    var lifeSeconds: Double

    static let cravingIcons: [TargetIcon] = [
        // Imported cannabis icon set — all rendered as white template images so
        // they blend into the red target exactly like the old SF symbols did.
        .templateImage("CannabisSymbol"),
        .templateImage("CannabisPlant"),
        .templateImage("CannabisBong"),
        .templateImage("CannabisJar"),
        .templateImage("CannabisDispensary"),
        .templateImage("CannabisCBD"),
        .templateImage("CannabisBadge"),
        .templateImage("CannabisPerson"),
        .templateImage("CannabisSearch")
    ]
    static let clear30Icons: [TargetIcon] = [
        .image("Clear30Logo"), .image("Clear30Logo"),
        .sfSymbol("figure.walk"), .sfSymbol("figure.mind.and.body"),
        .sfSymbol("figure.run"), .sfSymbol("figure.cooldown"),
        .sfSymbol("heart.fill"), .sfSymbol("leaf.fill"),
        .sfSymbol("sun.max.fill"), .sfSymbol("dumbbell.fill"), .sfSymbol("bicycle")
    ]
}

private struct TrailPoint: Identifiable, Equatable {
    let id = UUID()
    var position: CGPoint
    var bornAt: Date = Date()
}

private struct SliceBurst: Identifiable, Equatable {
    enum Kind { case craving, clear30 }
    let id = UUID()
    let position: CGPoint
    let kind: Kind
}

// MARK: - Engine

@Observable
final class SliceEngine {

    var mode: GameMode = .level(1)
    var targets: [SliceTarget] = []
    var score: Int = 0
    var combo: Int = 0
    var maxCombo: Int = 0
    var elapsed: Double = 0
    var remaining: Double = 0
    var cleared: Bool = false
    var rewardQuote: String = ""
    var penaltyFlash: Int = 0
    var penaltyToast: String? = nil

    private var spawnTask: Task<Void, Never>?
    private var tickTask:  Task<Void, Never>?
    private var startTime = Date()
    private var arenaSize: CGSize = .zero

    /// Per-level duration in seconds. Infinite returns 0 (unused).
    var duration: Double {
        guard !mode.isInfinite else { return 0 }
        return 30 + GameLevels.fraction(mode.levelValue) * 60   // L1: 30s, L12: 90s
    }

    /// 0...1 difficulty fraction for spawn/green/wave shaping.
    private var fraction: Double {
        if mode.isInfinite { return min(1, elapsed / 90) }
        return GameLevels.fraction(mode.levelValue)
    }

    func start(mode: GameMode, in size: CGSize) {
        self.mode = mode
        arenaSize = size
        startTime = Date()
        score = 0; combo = 0; maxCombo = 0; elapsed = 0
        cleared = false; rewardQuote = ""
        remaining = duration
        targets = []
        spawnLoop(); tickLoop()
    }

    func stop() {
        spawnTask?.cancel(); tickTask?.cancel()
        spawnTask = nil; tickTask = nil
    }

    @discardableResult
    func registerSlice(point: CGPoint) -> [SliceTarget] {
        var hit: [SliceTarget] = []
        var remainingTargets: [SliceTarget] = []
        let grace: CGFloat = 10
        for t in targets {
            let dx = t.position.x - point.x, dy = t.position.y - point.y
            if sqrt(dx * dx + dy * dy) < t.radius + grace { hit.append(t) } else { remainingTargets.append(t) }
        }
        if hit.isEmpty { return [] }
        targets = remainingTargets
        for t in hit {
            switch t.kind {
            case .craving:
                score += 1 + max(0, combo / 3)
                combo += 1
                maxCombo = max(maxCombo, combo)
            case .clear30:
                combo = 0
                score = max(0, score - 2)
                penaltyFlash += 1
                penaltyToast = "Don't slice the good stuff!"
                GlobalData.shared.heavyImpact()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in self?.penaltyToast = nil }
            }
        }
        GlobalData.shared.mediumImpact()
        return hit
    }

    func makeResult(intensity: CravingIntensity, completed: Bool) -> GameResult {
        GameResult(
            game: "slice",
            intensity: intensity,
            score: score,
            durationSeconds: Date().timeIntervalSince(startTime),
            maxStreak: maxCombo,
            levelReached: mode.levelValue,
            completed: completed,
            wasInfinite: mode.isInfinite
        )
    }

    private func spawnLoop() {
        spawnTask?.cancel()
        spawnTask = Task {
            while !Task.isCancelled {
                let interval = max(0.4, 1.5 - self.fraction * 1.0)
                try? await Task.sleep(nanoseconds: UInt64(interval * 1e9))
                if Task.isCancelled { return }
                await MainActor.run {
                    let level = self.mode.isInfinite ? 7 : self.mode.levelValue
                    let wave = level >= 9 ? Int.random(in: 1...3)
                             : (level >= 5 ? Int.random(in: 1...2) : 1)
                    for _ in 0..<wave { self.spawn() }
                }
            }
        }
    }

    private func tickLoop() {
        tickTask?.cancel()
        tickTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    self.elapsed = Date().timeIntervalSince(self.startTime)
                    let now = Date()
                    let before = self.targets.count
                    self.targets.removeAll { now.timeIntervalSince($0.spawnedAt) > $0.lifeSeconds }
                    if before - self.targets.count > 0 { self.combo = 0 }
                    if !self.mode.isInfinite {
                        self.remaining = max(0, self.duration - self.elapsed)
                        if self.remaining <= 0 && !self.cleared { self.clearLevel() }
                    }
                }
            }
        }
    }

    private func clearLevel() {
        cleared = true
        rewardQuote = GameQuotes.randomReward()
        GlobalData.shared.successHeavy()
        stop()
    }

    private func spawn() {
        let radius: CGFloat = .random(in: 38...52)
        let inset = radius + 12
        guard arenaSize.width > inset * 2, arenaSize.height > inset * 2 else { return }

        var chosen: CGPoint? = nil
        for _ in 0..<14 {
            let candidate = CGPoint(
                x: CGFloat.random(in: inset...(arenaSize.width - inset)),
                y: CGFloat.random(in: inset...(arenaSize.height - inset))
            )
            let clashes = targets.contains { t in
                let dx = t.position.x - candidate.x, dy = t.position.y - candidate.y
                return sqrt(dx * dx + dy * dy) < (t.radius + radius + 18)
            }
            if !clashes { chosen = candidate; break }
        }
        guard let position = chosen else { return }

        let life: Double = {
            if mode.isInfinite { return max(1.6, 2.5 - fraction * 0.9) }
            // Within a level, life stays steady across the session.
            return 2.4 - GameLevels.fraction(mode.levelValue) * 1.2
        }()

        let greenChance = 0.2 + fraction * 0.4
        let isClear30 = Double.random(in: 0...1) < greenChance
        let icon: TargetIcon = isClear30
            ? (SliceTarget.clear30Icons.randomElement() ?? .image("Clear30Logo"))
            : (SliceTarget.cravingIcons.randomElement() ?? .templateImage("CannabisSymbol"))

        targets.append(SliceTarget(
            kind: isClear30 ? .clear30 : .craving,
            icon: icon,
            position: position,
            radius: radius,
            lifeSeconds: life
        ))
    }
}

// MARK: - Target view

struct SliceTargetView: View {
    let target: SliceTarget
    @State private var appear: CGFloat = 0.6
    @State private var spin: Double = 0

    private var gradient: LinearGradient {
        target.kind == .craving ? GlobalData.shared.redGradient : GlobalData.shared.clear30Gradient
    }
    private var shadowTint: Color {
        target.kind == .craving ? GlobalData.shared.redColor2 : .clear30Green
    }

    @ViewBuilder private var iconView: some View {
        switch target.icon {
        case .sfSymbol(let n):
            Image(systemName: n).resizable().aspectRatio(contentMode: .fit).foregroundColor(.white)
        case .image(let n):
            Image(n).resizable().aspectRatio(contentMode: .fit).clipShape(Circle())
        case .templateImage(let n):
            // Rendered as a mask, tinted white → blends into the red target like the SF symbols do.
            Image(n).resizable().renderingMode(.template)
                .aspectRatio(contentMode: .fit).foregroundColor(.white)
        }
    }

    var body: some View {
        ZStack {
            Circle().fill(.white.opacity(0.25))
                .frame(width: target.radius * 2 + 14, height: target.radius * 2 + 14)
            Circle().fill(gradient)
                .frame(width: target.radius * 2, height: target.radius * 2)
                .shadow(color: shadowTint.opacity(0.5), radius: 16)
            iconView.frame(width: target.radius * 0.9, height: target.radius * 0.9)
            Circle().strokeBorder(.white.opacity(0.5), lineWidth: 2)
                .frame(width: target.radius * 2, height: target.radius * 2)
        }
        .scaleEffect(appear)
        .rotationEffect(.degrees(spin))
        .position(target.position)
        .onAppear {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) { appear = 1.0 }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { spin = 360 }
        }
    }
}

private struct SliceBurstView: View {
    let burst: SliceBurst
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 1
    private var gradient: LinearGradient {
        burst.kind == .craving ? GlobalData.shared.redGradient : GlobalData.shared.clear30Gradient
    }
    var body: some View {
        Circle().stroke(gradient, lineWidth: 4).frame(width: 100, height: 100)
            .scaleEffect(scale).opacity(opacity).position(burst.position)
            .onAppear { withAnimation(.easeOut(duration: 0.4)) { scale = 1.2; opacity = 0 } }
    }
}

private struct PenaltyFlashView: View {
    let trigger: Int
    @State private var last = 0
    @State private var opacity: Double = 0
    var body: some View {
        Rectangle().fill(GlobalData.shared.redGradient).opacity(opacity * 0.5)
            .allowsHitTesting(false).ignoresSafeArea()
            .onChange(of: trigger) { _, new in
                guard new != last else { return }
                last = new
                withAnimation(.easeOut(duration: 0.1)) { opacity = 0.5 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.easeOut(duration: 0.4)) { opacity = 0 }
                }
            }
    }
}

// MARK: - Game view

struct SliceGameView: CravingGameView {

    let intensity: CravingIntensity
    let mode: GameMode
    var onLevelComplete: (GameResult) -> Void
    var onExit: (GameResult) -> Void

    @State private var engine = SliceEngine()
    @State private var trail: [TrailPoint] = []
    @State private var bursts: [SliceBurst] = []
    @State private var confetti: Int = 0
    @State private var levelCompleteTask: Task<Void, Never>?

    init(intensity: CravingIntensity, mode: GameMode,
         onLevelComplete: @escaping (GameResult) -> Void,
         onExit: @escaping (GameResult) -> Void) {
        self.intensity = intensity
        self.mode = mode
        self.onLevelComplete = onLevelComplete
        self.onExit = onExit
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.clear30Background.ignoresSafeArea()
                arena(in: arenaSize(geo: geo))
                PenaltyFlashView(trigger: engine.penaltyFlash)

                VStack(spacing: 0) {
                    GameTopBar(
                        title: "Slice",
                        subtitle: mode.isInfinite ? "Endless · slice cravings, dodge green" : "\(GameLevels.band(mode.levelValue)) · \(Int(engine.duration))s · slice cravings",
                        mode: mode,
                        gradient: intensity.gradient,
                        onQuit: {
                            engine.stop()
                            onExit(engine.makeResult(intensity: intensity, completed: false))
                        }
                    )
                    .padding(.horizontal, GlobalData.shared.horizontalPadding)
                    .padding(.top, GlobalData.shared.headingTopPadding * 2)

                    hud
                        .padding(.horizontal, GlobalData.shared.horizontalPadding)
                        .padding(.top, GlobalData.shared.cardSpacing)

                    Spacer()

                    if let toast = engine.penaltyToast {
                        toastPill(toast)
                            .padding(.bottom, GlobalData.shared.cardSpacing * 2)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    endButton
                        .padding(.horizontal, GlobalData.shared.horizontalPadding)
                        .padding(.bottom, GlobalData.shared.cardSpacing * 2)
                }
                .animation(GlobalData.shared.springAnimation, value: engine.penaltyToast)

                if engine.cleared { LevelRewardOverlay(quote: engine.rewardQuote) }
            }
            .modifier(ConfettiPop(num: 50, radius: 240, confetti: $confetti))
            .overlay { GameIntroOverlay(text: GameQuotes.intro(for: intensity)) }
            .onAppear { engine.start(mode: mode, in: arenaSize(geo: geo)) }
            .onDisappear {
                levelCompleteTask?.cancel()
                engine.stop()
            }
            .onChange(of: engine.cleared) { _, done in
                if done {
                    confetti += 1
                    levelCompleteTask?.cancel()
                    levelCompleteTask = Task {
                        try? await Task.sleep(nanoseconds: 2_200_000_000)
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            onLevelComplete(engine.makeResult(intensity: intensity, completed: true))
                        }
                    }
                }
            }
        }
    }

    private func arenaSize(geo: GeometryProxy) -> CGSize {
        CGSize(width: geo.size.width - GlobalData.shared.horizontalPadding * 2,
               height: geo.size.height - GlobalData.shared.cardSpacing * 14)
    }

    private func arena(in size: CGSize) -> some View {
        ZStack {
            Rectangle().fill(.clear).contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            trail.append(TrailPoint(position: value.location))
                            if trail.count > 14 { trail.removeFirst() }
                            let hit = engine.registerSlice(point: value.location)
                            for t in hit {
                                bursts.append(SliceBurst(position: t.position, kind: t.kind == .craving ? .craving : .clear30))
                            }
                            cleanupBursts(); cleanupTrail()
                        }
                        .onEnded { _ in withAnimation(.easeOut(duration: 0.3)) { trail.removeAll() } }
                )
            ForEach(engine.targets) { target in
                SliceTargetView(target: target).transition(.scale.combined(with: .opacity))
            }
            ForEach(bursts) { burst in SliceBurstView(burst: burst) }
            trailLine.allowsHitTesting(false)
        }
        .padding(.horizontal, GlobalData.shared.horizontalPadding)
        .padding(.top, GlobalData.shared.cardSpacing * 6)
        .padding(.bottom, GlobalData.shared.cardSpacing * 6)
    }

    @ViewBuilder
    private var trailLine: some View {
        if trail.count > 1 {
            Canvas { ctx, _ in
                var path = Path()
                path.move(to: trail.first!.position)
                for p in trail.dropFirst() { path.addLine(to: p.position) }
                let shading = GraphicsContext.Shading.linearGradient(
                    Gradient(colors: [GlobalData.shared.redColor1.opacity(0.5), GlobalData.shared.redColor2]),
                    startPoint: trail.first!.position, endPoint: trail.last!.position)
                ctx.stroke(path, with: shading, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private func cleanupTrail() {
        let now = Date()
        trail.removeAll { now.timeIntervalSince($0.bornAt) > 0.3 }
    }
    private func cleanupBursts() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !bursts.isEmpty { bursts.removeFirst() }
        }
    }

    // MARK: - HUD

    private var hud: some View {
        HStack(spacing: GlobalData.shared.cardSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                TinyText(text: "Score").opacity(0.5)
                Heading3(text: "\(engine.score)")
            }
            Spacer()
            if !mode.isInfinite {
                VStack(alignment: .leading, spacing: 4) {
                    TinyText(text: "Time left").opacity(0.5)
                    timeBar.frame(width: 130, height: 8)
                }
                Spacer()
            }
            if engine.combo > 1 {
                VStack(alignment: .trailing, spacing: 2) {
                    TinyText(text: "Combo").opacity(0.5)
                    SmallText(text: "x\(engine.combo)")
                        .foregroundStyle(GlobalData.shared.redGradient)
                }
                .transition(.opacity)
            }
        }
    }

    private var timeBar: some View {
        GeometryReader { geo in
            let ratio = engine.duration > 0 ? max(0, engine.remaining / engine.duration) : 0
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.clear30OpacityGray)
                RoundedRectangle(cornerRadius: 4)
                    .fill(intensity.gradient)
                    .frame(width: geo.size.width * CGFloat(ratio))
                    .animation(.linear(duration: 0.1), value: engine.remaining)
            }
        }
    }

    private func toastPill(_ text: String) -> some View {
        SmallText(text: text).foregroundColor(.white)
            .padding(.vertical, GlobalData.shared.cardSpacing / 2)
            .padding(.horizontal, GlobalData.shared.cardSpacing)
            .background(Capsule().fill(GlobalData.shared.redGradient))
            .shadow(color: GlobalData.shared.redColor1.opacity(0.5), radius: 16)
    }

    private var endButton: some View {
        Button {
            GlobalData.shared.mediumImpact()
            engine.stop()
            onExit(engine.makeResult(intensity: intensity, completed: false))
        } label: {
            HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                Image(systemName: "checkmark").foregroundColor(.white)
                SmallText(text: "I'm good — end").foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .modifier(CardStyle(gradient: GlobalData.shared.clear30Gradient))
        }
        .modifier(DefaultButtonStyle(shadow: false))
    }
}
