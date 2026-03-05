import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @State private var appeared = false

    private let totalPages = 4

    // Per-page config
    private let configs: [PageConfig] = [
        PageConfig(
            icon: "hammer.fill",
            tag: "PLAN",
            title: "Map Your\nRenovation",
            subtitle: "Break any project into stages. From demolition to the final coat of paint — nothing falls through the cracks.",
            accentHex: "E07B54",
            glowHex: "E07B54",
            bgSymbol: "house.fill"
        ),
        PageConfig(
            icon: "dollarsign.circle.fill",
            tag: "BUDGET",
            title: "Control\nEvery Dollar",
            subtitle: "Track planned vs. actual spend by category. See exactly where your money goes, in real time.",
            accentHex: "C9A84C",
            glowHex: "C9A84C",
            bgSymbol: "banknote.fill"
        ),
        PageConfig(
            icon: "camera.fill",
            tag: "CAPTURE",
            title: "Before & After,\nBeautifully Logged",
            subtitle: "Shoot photos at every stage. Watch your space transform — and have proof of every decision made.",
            accentHex: "4CAF84",
            glowHex: "4CAF84",
            bgSymbol: "photo.stack.fill"
        ),
        PageConfig(
            icon: "calendar.badge.clock",
            tag: "SCHEDULE",
            title: "Never Miss\na Deadline",
            subtitle: "Schedule deliveries, contractor visits, and inspections. Smart reminders keep your whole team on track.",
            accentHex: "6B9EFF",
            glowHex: "6B9EFF",
            bgSymbol: "clock.fill"
        )
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Background ────────────────────────────────────────
                Color(hex: "0F0F1A").ignoresSafeArea()

                // Animated mesh background
                AnimatedMeshBG(accentHex: configs[currentPage].accentHex)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.7), value: currentPage)

                // ── Content ───────────────────────────────────────────
                VStack(spacing: 0) {

                    // Top bar
                    HStack {
                        // Logo mark
                        HStack(spacing: 7) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: configs[currentPage].accentHex).opacity(0.2))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "house.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: configs[currentPage].accentHex))
                            }
                            Text("RenovaTrack")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        if currentPage < totalPages - 1 {
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    hasSeenOnboarding = true
                                }
                            } label: {
                                Text("Skip")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.35))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(.white.opacity(0.06))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // ── Illustration area ─────────────────────────────
                    ZStack {
                        ForEach(0..<totalPages, id: \.self) { i in
                            PageIllustration(config: configs[i], index: i, currentPage: currentPage)
                                .frame(maxWidth: .infinity)
                                .offset(x: CGFloat(i - currentPage) * geo.size.width + dragOffset)
                                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: currentPage)
                        }
                    }
                    .frame(height: geo.size.height * 0.46)
                    .clipped()

                    // ── Text + controls ───────────────────────────────
                    VStack(spacing: 0) {

                        // Page indicator dots
                        HStack(spacing: 6) {
                            ForEach(0..<totalPages, id: \.self) { i in
                                Capsule()
                                    .fill(i == currentPage
                                          ? Color(hex: configs[currentPage].accentHex)
                                          : .white.opacity(0.15))
                                    .frame(width: i == currentPage ? 24 : 6, height: 6)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                            }
                        }
                        .padding(.bottom, 28)

                        // Tag
                        Text(configs[currentPage].tag)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: configs[currentPage].accentHex))
                            .tracking(3)
                            .padding(.bottom, 10)
                            .id("tag-\(currentPage)")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)

                        // Title
                        Text(configs[currentPage].title)
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .id("title-\(currentPage)")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.04), value: currentPage)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 14)

                        // Subtitle
                        Text(configs[currentPage].subtitle)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .id("sub-\(currentPage)")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.08), value: currentPage)
                            .padding(.horizontal, 32)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)

                        // CTA button
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                                if currentPage < totalPages - 1 {
                                    currentPage += 1
                                } else {
                                    hasSeenOnboarding = true
                                }
                            }
                        } label: {
                            ZStack {
                                // Glow
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(hex: configs[currentPage].accentHex))
                                    .blur(radius: 16)
                                    .opacity(0.4)
                                    .padding(.horizontal, 16)

                                HStack(spacing: 10) {
                                    Text(currentPage < totalPages - 1 ? "Continue" : "Let's Start")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: "0F0F1A"))

                                    Image(systemName: currentPage < totalPages - 1 ? "arrow.right" : "checkmark")
                                        .font(.system(size: 15, weight: .black))
                                        .foregroundColor(Color(hex: "0F0F1A"))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(Color(hex: configs[currentPage].accentHex))
                                .cornerRadius(20)
                            }
                        }
                        .buttonStyle(SpringButtonStyle())
                        .padding(.horizontal, 24)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom, 16) + 8)
                    }
                    .frame(height: geo.size.height * 0.54)
                    .padding(.top, 24)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { val in
                        dragOffset = val.translation.width * 0.4
                    }
                    .onEnded { val in
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                            if val.translation.width < -60, currentPage < totalPages - 1 {
                                currentPage += 1
                            } else if val.translation.width > 60, currentPage > 0 {
                                currentPage -= 1
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear { appeared = true }
    }
}

