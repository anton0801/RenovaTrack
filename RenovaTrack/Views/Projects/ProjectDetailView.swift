import SwiftUI

struct ProjectDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var store: DataStore
    var project: RenovaProject   // local copy — refreshed from store
    @ObservedObject var vm: ProjectsViewModel

    @State private var expandedSection: String? = "General Info"
    @State private var showEditProject = false
    @State private var shareItems: [Any] = []
    @State private var showShare = false

    // Always read from store so changes reflect live
    var current: RenovaProject { store.projects.first { $0.id == project.id } ?? project }

    var body: some View {
        ZStack {
            Color(hex: "1A1A2E").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero header
                    ZStack(alignment: .bottomLeading) {
                        if let data = current.coverPhotoData, let img = UIImage(data: data) {
                            Image(uiImage: img).resizable().scaledToFill().frame(height: 230).clipped()
                                .overlay(LinearGradient(colors: [.clear, Color(hex: "1A1A2E").opacity(0.9)], startPoint: .center, endPoint: .bottom))
                        } else {
                            ZStack {
                                LinearGradient(colors: [Color(hex: "0F2040"), Color(hex: "1A1A2E")], startPoint: .top, endPoint: .bottom).frame(height: 230)
                                Canvas { ctx, size in
                                    let sp: CGFloat = 22; var path = Path(); var x: CGFloat = 0
                                    while x <= size.width { path.move(to: .init(x: x, y: 0)); path.addLine(to: .init(x: x, y: size.height)); x += sp }
                                    var y: CGFloat = 0
                                    while y <= size.height { path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: size.width, y: y)); y += sp }
                                    ctx.stroke(path, with: .color(Color(hex: "C9A84C").opacity(0.07)), lineWidth: 0.5)
                                }.frame(height: 230)
                                Image(systemName: "house.fill").font(.system(size: 64)).foregroundColor(.white.opacity(0.05))
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(current.name).font(.system(size: 26, weight: .black, design: .rounded)).foregroundColor(Color(hex: "F5EFE6"))
                            if !current.address.isEmpty {
                                HStack(spacing: 5) {
                                    Image(systemName: "location.fill").font(.system(size: 11)).foregroundColor(Color(hex: "E07B54"))
                                    Text(current.address).font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }.padding(20)
                    }.frame(height: 230).clipped()

                    // Stat bar
                    HStack(spacing: 0) {
                        StatPill(label: "Progress", value: "\(Int(current.progress * 100))%", color: Color(hex: "C9A84C"))
                        Divider().background(.white.opacity(0.08)).frame(height: 40)
                        StatPill(label: "Spent", value: "$\(Int(current.spentBudget).formattedWithComma())", color: Color(hex: "E07B54"))
                        Divider().background(.white.opacity(0.08)).frame(height: 40)
                        if let days = current.daysRemaining {
                            StatPill(label: days < 0 ? "Overdue" : "Days Left", value: "\(abs(days))d", color: days < 0 ? Color(hex: "E05454") : Color(hex: "4CAF84"))
                        } else {
                            StatPill(label: "Budget", value: "$\(Int(current.totalBudget).formattedWithComma())", color: Color(hex: "F5EFE6"))
                        }
                    }
                    .padding(.vertical, 14).padding(.horizontal, 20)
                    .background(Color(hex: "16213E"))
                    .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5), alignment: .bottom)

                    // Action buttons
                    HStack(spacing: 10) {
                        ActionButton(icon: "square.and.pencil", label: "Edit") { showEditProject = true }
//                        ActionButton(icon: "doc.text.fill", label: "PDF") {
//                            let data = PDFGenerator.generate(project: current, stages: current.stages, budgetItems: current.budgetItems, contractors: current.contractors)
//                            shareItems = [data]
//                            showShare = true
//                        }
                        ActionButton(icon: "trash.fill", label: "Delete", color: Color(hex: "E05454")) {
                            vm.delete(id: current.id)
                            dismiss()
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)

                    // Accordion sections
                    VStack(spacing: 10) {
                        AccordionSection(title: "General Info", icon: "info.circle.fill", badge: nil, expanded: $expandedSection) {
                            GeneralInfoContent(project: current)
                        }
                        AccordionSection(title: "Stages", icon: "checklist", badge: "\(current.stages.filter { $0.isCompleted }.count)/\(current.stages.count)", expanded: $expandedSection) {
                            StagesContent(project: current, store: store)
                        }
                        AccordionSection(title: "Budget", icon: "dollarsign.circle.fill", badge: "$\(Int(current.spentBudget).formattedWithComma())", expanded: $expandedSection) {
                            BudgetContent(project: current, store: store)
                        }
                        AccordionSection(title: "Contractors", icon: "person.2.fill", badge: current.contractors.isEmpty ? nil : "\(current.contractors.count)", expanded: $expandedSection) {
                            ContractorsContent(project: current, store: store)
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 10)

                    Spacer().frame(height: 120)
                }
            }
        }
        .navigationBarHidden(false)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEditProject = true } label: {
                    Image(systemName: "square.and.pencil").foregroundColor(Color(hex: "E07B54"))
                }
            }
        }
        .sheet(isPresented: $showEditProject) { EditProjectView(project: current, vm: vm) }
        .sheet(isPresented: $showShare) {
            if !shareItems.isEmpty { ActivityView(activityItems: shareItems) }
        }
    }
}

