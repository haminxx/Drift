//
//  ContentView.swift
//  Drift
//
//  Splash then four-tab main shell (Tide-style Home, Flow analytics, Lock hub, Insights).
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
                SplashView(onContinue: {
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
                .id("splash")
            }
        }
    }
}
