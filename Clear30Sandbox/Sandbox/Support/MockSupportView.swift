//
//  MockSupportView.swift
//  Clear30Sandbox
//
//  Recreates the layout of the real app's Support tab — Cravings hero +
//  Sleep hero + Claire compact — so the cravings flow can be tested in
//  visual context. Buttons other than Cravings are no-op.
//

import SwiftUI

struct MockSupportView: View {

    @State private var showCravings: Bool = false
    @State private var showStub: StubKind? = nil

    enum StubKind: String, Identifiable {
        case sleep, claire
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing * 2) {
                    header
                    immediateSupport
                    humanSupportPreview
                }
                .padding(.horizontal, GlobalData.shared.horizontalPadding)
                .padding(.top, GlobalData.shared.headingTopPadding)
                .padding(.bottom, GlobalData.shared.cardSpacing * 4)
            }
            .background(Color.clear30Background.ignoresSafeArea())
        }
        .sheet(isPresented: $showCravings) {
            CravingInterventionFlow(
                onDismiss: { showCravings = false }
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $showStub) { stub in
            stubSheet(stub)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: GlobalData.shared.cardSpacing / 2) {
            Heading2(text: "Support")
            SmallText(text: "Help when you need it most.")
                .opacity(0.5)
        }
    }

    // MARK: - Immediate support

    private var immediateSupport: some View {
        VStack(alignment: .leading, spacing: 0) {
            SmallText(text: "Immediate support")
                .padding(.bottom, GlobalData.shared.cardSpacing)
                .opacity(0.5)

            VStack(spacing: GlobalData.shared.cardSpacing) {
                cravingHero
                sleepHero
                claireCompact
            }
        }
    }

    private var cravingHero: some View {
        Button {
            GlobalData.shared.mediumImpact()
            showCravings = true
        } label: {
            heroRow(
                title: "Cravings",
                subtitle: "Help is here",
                sfSymbol: "flame.fill",
                gradient: GlobalData.shared.redGradient,
                iconGradient: GlobalData.shared.redGradient
            )
        }
        .modifier(DefaultButtonStyle(shadow: false))
    }

    private var sleepHero: some View {
        Button {
            GlobalData.shared.mediumImpact()
            showStub = .sleep
        } label: {
            heroRow(
                title: "Sleep",
                subtitle: "Wind down",
                sfSymbol: "moon.fill",
                gradient: GlobalData.shared.sleepGradient,
                iconGradient: GlobalData.shared.sleepGradient
            )
        }
        .modifier(DefaultButtonStyle(shadow: false))
    }

    private var claireCompact: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                Image(systemName: "sparkles")
                SmallText(text: "Claire")
            }
            .padding(.bottom, GlobalData.shared.cardSpacing / 2)

            TinyText(text: "Chat or tap how you're feeling")
                .opacity(0.5)
                .padding(.bottom, GlobalData.shared.cardSpacing)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                    Button {
                        GlobalData.shared.mediumImpact()
                        showStub = .claire
                    } label: {
                        HStack(spacing: GlobalData.shared.cardSpacing / 2) {
                            Image(systemName: "text.bubble.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 17)
                                .foregroundStyle(GlobalData.shared.claireGradient)
                            TinyText(text: "Chat")
                                .foregroundStyle(GlobalData.shared.claireGradient)
                        }
                        .frame(height: GlobalData.shared.cardSpacing * 3)
                        .padding(.horizontal, GlobalData.shared.cardSpacing)
                        .background(
                            RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 1.5)
                                .fill(.white)
                        )
                    }
                    .modifier(DefaultButtonStyle(shadow: false))

                    ForEach(["🤩", "🤔", "🥺", "🤢", "🫥", "😡", "🫨", "🫠"], id: \.self) { emoji in
                        Button {
                            GlobalData.shared.lightImpact()
                            showStub = .claire
                        } label: {
                            Heading2(text: emoji)
                                .frame(
                                    width: GlobalData.shared.cardSpacing * 3,
                                    height: GlobalData.shared.cardSpacing * 3
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: GlobalData.shared.cornerRadius / 1.5)
                                        .fill(.white.opacity(0.5))
                                )
                        }
                        .modifier(DefaultButtonStyle(shadow: false))
                    }
                }
            }
        }
        .modifier(CardStyle(gradient: GlobalData.shared.claireGradient))
    }

    // MARK: - Human support preview (visual only)

    private var humanSupportPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            SmallText(text: "Human support")
                .padding(.bottom, GlobalData.shared.cardSpacing)
                .opacity(0.5)

            VStack(spacing: GlobalData.shared.cardSpacing) {
                humanRow(name: "Dr. Fred", role: "Addiction specialist", icon: "stethoscope", gradient: GlobalData.shared.meditationGradient)
                humanRow(name: "Gerad", role: "Accountability buddy", icon: "person.fill", gradient: LinearGradient(colors: [.meditation1, Color(hex: "#448eee")], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        }
    }

    private func humanRow(name: String, role: String, icon: String, gradient: LinearGradient) -> some View {
        HStack(spacing: GlobalData.shared.cardSpacing) {
            ZStack {
                Circle().fill(.white.opacity(0.25)).frame(width: 56, height: 56)
                Circle().fill(.white).frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22)
                            .foregroundStyle(gradient)
                    }
            }
            VStack(alignment: .leading, spacing: 2) {
                SmallText(text: name)
                TinyText(text: role).opacity(0.75)
            }
            Spacer()
        }
        .modifier(CardStyle(gradient: gradient))
    }

    // MARK: - Shared row visual (hero)

    private func heroRow(title: String, subtitle: String, sfSymbol: String, gradient: LinearGradient, iconGradient: LinearGradient) -> some View {
        HStack(spacing: GlobalData.shared.cardSpacing) {
            ZStack {
                Circle().fill(.white.opacity(0.25)).frame(width: 56, height: 56)
                Circle().fill(.white).frame(width: 48, height: 48)
                    .shadow(color: .white.opacity(0.5), radius: 5)
                    .shadow(color: .white.opacity(0.25), radius: 11)
                    .overlay {
                        Image(systemName: sfSymbol)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22)
                            .foregroundStyle(iconGradient)
                    }
            }
            VStack(alignment: .leading, spacing: 2) {
                SmallText(text: title)
                TinyText(text: subtitle).opacity(0.75)
            }
            Spacer()
        }
        .modifier(CardStyle(gradient: gradient))
    }

    // MARK: - Stub sheets

    @ViewBuilder
    private func stubSheet(_ kind: StubKind) -> some View {
        VStack(spacing: GlobalData.shared.cardSpacing) {
            Spacer()
            Heading3(text: kind == .sleep ? "Sleep (stubbed)" : "Claire (stubbed)")
            SmallText(text: "Only the Cravings flow is wired up in the sandbox.")
                .opacity(0.5)
                .multilineTextAlignment(.center)
                .padding(.horizontal, GlobalData.shared.horizontalPadding)
            Spacer()
            Button {
                showStub = nil
            } label: {
                SmallText(text: "Close").foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .modifier(CardStyle(gradient: GlobalData.shared.clear30Gradient))
            }
            .modifier(DefaultButtonStyle(shadow: false))
            .padding(.horizontal, GlobalData.shared.horizontalPadding)
            .padding(.bottom, GlobalData.shared.cardSpacing * 2)
        }
    }
}
