//
//  ContentView.swift
//  Drift
//
//  Root navigation: Splash (with onContinue) or Home Dashboard. No tabs; Splash transitions to Home.
//

import SwiftUI

struct ContentView: View {
    @State private var showHome: Bool = false

    var body: some View {
        if showHome {
            HomeDashboardView()
        } else {
            SplashView(onContinue: { showHome = true })
        }
    }
}
