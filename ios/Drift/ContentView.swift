//
//  ContentView.swift
//  Drift
//
//  Welcome then three-tab shell (Flow, Lock, Insight).
//

import SwiftUI

struct ContentView: View {
    @State private var showMain: Bool = false

    var body: some View {
        ZStack {
            if showMain {
                MainTabView()
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity
                        )
                    )
                    .id("main")
            } else {
                WelcomeView(onContinue: {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                        showMain = true
                    }
                })
                .transition(
                    .asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .move(edge: .leading))
                    )
                )
                .id("welcome")
            }
        }
    }
}
