//
//  HomeSereneView.swift
//  Drift
//
//  Tide-inspired serene home: ocean-like gradient, greeting, week strip, glass "Now for you" cards.
//

import SwiftUI

struct HomeSereneView: View {
    private let weekLetters = ["S", "M", "T", "W", "T", "F", "S"]
    @State private var headerAppeared = false
    @State private var cardsAppeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                sereneBackground
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        headerBlock
                            .opacity(headerAppeared ? 1 : 0)
                            .offset(y: headerAppeared ? 0 : 16)
                        nowForYouSection
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 20)
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, geo.safeAreaInsets.top + 8)
                    .frame(maxWidth: min(geo.size.width, 480))
                    .frame(maxWidth: .infinity)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.05)) {
                    headerAppeared = true
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.15)) {
                    cardsAppeared = true
                }
            }
        }
    }

    private var sereneBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.58, blue: 0.72),
                    Color(red: 0.32, green: 0.42, blue: 0.55),
                    Color(red: 0.18, green: 0.24, blue: 0.34),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.white.opacity(0.12), Color.clear],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 380
            )
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(timeGreeting)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            HStack(spacing: 0) {
                ForEach(0 ..< 7, id: \.self) { i in
                    let sunIdx = Calendar.current.component(.weekday, from: Date()) - 1
                    Text(weekLetters[i])
                        .font(.subheadline)
                        .fontWeight(i == sunIdx ? .bold : .regular)
                        .foregroundStyle(.white.opacity(i == sunIdx ? 1 : 0.45))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)
        }
    }

    /// Week starts Sunday: weekday 1 = Sunday = index 0.
    private var timeGreeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5 ..< 12: return String(localized: "home.greeting.morning")
        case 12 ..< 17: return String(localized: "home.greeting.day")
        case 17 ..< 22: return String(localized: "home.greeting.evening")
        default: return String(localized: "home.greeting.night")
        }
    }

    private var nowForYouSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Text("✨")
                Text(String(localized: "home.now_for_you"))
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white.opacity(0.95))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    sereneActionCard(icon: "scope", title: "home.action.focus")
                    sereneActionCard(icon: "cup.and.saucer.fill", title: "home.action.break")
                    sereneActionCard(icon: "wind", title: "home.action.breathe")
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func sereneActionCard(icon: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
            Text(String(localized: LocalizedStringResource(stringLiteral: title)))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(20)
        .frame(width: 132, height: 118, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                }
        }
    }
}
