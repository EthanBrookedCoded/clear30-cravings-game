//
//  LevelPickerSheet.swift
//  Clear30Sandbox
//
//  Shared in-game chrome reused by all three games:
//   • LevelChip / GameQuitButton — composable top-bar pieces (no game titles/bands)
//   • GameIntroView     — pre-game "get ready" intro every game shows before starting
//   • ScoreBadge        — the score pill used by the scored games
//   • LevelPickerSheet  — tapping the level chip opens this to jump levels
//   • LevelRewardOverlay — confetti card shown on level completion
//

import SwiftUI

// MARK: - In-game chrome pieces
//
// Game titles + difficulty bands were removed — the games are self-evident once open.
// Each game composes its own top bar from these pieces (the level chip + quit X).

struct LevelChip: View {
    let mode: GameMode
    var onSelect: (() -> Void)? = nil

    var body: some View {
        if let onSelect {
            Button {
                GlobalData.shared.lightImpact()
                onSelect()
            } label: { chip(selectable: true) }
            .modifier(DefaultButtonStyle(shadow: false))
        } else {
            chip(selectable: false)
        }
    }

    private func chip(selectable: Bool) -> some View {
        HStack(spacing: GlobalData.shared.cardSpacing / 4) {
            Image(systemName: mode.isInfinite ? "infinity" : "flag.fill")
            TinyText(text: mode.isInfinite ? "Endless" : "Lvl \(mode.levelValue)")
            if selectable {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .opacity(0.5)
            }
        }
        .foregroundColor(.clear30Text)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.clear30Button))
    }
}

struct GameQuitButton: View {
    var onQuit: () -> Void

    var body: some View {
        Button {
            GlobalData.shared.lightImpact()
            onQuit()
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

// MARK: - Score badge (used by scored games)

struct ScoreBadge: View {
    let score: Int
    var gradient: LinearGradient = GlobalData.shared.clear30Gradient

    var body: some View {
        HStack(spacing: GlobalData.shared.cardSpacing / 2) {
            ZStack {
                Circle().fill(gradient).frame(width: 26, height: 26)
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            Text("\(score)")
                .font(.custom("Lexend", size: 20).weight(.semibold))
                .foregroundColor(.clear30Text)
                .contentTransition(.numericText())
                .animation(.snappy, value: score)
        }
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.clear30Button))
        .overlay(Capsule().strokeBorder(gradient, lineWidth: 1).opacity(0.2))
    }
}

// MARK: - Pre-game intro ("get ready")

struct GameIntroLine: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

struct GameIntroView: View {

    let title: String
    let symbol: String
    let blurb: String
    let lines: [GameIntroLine]
    let gradient: LinearGradient
    var onStart: () -> Void

    var body: some View {
        ZStack {
            Color.clear30Background.ignoresSafeArea()

            VStack(spacing: GlobalData.shared.cardSpacing * 1.5) {
                Spacer()

                ZStack {
                    Circle().fill(.white.opacity(0.25)).frame(width: 104, height: 104)
                    Circle().fill(gradient).frame(width: 84, height: 84)
                        .shadow(color: .clear30Shadow, radius: 16, y: 6)
                    Image(systemName: symbol)
                        .resizable().aspectRatio(contentMode: .fit).frame(width: 38)
                        .foregroundColor(.white)
                }

                VStack(spacing: GlobalData.shared.cardSpacing / 2) {
                    Heading2(text: title)
                    SmallText(text: blurb).opacity(0.5).multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing) {
                    ForEach(lines) { line in
                        HStack(spacing: GlobalData.shared.cardSpacing) {
                            ZStack {
                                Circle().fill(Color.clear30Button).frame(width: 38, height: 38)
                                Image(systemName: line.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(gradient)
                            }
                            SmallText(text: line.text)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.vertical, GlobalData.shared.cardSpacing)
                .padding(.horizontal, GlobalData.shared.cardSpacing)

                Spacer()

                Button {
                    GlobalData.shared.mediumImpact()
                    onStart()
                } label: {
                    SmallText(text: "Start").foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .modifier(CardStyle(gradient: gradient))
                }
                .modifier(DefaultButtonStyle(shadow: false))
            }
            .padding(.horizontal, GlobalData.shared.horizontalPadding)
            .padding(.top, GlobalData.shared.headingTopPadding * 3)
            .padding(.bottom, GlobalData.shared.cardSpacing * 3)
        }
    }
}

// MARK: - In-game level picker (tapping the level chip)

struct LevelPickerSheet: View {

    let gameTitle: String
    let gameName: String
    let current: Int
    let gradient: LinearGradient
    var onPick: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    private var unlocked: Int { CravingStore.maxUnlockedLevel(for: gameName) }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Heading3(text: "\(gameTitle) levels")
                Spacer()
                TinyText(text: "\(unlocked) / \(CravingStore.maxLevel)").opacity(0.5)
            }
            .padding(.bottom, GlobalData.shared.cardSpacing * 1.5)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(1...CravingStore.maxLevel, id: \.self) { lvl in
                    cell(lvl)
                }
            }

            Spacer()
        }
        .padding(.horizontal, GlobalData.shared.horizontalPadding)
        .padding(.top, GlobalData.shared.headingTopPadding * 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.clear30Background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func cell(_ lvl: Int) -> some View {
        let isUnlocked = lvl <= unlocked
        let isCurrent = lvl == current
        return Button {
            guard isUnlocked else { return }
            GlobalData.shared.lightImpact()
            onPick(lvl)
            dismiss()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(isCurrent ? AnyShapeStyle(gradient) : AnyShapeStyle(Color.clear30Button))
                    .overlay {
                        if !isCurrent {
                            RoundedRectangle(cornerRadius: 15)
                                .strokeBorder(Color.clear30OpacityGray, lineWidth: 1)
                        }
                    }
                if isUnlocked {
                    Text("\(lvl)")
                        .font(.custom("Lexend", size: 17).weight(.semibold))
                        .foregroundColor(isCurrent ? .white : .clear30Text)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.clear30Text.opacity(0.3))
                }
            }
            .frame(height: 56)
            .opacity(isUnlocked ? 1 : 0.5)
        }
        .modifier(DefaultButtonStyle(shadow: false, transition: false))
        .disabled(!isUnlocked)
    }
}

// MARK: - Per-level reward overlay (confetti + quote)

struct LevelRewardOverlay: View {

    let quote: String

    var body: some View {
        VStack(spacing: GlobalData.shared.cardSpacing) {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64)
                .foregroundStyle(GlobalData.shared.clear30Gradient)
            Heading3(text: quote)
                .multilineTextAlignment(.center)
        }
        .padding(GlobalData.shared.cardSpacing * 2)
        .frame(maxWidth: .infinity)
        .modifier(CardStyle(
            color: .clear30Button,
            outlineGradient: GlobalData.shared.clear30Gradient,
            outlineWidth: 1.5,
            outlineOpacity: 0.5
        ))
        .padding(.horizontal, GlobalData.shared.horizontalPadding)
        .transition(.scale.combined(with: .opacity))
    }
}