// MARK: - Config
struct PageConfig {
    let icon: String
    let tag: String
    let title: String
    let subtitle: String
    let accentHex: String
    let glowHex: String
    let bgSymbol: String
}

// MARK: - Animated Mesh Background
struct AnimatedMeshBG: View {
    let accentHex: String
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            // Base
            Color(hex: "0F0F1A")

            // Top glow orb
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: accentHex).opacity(0.28), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )
                .frame(width: 440, height: 380)
                .offset(x: 60, y: -180)
                .blur(radius: 20)

            // Bottom accent orb
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: accentHex).opacity(0.12), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 300)
                .offset(x: -80, y: 280)
                .blur(radius: 30)

            // Fine grid lines
            Canvas { ctx, size in
                let spacing: CGFloat = 36
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
                ctx.stroke(path, with: .color(.white.opacity(0.035)), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - Page Illustration
struct PageIllustration: View {
    let config: PageConfig
    let index: Int
    let currentPage: Int

    var isActive: Bool { index == currentPage }

    @State private var floatOffset: CGFloat = 0
    @State private var innerAnimate = false

    var body: some View {
        ZStack {
            // Large ghost symbol
            Image(systemName: config.bgSymbol)
                .font(.system(size: 180, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: config.accentHex).opacity(0.07),
                            Color(hex: config.accentHex).opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .offset(x: 50, y: 20)
                .blur(radius: 2)

            // Central card
            VStack(spacing: 0) {
                Spacer()
                cardContent
                    .scaleEffect(isActive ? 1 : 0.88)
                    .opacity(isActive ? 1 : 0.4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isActive)
                    .offset(y: isActive ? floatOffset : 0)
                Spacer()
            }
        }
        .onAppear {
            if isActive { startFloat() }
        }
        .onChange(of: isActive) { active in
            if active {
                innerAnimate = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { innerAnimate = true }
                    startFloat()
                }
            } else {
                innerAnimate = false
            }
        }
    }

    func startFloat() {
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            floatOffset = -10
        }
    }

    @ViewBuilder
    var cardContent: some View {
        switch index {
        case 0: StagesCard(accent: config.accentHex, animate: innerAnimate)
        case 1: BudgetCard(accent: config.accentHex, animate: innerAnimate)
        case 2: PhotoCard(accent: config.accentHex, animate: innerAnimate)
        default: CalendarCard(accent: config.accentHex, animate: innerAnimate)
        }
    }
}

// MARK: - Card 1: Stages

struct StagesCard: View {
    let accent: String
    let animate: Bool

    let stages = [
        ("Demolition", true),
        ("Rough-in & Framing", true),
        ("Electrical & Plumbing", false),
        ("Finishing & Paint", false),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Card header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Kitchen Reno")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("4 stages · 2 done")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                ZStack {
                    Circle()
                        .trim(from: 0, to: animate ? 0.5 : 0)
                        .stroke(Color(hex: accent), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.2, dampingFraction: 0.7).delay(0.2), value: animate)
                    Circle()
                        .stroke(.white.opacity(0.08), lineWidth: 3)
                        .frame(width: 36, height: 36)
                    Text("50%")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider().background(.white.opacity(0.07))

            // Stage rows
            VStack(spacing: 0) {
                ForEach(Array(stages.enumerated()), id: \.0) { i, stage in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(stage.1 ? Color(hex: accent) : .white.opacity(0.07))
                                .frame(width: 26, height: 26)
                            if stage.1 {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white)
                            }
                        }
                        .scaleEffect(animate ? 1 : 0.6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(i) * 0.08), value: animate)

                        Text(stage.0)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(stage.1 ? .white.opacity(0.45) : .white.opacity(0.85))
                            .strikethrough(stage.1, color: .white.opacity(0.3))
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)

                    if i < stages.count - 1 {
                        Divider().background(.white.opacity(0.05)).padding(.leading, 56)
                    }
                }
            }
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.09), lineWidth: 1))
        )
        .padding(.horizontal, 28)
    }
}

// MARK: - Card 2: Budget

struct BudgetCard: View {
    let accent: String
    let animate: Bool

    let items: [(String, Double, Double)] = [
        ("Materials",  8400,  6200),
        ("Labor",     12000,  9800),
        ("Permits",    1200,  1200),
        ("Furniture",  5000,  1400),
    ]

    var totalBudget: Double { items.reduce(0) { $0 + $1.1 } }
    var totalSpent: Double { items.reduce(0) { $0 + $1.2 } }

