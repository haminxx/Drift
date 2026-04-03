//
//  WelcomeView.swift
//  Drift
//
//  Entry screen: navy shader-style background, fade-in title, subtitle, Start.
//

import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            NavyShaderLinesBackground()

            VStack(spacing: 18) {
                Spacer()

                Text(String(localized: "welcome.title"))
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.75),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(titleOpacity)

                Text(String(localized: "welcome.subtitle"))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.62))
                    .padding(.horizontal, 36)
                    .opacity(subtitleOpacity)

                Button {
                    onContinue()
                } label: {
                    Text(String(localized: "welcome.start"))
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: 260)
                        .padding(.vertical, 16)
                        .background {
                            Capsule()
                                .fill(Color.white.opacity(0.16))
                                .overlay {
                                    Capsule()
                                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                                }
                        }
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.top, 28)
                .opacity(buttonOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                titleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.9).delay(0.35)) {
                subtitleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.7)) {
                buttonOpacity = 1
            }
        }
    }
}
