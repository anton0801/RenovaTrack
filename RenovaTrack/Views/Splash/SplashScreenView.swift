import SwiftUI

struct SplashScreenView: View {
    @State private var gridOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var logoGlow: CGFloat = 10
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var particles: [SplashParticle] = SplashParticle.generate(count: 35)
    @State private var particlesVisible = false
    @State private var ringScale: CGFloat = 0.1
    @State private var ringOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "1A1A2E").ignoresSafeArea()

            // Blueprint grid
            BlueprintGridView()
                .opacity(gridOpacity)

            // Outer ring pulse
            Circle()
                .stroke(Color(hex: "E07B54").opacity(0.15), lineWidth: 1)
                .frame(width: 200, height: 200)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            Circle()
                .stroke(Color(hex: "C9A84C").opacity(0.1), lineWidth: 1)
                .frame(width: 280, height: 280)
                .scaleEffect(ringScale * 0.8)
                .opacity(ringOpacity * 0.7)

            // Particles
            ForEach(particles) { p in
                Circle()
                    .fill(p.isGold ? Color(hex: "C9A84C").opacity(p.opacity) : Color(hex: "E07B54").opacity(p.opacity * 0.6))
                    .frame(width: p.size, height: p.size)
                    .offset(x: p.x, y: p.y)
                    .scaleEffect(particlesVisible ? 1 : 0)
                    .animation(
                        .spring(response: 0.7, dampingFraction: 0.5).delay(p.delay),
                        value: particlesVisible
                    )
            }

            VStack(spacing: 16) {
                // Logo mark
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "E07B54"), Color(hex: "C9A84C")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                        .shadow(color: Color(hex: "E07B54").opacity(0.7), radius: logoGlow)
                        .shadow(color: Color(hex: "C9A84C").opacity(0.3), radius: logoGlow * 2)

                    Image(systemName: "house.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)

                    // Wrench badge
                    ZStack {
                        Circle()
                            .fill(Color(hex: "1A1A2E"))
                            .frame(width: 28, height: 28)
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "C9A84C"))
                    }
                    .offset(x: 32, y: 32)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 6) {
                    Text("RenovaTrack")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "F5EFE6"))
                        .tracking(1)

                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(Color(hex: "C9A84C").opacity(0.5))
                            .frame(width: 30, height: 1)
                        Text("YOUR RENOVATION MANAGER")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: "C9A84C"))
                            .tracking(2)
                        Rectangle()
                            .fill(Color(hex: "C9A84C").opacity(0.5))
                            .frame(width: 30, height: 1)
                    }
                    .opacity(taglineOpacity)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
        }
        .onAppear { animateSplash() }
    }

    func animateSplash() {
        withAnimation(.easeIn(duration: 1.0)) {
            gridOpacity = 0.12
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.3)) {
            logoScale = 1.0
            logoOpacity = 1.0
            ringScale = 1.0
            ringOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.8)) {
            logoGlow = 25
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            particlesVisible = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.9)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.4).delay(1.2)) {
            taglineOpacity = 1.0
        }
    }
}

// MARK: - Blueprint Grid
struct BlueprintGridView: View {
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 26
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            ctx.stroke(path, with: .color(Color(hex: "C9A84C")), lineWidth: 0.35)

            // Crosshairs at center
            let cx = size.width / 2
            let cy = size.height / 2
            var crossPath = Path()
            crossPath.move(to: CGPoint(x: cx - 20, y: cy))
            crossPath.addLine(to: CGPoint(x: cx + 20, y: cy))
            crossPath.move(to: CGPoint(x: cx, y: cy - 20))
            crossPath.addLine(to: CGPoint(x: cx, y: cy + 20))
            ctx.stroke(crossPath, with: .color(Color(hex: "E07B54").opacity(0.3)), lineWidth: 0.8)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Particle Model
struct SplashParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var delay: Double
    var isGold: Bool

    static func generate(count: Int) -> [SplashParticle] {
        (0..<count).map { _ in
            SplashParticle(
                x: CGFloat.random(in: -200...200),
                y: CGFloat.random(in: -320...320),
                size: CGFloat.random(in: 2...7),
                opacity: Double.random(in: 0.25...0.75),
                delay: Double.random(in: 0...0.6),
                isGold: Bool.random()
            )
        }
    }
}

#Preview {
    SplashScreenView()
}
