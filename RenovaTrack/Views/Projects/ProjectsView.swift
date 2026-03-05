import SwiftUI

// MARK: - Projects Screen
struct ProjectsView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = ProjectsViewModel()
    @State private var showAddProject = false
    @State private var filterStatus: ProjectStatus? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1A2E").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("My Projects")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: "F5EFE6"))
                                    Text("\(store.projects.count) renovation\(store.projects.count == 1 ? "" : "s") tracked")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.45))
                                }
                                Spacer()
                                ZStack {
                                    Circle().fill(Color(hex: "E07B54").opacity(0.15)).frame(width: 44, height: 44)
                                    Image(systemName: "house.fill").font(.system(size: 20)).foregroundColor(Color(hex: "E07B54"))
                                }
                            }

                            // Search
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.35))
                                TextField("Search projects...", text: $vm.searchText)
                                    .foregroundColor(Color(hex: "F5EFE6")).tint(Color(hex: "E07B54"))
                                if !vm.searchText.isEmpty {
                                    Button { vm.searchText = "" } label: {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.35))
                                    }
                                }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(Color(hex: "16213E"))
                            .cornerRadius(13)
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.07), lineWidth: 1))

                            // Filter chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(label: "All", isSelected: filterStatus == nil) {
                                        withAnimation { filterStatus = nil; vm.filterStatus = nil }
                                    }
                                    ForEach(ProjectStatus.allCases, id: \.self) { s in
                                        FilterChip(label: s.displayName, isSelected: filterStatus == s) {
                                            withAnimation { filterStatus = s; vm.filterStatus = s }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 20)

                        if vm.filteredProjects.isEmpty {
                            EmptyProjectsView()
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(vm.filteredProjects) { project in
                                    NavigationLink {
                                        ProjectDetailView(project: project, vm: vm)
                                    } label: {
                                        ProjectCard(project: project)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button(role: .destructive) { vm.delete(id: project.id) } label: {
                                            Label("Delete Project", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        Spacer().frame(height: 120)
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { showAddProject = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                                Text("New Project").font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white).padding(.horizontal, 22).padding(.vertical, 15)
                            .background(LinearGradient(colors: [Color(hex: "E07B54"), Color(hex: "C9A84C")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(30)
                            .shadow(color: Color(hex: "E07B54").opacity(0.55), radius: 18, y: 8)
                        }
                        .buttonStyle(SpringButtonStyle())
                        .padding(.trailing, 20).padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showAddProject) { AddProjectView(vm: vm) }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? Color(hex: "1A1A2E") : .white.opacity(0.6))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? Color(hex: "E07B54") : Color(hex: "16213E"))
                .cornerRadius(20)
                .overlay(Capsule().stroke(Color.white.opacity(isSelected ? 0 : 0.08), lineWidth: 1))
        }.buttonStyle(SpringButtonStyle())
    }
}

// MARK: - Empty State
struct EmptyProjectsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)
            ZStack {
                Circle().fill(Color(hex: "16213E")).frame(width: 100, height: 100)
                Image(systemName: "house.badge.plus").font(.system(size: 42)).foregroundColor(Color(hex: "E07B54").opacity(0.5))
            }
            Text("No Projects Yet").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(Color(hex: "F5EFE6"))
            Text("Tap \"+ New Project\" to start\ntracking your first renovation.")
                .font(.system(size: 15)).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center).lineSpacing(4)
        }
    }
}

// MARK: - Project Card
struct ProjectCard: View {
    let project: RenovaProject

