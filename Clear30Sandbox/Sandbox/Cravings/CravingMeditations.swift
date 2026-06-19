//
//  CravingMeditations.swift
//  Clear30Sandbox
//
//  Mock meditation content for the cravings hub.
//
//  SANDBOX: in the real app these come from Supabase (`craving_resources`) via
//  MeditationResources(kind: .craving) — see CravingResources.swift. Tapping a
//  meditation there opens a player as its OWN sheet, stacked on top of the cravings
//  sheet. We mirror that here by presenting MeditationPlayerView with `.sheet`.
//

import SwiftUI

struct CravingMeditation: Identifiable {
    let id = UUID()
    let title: String
    let length: String
    let teacher: String
    let gradient: LinearGradient
}

enum CravingMeditationLibrary {
    static let all: [CravingMeditation] = [
        .init(title: "Ride the Wave",         length: "6 min",  teacher: "Dr. Fred", gradient: GlobalData.shared.meditationGradient),
        .init(title: "This Will Pass",        length: "4 min",  teacher: "Tara",     gradient: GlobalData.shared.clear30Gradient),
        .init(title: "Name the Urge",         length: "8 min",  teacher: "Dr. Fred", gradient: GlobalData.shared.claireGradient),
        .init(title: "Body Scan for Cravings", length: "11 min", teacher: "Maya",    gradient: GlobalData.shared.meditationGradient),
        .init(title: "Urge Surfing",          length: "5 min",  teacher: "Tara",     gradient: GlobalData.shared.clear30Gradient),
    ]
}

// MARK: - Player (presented as a stacked sheet)

struct MeditationPlayerView: View {

    let meditation: CravingMeditation

    @Environment(\.dismiss) private var dismiss
    @State private var playing = true
    @State private var progress: CGFloat = 0
    @State private var ticker: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    GlobalData.shared.lightImpact()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.clear30Text.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.clear30Button))
                }
                .modifier(DefaultButtonStyle(shadow: false))
                Spacer()
            }
            .padding(.horizontal, GlobalData.shared.horizontalPadding)
            .padding(.top, GlobalData.shared.cardSpacing)

            Spacer()

            RoundedRectangle(cornerRadius: 28)
                .fill(meditation.gradient)
                .frame(width: 220, height: 220)
                .overlay {
                    Image(systemName: "headphones")
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 56)
                        .foregroundColor(.white)
                }
                .shadow(color: .clear30Shadow, radius: 20, y: 10)

            Heading3(text: meditation.title)
                .padding(.top, GlobalData.shared.cardSpacing * 2)

            // Progress bar (mock playback)
            VStack(spacing: GlobalData.shared.cardSpacing / 2) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.clear30Button).frame(height: 5)
                        Capsule().fill(meditation.gradient)
                            .frame(width: geo.size.width * progress, height: 5)
                    }
                }
                .frame(height: 5)
                HStack {
                    TinyText(text: playing ? "playing…" : "paused").opacity(0.5)
                    Spacer()
                }
            }
            .padding(.horizontal, GlobalData.shared.horizontalPadding)
            .padding(.top, GlobalData.shared.cardSpacing * 2)

            Spacer()

            Button {
                GlobalData.shared.mediumImpact()
                playing.toggle()
            } label: {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(GlobalData.shared.meditationGradient))
                    .shadow(color: .meditation1.opacity(0.4), radius: 14, y: 6)
            }
            .modifier(DefaultButtonStyle(shadow: false))
            .padding(.bottom, GlobalData.shared.cardSpacing * 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear30Background.ignoresSafeArea())
        .onAppear { startTicker() }
        .onDisappear { ticker?.cancel() }
        .onChange(of: playing) { _, isPlaying in
            if isPlaying { startTicker() } else { ticker?.cancel() }
        }
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task {
            while !Task.isCancelled && progress < 1 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    withAnimation(.linear(duration: 0.1)) { progress = min(1, progress + 0.006) }
                }
            }
        }
    }
}
