import SwiftUI

@main
struct RenovaTrackApp: App {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    @State private var showSplash = true
    @StateObject private var store = DataStore.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(2)
                } else if !hasSeenOnboarding {
                    OnboardingView()
                        .transition(.opacity)
                        .zIndex(1)
                } else {
                    ContentView()
                        .environmentObject(store)
                        .transition(.opacity)
                        .zIndex(0)
                }
            }
            .animation(.easeInOut(duration: 0.45), value: showSplash)
            .animation(.easeInOut(duration: 0.45), value: hasSeenOnboarding)
            .onAppear {
                NotificationManager.shared.requestAuthorization()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                    withAnimation { showSplash = false }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0: ProjectsView()
                case 1: CalendarView()
                case 2: PhotoLogView()
                case 3: SettingsView()
                default: ProjectsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let items: [(label: String, icon: String, activeIcon: String)] = [
        ("Projects",  "house",           "house.fill"),
        ("Calendar",  "calendar",        "calendar.badge.clock"),
        ("Photos",    "camera",          "camera.fill"),
        ("Settings",  "gearshape",       "gearshape.fill")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        selectedTab = i
                    }
                } label: {
                    VStack(spacing: 5) {
                        ZStack {
                            if selectedTab == i {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "E07B54").opacity(0.18))
                                    .frame(width: 44, height: 32)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            Image(systemName: selectedTab == i ? items[i].activeIcon : items[i].icon)
                                .font(.system(size: 20, weight: selectedTab == i ? .bold : .regular))
                                .foregroundColor(selectedTab == i ? Color(hex: "E07B54") : .white.opacity(0.38))
                                .scaleEffect(selectedTab == i ? 1.1 : 1.0)
                        }
                        .frame(width: 44, height: 32)

                        Text(items[i].label)
                            .font(.system(size: 10, weight: selectedTab == i ? .semibold : .regular))
                            .foregroundColor(selectedTab == i ? Color(hex: "E07B54") : .white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            ZStack {
                Color(hex: "141428")
                    .overlay(
                        LinearGradient(
                            colors: [Color(hex: "C9A84C").opacity(0.12), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 0.5),
                        alignment: .top
                    )
            }
        )
        .overlay(
            Rectangle()
                .fill(Color(hex: "C9A84C").opacity(0.18))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}