    var statusColor: Color {
        switch project.status {
        case .completed: return Color(hex: "4CAF84")
        case .onHold:    return Color(hex: "F0A500")
        default:         return Color(hex: "E07B54")
        }
    }
    var statusIcon: String {
        switch project.status {
        case .completed: return "checkmark.circle.fill"
        case .onHold:    return "pause.circle.fill"
        default:         return "hammer.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover
            ZStack(alignment: .topTrailing) {
                if let data = project.coverPhotoData, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill().frame(height: 148).clipped()
                        .overlay(LinearGradient(colors: [.clear, Color(hex: "16213E").opacity(0.85)], startPoint: .top, endPoint: .bottom))
                } else {
                    ZStack {
                        LinearGradient(colors: [Color(hex: "16213E"), Color(hex: "0F2040")], startPoint: .topLeading, endPoint: .bottomTrailing).frame(height: 148)
                        Canvas { ctx, size in
                            let sp: CGFloat = 20; var path = Path(); var x: CGFloat = 0
                            while x <= size.width { path.move(to: .init(x: x, y: 0)); path.addLine(to: .init(x: x, y: size.height)); x += sp }
                            var y: CGFloat = 0
                            while y <= size.height { path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: size.width, y: y)); y += sp }
                            ctx.stroke(path, with: .color(Color(hex: "C9A84C").opacity(0.06)), lineWidth: 0.5)
                        }.frame(height: 148)
                        Image(systemName: "house.fill").font(.system(size: 44)).foregroundColor(.white.opacity(0.07))
                    }
                }
                HStack(spacing: 5) {
                    Image(systemName: statusIcon).font(.system(size: 10, weight: .bold))
                    Text(project.status.displayName).font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6)
                .background(statusColor).cornerRadius(20).padding(12)
            }
            .frame(height: 148).clipped()

            // Body
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name).font(.system(size: 19, weight: .bold, design: .rounded)).foregroundColor(Color(hex: "F5EFE6")).lineLimit(1)
                    HStack(spacing: 6) {
                        if !project.address.isEmpty {
                            Image(systemName: "location.fill").font(.system(size: 10)).foregroundColor(Color(hex: "E07B54"))
                            Text(project.address).font(.system(size: 13)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                        }
                        if !project.renovationType.isEmpty {
                            Text("·").foregroundColor(.white.opacity(0.3))
                            Text(project.renovationType).font(.system(size: 13)).foregroundColor(.white.opacity(0.4)).lineLimit(1)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Progress").font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.45))
                        Spacer()
                        Text("\(Int(project.progress * 100))% complete").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(Color(hex: "C9A84C"))
                    }
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08)).frame(height: 7)
                            Capsule()
                                .fill(LinearGradient(
                                    colors: project.progress >= 1 ? [Color(hex: "4CAF84"), Color(hex: "4CAF84")] : [Color(hex: "E07B54"), Color(hex: "C9A84C")],
                                    startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(g.size.width * project.progress, project.progress > 0 ? 7 : 0), height: 7)
                        }
                    }.frame(height: 7)
                }

                HStack(spacing: 0) {
                    BudgetPill(label: "Budget", amount: project.totalBudget, color: Color(hex: "F5EFE6"))
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 32)
                    BudgetPill(label: "Spent",  amount: project.spentBudget, color: Color(hex: "E07B54"))
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 32)
                    BudgetPill(label: "Left",   amount: max(0, project.totalBudget - project.spentBudget), color: Color(hex: "4CAF84"))
                }
                .padding(.vertical, 10).background(Color.white.opacity(0.04)).cornerRadius(11)

                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar").font(.system(size: 11)).foregroundColor(.white.opacity(0.35))
                        Text(project.startDate.formatted(date: .abbreviated, time: .omitted))
                        Text("→")
                        Text(project.endDate.formatted(date: .abbreviated, time: .omitted))
                    }.font(.system(size: 11)).foregroundColor(.white.opacity(0.38))
                    Spacer()
                    if let days = project.daysRemaining {
                        HStack(spacing: 4) {
                            Image(systemName: days < 0 ? "exclamationmark.circle.fill" : "clock").font(.system(size: 11))
                                .foregroundColor(days < 0 ? Color(hex: "E05454") : days < 7 ? Color(hex: "F0A500") : .white.opacity(0.35))
                            Text(days < 0 ? "\(abs(days))d overdue" : "\(days)d left")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(days < 0 ? Color(hex: "E05454") : days < 7 ? Color(hex: "F0A500") : .white.opacity(0.4))
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(hex: "16213E")).cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.065), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 5)
    }
}

// MARK: - Budget Pill
struct BudgetPill: View {
    let label: String; let amount: Double; let color: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.38))
            Text("$\(Int(amount).formattedWithComma())").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(color)
        }.frame(maxWidth: .infinity)
    }
}

extension Int {
    func formattedWithComma() -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