// MARK: - General Info
struct GeneralInfoContent: View {
    let project: RenovaProject
    var body: some View {
        VStack(spacing: 10) {
            InfoRow(label: "Type",    value: project.renovationType)
            InfoRow(label: "Status",  value: project.status.displayName)
            InfoRow(label: "Area",    value: project.areaSqM > 0 ? "\(Int(project.areaSqM)) m²" : "—")
            InfoRow(label: "Start",   value: project.startDate.formatted(date: .long, time: .omitted))
            InfoRow(label: "Finish",  value: project.endDate.formatted(date: .long, time: .omitted))
            InfoRow(label: "Budget",  value: "$\(Int(project.totalBudget).formattedWithComma())")
        }.padding(16)
    }
}

// MARK: - Stages
struct StagesContent: View {
    let project: RenovaProject
    let store: DataStore
    var body: some View {
        VStack(spacing: 8) {
            ForEach(project.stages) { stage in
                HStack(spacing: 12) {
                    Button {
                        var p = project
                        if let i = p.stages.firstIndex(where: { $0.id == stage.id }) {
                            p.stages[i].isCompleted.toggle()
                            store.updateProject(p)
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(stage.isCompleted ? Color(hex: "4CAF84") : Color.white.opacity(0.07))
                                .frame(width: 28, height: 28)
                            if stage.isCompleted { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white) }
                        }
                    }.buttonStyle(SpringButtonStyle())

                    Text(stage.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(stage.isCompleted ? .white.opacity(0.4) : Color(hex: "F5EFE6"))
                        .strikethrough(stage.isCompleted, color: .white.opacity(0.3))
                    Spacer()
                }
                .padding(.vertical, 4)
                if stage.id != project.stages.last?.id { Divider().background(.white.opacity(0.06)) }
            }
        }.padding(16)
    }
}

// MARK: - Budget
struct BudgetContent: View {
    let project: RenovaProject
    let store: DataStore
    @State private var showAddItem = false
    @State private var editItem: RenovaBudgetItem?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(project.budgetItems) { item in
                BudgetRow(item: item) { newSpent in
                    var p = project
                    if let i = p.budgetItems.firstIndex(where: { $0.id == item.id }) {
                        p.budgetItems[i].spent = newSpent
                        store.updateProject(p)
                    }
                } onDelete: {
                    var p = project
                    p.budgetItems.removeAll { $0.id == item.id }
                    store.updateProject(p)
                }
            }
            // Totals
            Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
            HStack {
                Text("TOTAL").font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.5)).tracking(1)
                Spacer()
                Text("$\(Int(project.budgetItems.reduce(0){$0+$1.spent}).formattedWithComma()) / $\(Int(project.budgetItems.reduce(0){$0+$1.planned}).formattedWithComma())")
                    .font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(Color(hex: "C9A84C"))
            }.padding(.horizontal, 16).padding(.vertical, 12)
        }
    }
}