    var body: some View {
        VStack(spacing: 0) {
            // Big numbers
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("TOTAL BUDGET")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(2)
                    Text("$26,600")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("SPENT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(2)
                    Text("$18,600")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: accent))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            // Overall bar
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.07)).frame(height: 6)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(hex: accent), Color(hex: accent).opacity(0.6)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: animate ? g.size.width * 0.7 : 0, height: 6)
                        .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.15), value: animate)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 18)
            .padding(.bottom, 16)

            Divider().background(.white.opacity(0.07))

            // Category rows
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.0) { i, item in
                    HStack(spacing: 10) {
                        Text(item.0)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(width: 80, alignment: .leading)

                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.07)).frame(height: 5)
                                Capsule()
                                    .fill(Color(hex: accent).opacity(0.7))
                                    .frame(width: animate ? g.size.width * (item.2 / item.1) : 0, height: 5)
                                    .animation(.spring(response: 0.9, dampingFraction: 0.7).delay(Double(i) * 0.09 + 0.2), value: animate)
                            }
                        }.frame(height: 5)

                        Text("$\(Int(item.2) / 1000)k")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(width: 30, alignment: .trailing)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                }
            }
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.09), lineWidth: 1))
        )
        .padding(.horizontal, 28)
    }
}

// MARK: - Card 3: Photos

struct PhotoCard: View {
    let accent: String
    let animate: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Label row
            HStack {
                Label("Photo Log", systemImage: "camera.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("12 photos")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Before / After pair
            HStack(spacing: 10) {
                // Before
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "2A2030"), Color(hex: "1A1828")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.07), lineWidth: 1)
                        )
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 36, weight: .thin))
                                .foregroundColor(.white.opacity(0.12))
                        )

                    Text("BEFORE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1.5)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.45))
                        .cornerRadius(6)
                        .padding(8)
                }
                .scaleEffect(animate ? 1 : 0.85)
                .animation(.spring(response: 0.55, dampingFraction: 0.7), value: animate)

                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.25))
                    .opacity(animate ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.35), value: animate)

                // After
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: accent).opacity(0.25), Color(hex: "1A1828")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: accent).opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Image(systemName: "photo.fill")
                                .font(.system(size: 36, weight: .thin))
                                .foregroundColor(Color(hex: accent).opacity(0.35))
                        )

                    Label("AFTER", systemImage: "sparkles")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Color(hex: accent))
                        .tracking(1.5)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: accent).opacity(0.18))
                        .cornerRadius(6)
                        .padding(8)
                }
                .scaleEffect(animate ? 1 : 0.85)
                .animation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.12), value: animate)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.09), lineWidth: 1))
        )
        .padding(.horizontal, 28)
    }
}

// MARK: - Card 4: Calendar

struct CalendarCard: View {
    let accent: String
    let animate: Bool

    // (day, dot color hex, isSelected)
    let grid: [(Int, String?, Bool)] = [
        (1, nil, false), (2, "6B9EFF", false), (3, nil, false), (4, nil, false), (5, "4CAF84", false), (6, nil, false), (7, nil, false),
        (8, "E05454", false), (9, nil, false), (10, "6B9EFF", false), (11, nil, false), (12, nil, false), (13, nil, true), (14, nil, false),
        (15, nil, false), (16, "C9A84C", false), (17, nil, false), (18, nil, false), (19, "4CAF84", false), (20, nil, false), (21, nil, false),
    ]

    let tasks = [
        ("Tile delivery", "10:00", "6B9EFF"),
        ("Electrician visit", "14:30", "C9A84C"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Month header
            HStack {
                Image(systemName: "chevron.left").foregroundColor(.white.opacity(0.2)).font(.system(size: 12))
                Spacer()
                Text("February 2026")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.2)).font(.system(size: 12))
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // Day headers
            HStack(spacing: 0) {
                ForEach(["M","T","W","T","F","S","S"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.22))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)

            // Grid
            let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: cols, spacing: 2) {
                ForEach(Array(grid.enumerated()), id: \.0) { idx, day in
                    VStack(spacing: 2) {
                        ZStack {
                            if day.2 {
                                Circle()
                                    .fill(Color(hex: accent))
                                    .frame(width: 26, height: 26)
                            }
                            Text("\(day.0)")
                                .font(.system(size: 12, weight: day.2 ? .bold : .regular))
                                .foregroundColor(day.2 ? Color(hex: "0F0F1A") : .white.opacity(0.75))
                        }
                        if let hex = day.1 {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 4, height: 4)
                                .scaleEffect(animate ? 1 : 0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6)
                                    .delay(Double(idx) * 0.018 + 0.2), value: animate)
                        } else {
                            Color.clear.frame(width: 4, height: 4)
                        }
                    }
                    .frame(height: 36)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)

            Divider().background(.white.opacity(0.07))

            // Tasks for selected day
            VStack(spacing: 0) {
                ForEach(Array(tasks.enumerated()), id: \.0) { i, task in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: task.2))
                            .frame(width: 8, height: 8)
                        Text(task.0)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text(task.1)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .opacity(animate ? 1 : 0)
                    .offset(x: animate ? 0 : -12)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(i) * 0.1 + 0.3), value: animate)

                    if i == 0 { Divider().background(.white.opacity(0.05)).padding(.leading, 36) }
                }
            }
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.09), lineWidth: 1))
        )
        .padding(.horizontal, 28)
    }
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
}
