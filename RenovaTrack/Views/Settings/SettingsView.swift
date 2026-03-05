import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: DataStore
    @ObservedObject var settings = AppSettings.shared
    @State private var showClearAlert = false
    @State private var shareItems: [Any] = []
    @State private var showShare = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1A2E").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Settings").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundColor(Color(hex: "F5EFE6"))
                                Text("Customize your experience").font(.system(size: 14)).foregroundColor(.white.opacity(0.45))
                            }
                            Spacer()
                            ZStack {
                                Circle().fill(Color(hex: "C9A84C").opacity(0.12)).frame(width: 44, height: 44)
                                Image(systemName: "gearshape.fill").font(.system(size: 20)).foregroundColor(Color(hex: "C9A84C"))
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 20)

                        // Preferences
                        SettingsSection(title: "Preferences") {
                            HStack(spacing: 12) {
                                Image(systemName: "ruler.fill").font(.system(size: 16)).foregroundColor(Color(hex: "6B9EFF")).frame(width: 24)
                                Text("Measurement Units").font(.system(size: 15)).foregroundColor(Color(hex: "F5EFE6"))
                                Spacer()
                                Picker("", selection: $settings.useMetricUnits) {
                                    Text("Metric").tag(true)
                                    Text("Imperial").tag(false)
                                }.pickerStyle(.segmented).frame(width: 140)
                            }.padding(.vertical, 6)
                        }

                        // Stage Templates
                        SettingsSection(title: "Stage Templates") {
                            VStack(spacing: 0) {
                                ForEach(settings.stageTemplates.indices, id: \.self) { i in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 7).fill(Color(hex: "E07B54").opacity(0.15)).frame(width: 28, height: 28)
                                            Image(systemName: "checkmark.square.fill").font(.system(size: 14)).foregroundColor(Color(hex: "E07B54"))
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(settings.stageTemplates[i].name).font(.system(size: 14, weight: .medium)).foregroundColor(Color(hex: "F5EFE6"))
                                            Text("\(settings.stageTemplates[i].checklistItems.count) checklist items").font(.system(size: 11)).foregroundColor(.white.opacity(0.38))
                                        }
                                        Spacer()
                                    }.padding(.vertical, 10)
                                    if i < settings.stageTemplates.count - 1 { Divider().background(Color.white.opacity(0.06)) }
                                }
                            }
                        }

                        // Export & Data
                        SettingsSection(title: "Export & Data") {
                            VStack(spacing: 0) {
//                                SettingsActionRow(icon: "doc.richtext.fill", label: "Export All Projects as PDF", color: Color(hex: "E07B54")) { exportPDF() }
                                Divider().background(Color.white.opacity(0.06))
                                SettingsActionRow(icon: "tablecells.fill", label: "Export Projects as CSV", color: Color(hex: "C9A84C")) { exportCSV() }
                                Divider().background(Color.white.opacity(0.06))
                                SettingsActionRow(icon: "trash.fill", label: "Clear All Data", color: Color(hex: "E05454")) { showClearAlert = true }
                            }
                        }

                        // About
                        SettingsSection(title: "About") {
                            VStack(spacing: 0) {
                                SettingsInfoRow(icon: "hammer.circle.fill", label: "App",      value: "RenovaTrack",  color: Color(hex: "E07B54"))
                                Divider().background(Color.white.opacity(0.06))
                                SettingsInfoRow(icon: "number.circle.fill", label: "Version",  value: "1.0.0",        color: Color(hex: "6B9EFF"))
                                Divider().background(Color.white.opacity(0.06))
                                SettingsInfoRow(icon: "iphone",             label: "Platform", value: "iOS 16.0+",    color: Color(hex: "4CAF84"))
                            }
                        }

                        VStack(spacing: 8) {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(LinearGradient(colors: [Color(hex: "E07B54"), Color(hex: "C9A84C")], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 36, height: 36)
                                    Image(systemName: "house.fill").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("RenovaTrack").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(Color(hex: "F5EFE6"))
                                    Text("Your personal renovation manager").font(.system(size: 11)).foregroundColor(.white.opacity(0.35))
                                }
                            }
                            Text("Made with ❤️ for homeowners").font(.system(size: 11)).foregroundColor(.white.opacity(0.2))
                        }
                        .padding(.vertical, 20).padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Clear All Data", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear Everything", role: .destructive) {
                store.clearAll()
            }
        } message: {
            Text("This will permanently delete all projects, tasks, and photos. This cannot be undone.")
        }
        .sheet(isPresented: $showShare) {
            if !shareItems.isEmpty { ActivityView(activityItems: shareItems) }
        }
    }

//    func exportPDF() {
//        let projects = store.projects
//        guard !projects.isEmpty else { return }
//        let data = PDFGenerator.generateAll(projects: projects)
//        let url = FileManager.default.temporaryDirectory.appendingPathComponent("RenovaTrack_All_Projects.pdf")
//        try? data.write(to: url)
//        shareItems = [url]
//        showShare = true
//    }

    func exportCSV() {
        let projects = store.projects
        guard !projects.isEmpty else { return }
        var csv = "Project Name,Address,Type,Status,Start Date,End Date,Total Budget,Spent,Remaining,Progress %\n"
        let df = DateFormatter(); df.dateStyle = .medium
        for p in projects {
            let spent = p.spentBudget
            let rem = max(0, p.totalBudget - spent)
            let prog = Int(p.progress * 100)
            csv += "\"\(p.name)\",\"\(p.address)\",\(p.renovationType),\(p.status.displayName),\(df.string(from: p.startDate)),\(df.string(from: p.endDate)),\(Int(p.totalBudget)),\(Int(spent)),\(Int(rem)),\(prog)%\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("RenovaTrack_Export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        shareItems = [url]
        showShare = true
    }
}

// MARK: - Section Container
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased()).font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: "C9A84C").opacity(0.7)).tracking(1.4).padding(.horizontal, 20)
            VStack(spacing: 0) { content }
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(Color(hex: "16213E")).cornerRadius(15)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.065), lineWidth: 1))
                .padding(.horizontal, 16)
        }
    }
}

struct SettingsActionRow: View {
    let icon: String; let label: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 15)).foregroundColor(color)
                }
                Text(label).font(.system(size: 15)).foregroundColor(Color(hex: "F5EFE6"))
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.white.opacity(0.25))
            }.padding(.vertical, 11).contentShape(Rectangle())
        }.buttonStyle(SpringButtonStyle())
    }
}

struct SettingsInfoRow: View {
    let icon: String; let label: String; let value: String; let color: Color
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 15)).foregroundColor(color)
            }
            Text(label).font(.system(size: 15)).foregroundColor(Color(hex: "F5EFE6"))
            Spacer()
            Text(value).font(.system(size: 14)).foregroundColor(.white.opacity(0.4))
        }.padding(.vertical, 11)
    }
}