struct BudgetRow: View {
    let item: RenovaBudgetItem
    let onUpdate: (Double) -> Void
    let onDelete: () -> Void
    @State private var editSpent = ""
    @State private var editing = false
    var pct: Double { item.planned > 0 ? min(item.spent / item.planned, 1) : 0 }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(item.category).font(.system(size: 13, weight: .medium)).foregroundColor(Color(hex: "F5EFE6"))
                Spacer()
                if editing {
                    HStack(spacing: 6) {
                        TextField("Spent", text: $editSpent).keyboardType(.decimalPad)
                            .font(.system(size: 13, design: .monospaced)).foregroundColor(Color(hex: "E07B54"))
                            .frame(width: 80).tint(Color(hex: "E07B54"))
                        Button("✓") {
                            if let v = Double(editSpent) { onUpdate(v) }
                            editing = false
                        }.foregroundColor(Color(hex: "4CAF84")).font(.system(size: 15, weight: .bold))
                    }
                } else {
                    Button {
                        editSpent = String(Int(item.spent))
                        editing = true
                    } label: {
                        Text("$\(Int(item.spent)) / $\(Int(item.planned))").font(.system(size: 12, design: .monospaced)).foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.07)).frame(height: 4)
                    Capsule().fill(pct >= 1 ? Color(hex: "E05454") : Color(hex: "E07B54")).frame(width: g.size.width * pct, height: 4)
                }
            }.frame(height: 4)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .swipeActions(edge: .trailing) { Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") } }
    }
}

// MARK: - Contractors
struct ContractorsContent: View {
    let project: RenovaProject
    let store: DataStore
    @State private var showAdd = false

    var body: some View {
        VStack(spacing: 0) {
            if project.contractors.isEmpty {
                HStack { Spacer(); Text("No contractors added yet").font(.system(size: 13)).foregroundColor(.white.opacity(0.3)); Spacer() }.padding(20)
            }
            ForEach(project.contractors) { c in
                ContractorRow(contractor: c) {
                    var p = project; p.contractors.removeAll { $0.id == c.id }; store.updateProject(p)
                }
            }
            Button {showAdd = true} label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 15)).foregroundColor(Color(hex: "E07B54"))
                    Text("Add Contractor").font(.system(size: 14, weight: .medium)).foregroundColor(Color(hex: "E07B54"))
                }
                .frame(maxWidth: .infinity).padding(14).background(Color(hex: "E07B54").opacity(0.07)).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "E07B54").opacity(0.2), lineWidth: 1))
            }.buttonStyle(SpringButtonStyle()).padding(12)
        }
        .sheet(isPresented: $showAdd) { AddContractorSheet(project: project, store: store) }
    }
}

struct ContractorRow: View {
    let contractor: RenovaContractor
    let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: "E07B54").opacity(0.12)).frame(width: 42, height: 42)
                Text(String(contractor.name.prefix(1))).font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: "E07B54"))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(contractor.name).font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: "F5EFE6"))
                Text(contractor.role).font(.system(size: 12)).foregroundColor(.white.opacity(0.45))
                if !contractor.phone.isEmpty { Text(contractor.phone).font(.system(size: 11)).foregroundColor(.white.opacity(0.35)) }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("$\(Int(contractor.contractAmount).formattedWithComma())").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(Color(hex: "C9A84C"))
                HStack(spacing: 2) { ForEach(0..<5) { i in Image(systemName: i < contractor.rating ? "star.fill" : "star").font(.system(size: 8)).foregroundColor(i < contractor.rating ? Color(hex: "C9A84C") : .white.opacity(0.2)) } }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .swipeActions(edge: .trailing) { Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") } }
    }
}

struct AddContractorSheet: View {
    @Environment(\.dismiss) var dismiss
    let project: RenovaProject; let store: DataStore
    @State private var name = ""; @State private var role = ""; @State private var phone = ""
    @State private var amount = ""; @State private var rating = 3

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1A2E").ignoresSafeArea()
                VStack(spacing: 20) {
                    FormField(title: "Name *", placeholder: "Contractor name", text: $name)
                    FormField(title: "Role", placeholder: "e.g., Electrician, Plumber", text: $role)
                    FormField(title: "Phone", placeholder: "+1 555 000 0000", text: $phone)
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Contract Amount ($)")
                        TextField("e.g., 5000", text: $amount).keyboardType(.decimalPad)
                            .foregroundColor(Color(hex: "F5EFE6")).tint(Color(hex: "E07B54")).padding(14).background(Color(hex: "16213E")).cornerRadius(12)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Rating")
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { i in
                                Button { rating = i } label: {
                                    Image(systemName: i <= rating ? "star.fill" : "star").font(.system(size: 24))
                                        .foregroundColor(i <= rating ? Color(hex: "C9A84C") : .white.opacity(0.2))
                                }.buttonStyle(SpringButtonStyle())
                            }
                        }
                    }
                    Spacer()
                    Button("Add Contractor") {
                        let c = RenovaContractor(name: name, phone: phone, role: role, contractAmount: Double(amount) ?? 0, rating: rating)
                        var p = project; p.contractors.append(c); store.updateProject(p); dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(name.isEmpty ? Color.gray.opacity(0.3) : Color(hex: "E07B54")).cornerRadius(16)
                    .buttonStyle(SpringButtonStyle()).disabled(name.isEmpty).padding(.bottom, 20)
                }
                .padding(20)
            }
            .navigationTitle("Add Contractor").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Color(hex: "E07B54")) } }
        }
    }
}

