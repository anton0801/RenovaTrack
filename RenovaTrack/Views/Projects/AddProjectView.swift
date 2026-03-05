import SwiftUI

struct AddProjectView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: ProjectsViewModel

    @State private var name = ""
    @State private var address = ""
    @State private var areaSqM = ""
    @State private var renovationType = "Full Renovation"
    @State private var status = ProjectStatus.inProgress
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
    @State private var totalBudget = ""
    @State private var coverPhoto: UIImage?
    @State private var showImagePicker = false

    let renovationTypes = ["Full Renovation","Kitchen","Bathroom","Bedroom","Living Room","Exterior","Basement","Garage","Other"]
    var isValid: Bool { !name.isEmpty }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1A2E").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // Cover photo
                        Button { showImagePicker = true } label: {
                            ZStack {
                                if let img = coverPhoto {
                                    Image(uiImage: img).resizable().scaledToFill()
                                        .frame(height: 185).clipped()
                                        .overlay(ZStack(alignment: .bottomTrailing) {
                                            LinearGradient(colors: [.clear, Color(hex: "1A1A2E").opacity(0.5)], startPoint: .top, endPoint: .bottom)
                                            HStack { Image(systemName: "camera.fill").font(.system(size: 13)); Text("Change Photo").font(.system(size: 12, weight: .medium)) }
                                            .foregroundColor(.white.opacity(0.8)).padding(12)
                                        })
                                } else {
                                    ZStack {
                                        LinearGradient(colors: [Color(hex: "16213E"), Color(hex: "0F2040")], startPoint: .topLeading, endPoint: .bottomTrailing).frame(height: 185)
                                        VStack(spacing: 10) {
                                            Image(systemName: "camera.fill").font(.system(size: 30)).foregroundColor(.white.opacity(0.2))
                                            Text("Add Cover Photo").font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.3))
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 185).clipped().cornerRadius(16)
                        .buttonStyle(SpringButtonStyle())

                        FormField(title: "Project Name *", placeholder: "e.g., Kitchen Renovation 2025", text: $name)

                        FormField(title: "Address / Location", placeholder: "e.g., 42 Oak Street — Kitchen", text: $address)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionLabel("Area (m²)")
                                TextField("e.g., 28", text: $areaSqM).keyboardType(.decimalPad)
                                    .foregroundColor(Color(hex: "F5EFE6")).tint(Color(hex: "E07B54")).padding(14)
                                    .background(Color(hex: "16213E")).cornerRadius(12)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                SectionLabel("Total Budget ($)")
                                TextField("e.g., 25000", text: $totalBudget).keyboardType(.decimalPad)
                                    .foregroundColor(Color(hex: "F5EFE6")).tint(Color(hex: "E07B54")).padding(14)
                                    .background(Color(hex: "16213E")).cornerRadius(12)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Renovation Type")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(renovationTypes, id: \.self) { t in
                                        Button { withAnimation { renovationType = t } } label: {
                                            Text(t).font(.system(size: 13, weight: .medium))
                                                .foregroundColor(renovationType == t ? Color(hex: "1A1A2E") : .white.opacity(0.6))
                                                .padding(.horizontal, 14).padding(.vertical, 8)
                                                .background(renovationType == t ? Color(hex: "E07B54") : Color(hex: "16213E"))
                                                .cornerRadius(20)
                                                .overlay(Capsule().stroke(Color.white.opacity(renovationType == t ? 0 : 0.08), lineWidth: 1))
                                        }.buttonStyle(SpringButtonStyle())
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Status")
                            HStack(spacing: 8) {
                                ForEach(ProjectStatus.allCases, id: \.self) { s in
                                    Button { withAnimation { status = s } } label: {
                                        Text(s.displayName).font(.system(size: 13, weight: .medium))
                                            .foregroundColor(status == s ? .white : .white.opacity(0.5))
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(status == s ? Color(hex: "E07B54").opacity(0.3) : Color(hex: "16213E"))
                                            .cornerRadius(10)
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(status == s ? 0 : 0.07), lineWidth: 1))
                                    }.buttonStyle(SpringButtonStyle())
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionLabel("Start Date")
                                DatePicker("", selection: $startDate, displayedComponents: .date).labelsHidden()
                                    .datePickerStyle(.compact).tint(Color(hex: "E07B54")).padding(14)
                                    .background(Color(hex: "16213E")).cornerRadius(12)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                SectionLabel("End Date")
                                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date).labelsHidden()
                                    .datePickerStyle(.compact).tint(Color(hex: "E07B54")).padding(14)
                                    .background(Color(hex: "16213E")).cornerRadius(12)
                            }
                        }

                        Button {
                            vm.addProject(
                                name: name, address: address,
                                areaSqM: Double(areaSqM) ?? 0,
                                renovationType: renovationType, status: status,
                                startDate: startDate, endDate: endDate,
                                totalBudget: Double(totalBudget) ?? 0,
                                coverPhoto: coverPhoto.map { $0.jpegData(compressionQuality: 0.8) } ?? nil
                            )
                            dismiss()
                        } label: {
                            Text("Create Project").font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 56)
                                .background(isValid ? Color(hex: "E07B54") : Color.gray.opacity(0.3))
                                .cornerRadius(16)
                                .shadow(color: isValid ? Color(hex: "E07B54").opacity(0.4) : .clear, radius: 12, y: 6)
                        }
                        .buttonStyle(SpringButtonStyle()).disabled(!isValid)
                    }
                    .padding(20).padding(.bottom, 40)
                }
            }
            .navigationTitle("New Project").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Color(hex: "E07B54")) } }
        }
        .sheet(isPresented: $showImagePicker) { ImagePicker(image: $coverPhoto) }
    }
}

// MARK: - Shared Form Components
struct FormField: View {
    let title: String; let placeholder: String; @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title)
            TextField(placeholder, text: $text)
                .foregroundColor(Color(hex: "F5EFE6")).tint(Color(hex: "E07B54")).padding(14)
                .background(Color(hex: "16213E")).cornerRadius(12)
        }
    }
}

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.45)).tracking(0.5)
    }
}
