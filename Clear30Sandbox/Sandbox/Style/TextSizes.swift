//
//  TextSizes.swift
//  Clear30Sandbox
//
//  Lifted from the real Clear30 app. Uses Font.custom("Lexend", ...) —
//  silently falls back to the system font in the sandbox if Lexend isn't
//  bundled, which is fine for layout work.
//

import SwiftUI

struct Heading2: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.custom("Lexend", size: 25).weight(.medium))
            .transition(GlobalData.shared.defaultTransition)
    }
}

struct Heading3: View {
    var text: String
    var transition: AnyTransition = GlobalData.shared.defaultTransition
    var body: some View {
        Text(text)
            .font(.custom("Lexend", size: 22).weight(.medium))
            .transition(transition)
    }
}

struct DefaultText: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.custom("Lexend", size: 19).weight(.regular))
            .transition(GlobalData.shared.defaultTransition)
    }
}

struct SmallText: View {
    var text: String
    var transition: AnyTransition = GlobalData.shared.defaultTransition
    var body: some View {
        Text(text)
            .font(.custom("Lexend", size: 15.5).weight(.regular))
            .transition(transition)
    }
}

struct TinyText: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.custom("Lexend", size: 14).weight(.regular))
            .transition(GlobalData.shared.defaultTransition)
    }
}

struct MiniText: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.custom("Lexend", size: 10).weight(.regular))
            .transition(GlobalData.shared.defaultTransition)
    }
}