// MARK: - Edit Project
struct EditProjectView: View {
    @Environment(\.dismiss) var dismiss
    let project: RenovaProject
    @ObservedObject var vm: ProjectsViewModel

    @State private var name: String
    @State private var address: String
    @State private var totalBudget: String
    @State private var status: ProjectStatus
    @State private var endDate: Date

    init(project: RenovaProject, vm: ProjectsViewModel) {
        self.project = project; self.vm = vm
        _name = State(initialValue: project.name)
        _address = State(initialValue: project.address)
        _totalBudget = State(initialValue: "\(Int(project.totalBudget))")
        _status = State(initialValue: project.status)
        _endDate = State(initialValue: project.endDate)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1A2E").ignoresSafeArea()
                VStack(spacing: 20) {
                    FormField(title: "Project Name", placeholder: "", text: $name)
                    FormField(title: "Address", placeholder: "", text: $address)
                    FormField(title: "Total Budget ($)", placeholder: "", text: $totalBudget)
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Status")
                        HStack(spacing: 8) {
                            ForEach(ProjectStatus.allCases, id: \.self) { s in
                                Button { status = s } label: {
                                    Text(s.displayName).font(.system(size: 13, weight: .medium))
                                        .foregroundColor(status == s ? .white : .white.opacity(0.5))
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(status == s ? Color(hex: "E07B54").opacity(0.3) : Color(hex: "16213E")).cornerRadius(10)
                                }.buttonStyle(SpringButtonStyle())
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("End Date")
                        DatePicker("", selection: $endDate, displayedComponents: .date).labelsHidden()
                            .datePickerStyle(.compact).tint(Color(hex: "E07B54")).padding(14).background(Color(hex: "16213E")).cornerRadius(12)
                    }
                    Spacer()
                    Button("Save Changes") {
                        var p = project
                        p.name = name; p.address = address
                        p.totalBudget = Double(totalBudget) ?? project.totalBudget
                        p.status = status; p.endDate = endDate
                        vm.update(p); dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 54).background(Color(hex: "E07B54")).cornerRadius(16)
                    .buttonStyle(SpringButtonStyle()).padding(.bottom, 20)
                }
                .padding(20)
            }
            .navigationTitle("Edit Project").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Color(hex: "E07B54")) } }
        }
    }
}

// MARK: - Accordion
struct AccordionSection<Content: View>: View {
    let title: String; let icon: String; let badge: String?
    @Binding var expanded: String?
    @ViewBuilder let content: () -> Content

    var isExpanded: Bool { expanded == title }

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.spring(response: 0.38, dampingFraction: 0.75)) { expanded = isExpanded ? nil : title } } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon).font(.system(size: 15)).foregroundColor(Color(hex: "E07B54")).frame(width: 22)
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "F5EFE6"))
                    Spacer()
                    if let b = badge { Text(b).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(Color(hex: "C9A84C")).padding(.horizontal, 8).padding(.vertical, 3).background(Color(hex: "C9A84C").opacity(0.12)).cornerRadius(8) }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Divider().background(Color.white.opacity(0.07))
                content()
            }
        }
        .background(Color(hex: "16213E")).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1))
    }
}

// MARK: - Helpers
struct StatPill: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.4)).tracking(0.5)
            Text(value).font(.system(size: 17, weight: .black, design: .rounded)).foregroundColor(color)
        }.frame(maxWidth: .infinity)
    }
}

struct InfoRow: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(.white.opacity(0.45)).frame(width: 70, alignment: .leading)
            Text(value).font(.system(size: 13, weight: .medium)).foregroundColor(Color(hex: "F5EFE6"))
            Spacer()
        }
    }
}

struct ActionButton: View {
    let icon: String; let label: String; var color: Color = Color(hex: "E07B54"); let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundColor(color)
                Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(color.opacity(0.8))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(color.opacity(0.1)).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
        }.buttonStyle(SpringButtonStyle())
    }
}

// MARK: - Activity View (Share Sheet)
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
