import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = CalendarViewModel()
    @State private var showAddTask = false
    @State private var currentMonth = Date()

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1A2E").ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calendar").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundColor(Color(hex: "F5EFE6"))
                            Text("\(store.tasks.count) tasks total").font(.system(size: 14)).foregroundColor(.white.opacity(0.45))
                        }
                        Spacer()
                        Button { showAddTask = true } label: {
                            ZStack {
                                Circle().fill(Color(hex: "E07B54").opacity(0.15)).frame(width: 44, height: 44)
                                Image(systemName: "plus").font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: "E07B54"))
                            }
                        }.buttonStyle(SpringButtonStyle())
                    }
                    .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            MonthCalendarView(currentMonth: $currentMonth, selectedDate: $vm.selectedDate, dotColors: vm.dotColors)
                                .padding(.horizontal, 16)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(vm.selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                                            .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(Color(hex: "F5EFE6"))
                                        if !vm.tasksForSelectedDate.isEmpty {
                                            Text("\(vm.tasksForSelectedDate.count) task\(vm.tasksForSelectedDate.count == 1 ? "" : "s")")
                                                .font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
                                        }
                                    }
                                    Spacer()
                                    Button { showAddTask = true } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: "plus").font(.system(size: 11, weight: .bold))
                                            Text("Add").font(.system(size: 12, weight: .semibold))
                                        }
                                        .foregroundColor(Color(hex: "E07B54")).padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(Color(hex: "E07B54").opacity(0.12)).cornerRadius(20)
                                    }.buttonStyle(SpringButtonStyle())
                                }
                                .padding(.horizontal, 20)

                                if vm.tasksForSelectedDate.isEmpty {
                                    VStack(spacing: 14) {
                                        Image(systemName: "calendar.badge.checkmark").font(.system(size: 42)).foregroundColor(.white.opacity(0.12))
                                        Text("No tasks for this day").font(.system(size: 15)).foregroundColor(.white.opacity(0.3))
                                        Text("Tap '+' to add a task or reminder").font(.system(size: 12)).foregroundColor(.white.opacity(0.2))
                                    }.frame(maxWidth: .infinity).padding(.vertical, 40)
                                } else {
                                    LazyVStack(spacing: 10) {
                                        ForEach(vm.tasksForSelectedDate) { task in
                                            TaskRow(task: task, vm: vm)
                                        }
                                    }.padding(.horizontal, 20)
                                }
                            }

                            let upcoming = store.tasks.filter { $0.date > Date() && $0.status != "done" && !Calendar.current.isDate($0.date, inSameDayAs: vm.selectedDate) }.prefix(5)
                            if !upcoming.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("UPCOMING").font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.3)).tracking(1.5)
                                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
                                    ForEach(Array(upcoming)) { task in
                                        UpcomingTaskRow(task: task).padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 120)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddTask) { AddTaskSheet(vm: vm, defaultDate: vm.selectedDate) }
    }
}

// MARK: - Month Calendar
struct MonthCalendarView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let dotColors: (Date) -> [Color]

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var monthDays: [Date?] {
        let comps = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let first = calendar.date(from: comps) else { return [] }
        let weekday = calendar.component(.weekday, from: first)
        let offset = (weekday + 5) % 7
        let range = calendar.range(of: .day, in: .month, for: first)!
        var result: [Date?] = Array(repeating: nil, count: offset)
        for d in range { result.append(calendar.date(bySetting: .day, value: d, of: first)) }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)! } } label: {
                    Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "E07B54"))
                        .frame(width: 32, height: 32).background(Color(hex: "E07B54").opacity(0.1)).cornerRadius(8)
                }.buttonStyle(SpringButtonStyle())
                Spacer()
                Text(currentMonth.formatted(.dateTime.month(.wide).year())).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(Color(hex: "F5EFE6"))
                Spacer()
                Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)! } } label: {
                    Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "E07B54"))
                        .frame(width: 32, height: 32).background(Color(hex: "E07B54").opacity(0.1)).cornerRadius(8)
                }.buttonStyle(SpringButtonStyle())
            }

            HStack { ForEach(["Mo","Tu","We","Th","Fr","Sa","Su"], id: \.self) { d in Text(d).font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.28)).frame(maxWidth: .infinity) } }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<monthDays.count, id: \.self) { i in
                    if let date = monthDays[i] {
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isToday = calendar.isDateInToday(date)
                        let dots = dotColors(date)
                        Button { withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) { selectedDate = date } } label: {
                            VStack(spacing: 3) {
                                ZStack {
                                    if isSelected { Circle().fill(Color(hex: "E07B54")).frame(width: 34, height: 34) }
                                    else if isToday { Circle().stroke(Color(hex: "C9A84C"), lineWidth: 1.5).frame(width: 34, height: 34) }
                                    Text("\(calendar.component(.day, from: date))").font(.system(size: 14, weight: isSelected || isToday ? .bold : .regular))
                                        .foregroundColor(isSelected ? .white : isToday ? Color(hex: "C9A84C") : Color(hex: "F5EFE6"))
                                }
                                HStack(spacing: 2) { ForEach(Array(dots.prefix(3).enumerated()), id: \.0) { _, c in Circle().fill(c).frame(width: 4, height: 4) } }.frame(height: 5)
                            }.frame(height: 50)
                        }.buttonStyle(SpringButtonStyle())
                    } else { Color.clear.frame(height: 50) }
                }
            }

            HStack(spacing: 16) {
                ForEach([("Urgent", Color(hex: "E05454")), ("Planned", Color(hex: "6B9EFF")), ("Done", Color(hex: "4CAF84"))], id: \.0) { item in
                    HStack(spacing: 5) { Circle().fill(item.1).frame(width: 6, height: 6); Text(item.0).font(.system(size: 11)).foregroundColor(.white.opacity(0.38)) }
                }
                Spacer()
            }.padding(.top, 4)
        }
        .padding(16).background(Color(hex: "16213E")).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Task Row
struct TaskRow: View {
    let task: RenovaTask
    @ObservedObject var vm: CalendarViewModel

    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(task.statusColor).frame(width: 4).cornerRadius(2)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title).font(.system(size: 14, weight: .medium))
                        .foregroundColor(task.status == "done" ? .white.opacity(0.38) : Color(hex: "F5EFE6")).strikethrough(task.status == "done")
                    HStack(spacing: 4) {
                        Image(systemName: "clock").font(.system(size: 10)).foregroundColor(.white.opacity(0.3))
                        Text(task.date.formatted(date: .omitted, time: .shortened)).font(.system(size: 11)).foregroundColor(.white.opacity(0.38))
                    }
                    if !task.notes.isEmpty { Text(task.notes).font(.system(size: 11)).foregroundColor(.white.opacity(0.35)).lineLimit(1) }
                }
                Spacer()
                Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) { vm.toggleDone(task) } } label: {
                    Image(systemName: task.status == "done" ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24)).foregroundColor(task.status == "done" ? Color(hex: "4CAF84") : .white.opacity(0.25))
                }.buttonStyle(SpringButtonStyle())
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
        }
        .background(Color(hex: "16213E")).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.065), lineWidth: 1))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { vm.delete(task) } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

// MARK: - Upcoming Task Row
struct UpcomingTaskRow: View {
    let task: RenovaTask
    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(task.statusColor.opacity(0.2)).frame(width: 36, height: 36)
                .overlay(Image(systemName: task.status == "urgent" ? "exclamationmark" : "clock").font(.system(size: 13, weight: .bold)).foregroundColor(task.statusColor))
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title).font(.system(size: 13, weight: .medium)).foregroundColor(Color(hex: "F5EFE6"))
                Text(task.date.formatted(.dateTime.weekday(.short).month(.abbreviated).day().hour().minute())).font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            let days = Calendar.current.dateComponents([.day], from: Date(), to: task.date).day ?? 0
            Text(days == 0 ? "Today" : days == 1 ? "Tomorrow" : "in \(days)d")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(days <= 1 ? Color(hex: "F0A500") : .white.opacity(0.35))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(days <= 1 ? Color(hex: "F0A500").opacity(0.12) : Color.white.opacity(0.05))
                .cornerRadius(8)
        }
        .padding(12).background(Color(hex: "16213E")).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Add Task Sheet
struct AddTaskSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: CalendarViewModel
    var defaultDate: Date

    @State private var title = ""
    @State private var date: Date
    @State private var status = "planned"
    @State private var notes = ""

    init(vm: CalendarViewModel, defaultDate: Date) {
        self.vm = vm; self.defaultDate = defaultDate
        _date = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1A2E").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        FormField(title: "Task Title *", placeholder: "e.g., Tile delivery, Inspect walls", text: $title)

                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Date & Time")
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact).tint(Color(hex: "E07B54")).labelsHidden()
                                .padding(14).background(Color(hex: "16213E")).cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel("Priority")
                            HStack(spacing: 8) {
                                ForEach([("planned","Planned",Color(hex: "6B9EFF")),("urgent","Urgent",Color(hex: "E05454")),("done","Done",Color(hex: "4CAF84"))], id: \.0) { val, label, color in
                                    Button { withAnimation { status = val } } label: {
                                        HStack(spacing: 5) { Circle().fill(color).frame(width: 7, height: 7); Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(status == val ? .white : .white.opacity(0.5)) }
                                        .padding(.horizontal, 14).padding(.vertical, 9)
                                        .background(status == val ? color.opacity(0.25) : Color(hex: "16213E")).cornerRadius(20)
                                        .overlay(Capsule().stroke(status == val ? color.opacity(0.5) : Color.white.opacity(0.07), lineWidth: 1))
                                    }.buttonStyle(SpringButtonStyle())
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 7) {
                            SectionLabel("Notes (optional)")
                            TextField("Any notes or details...", text: $notes, axis: .vertical)
                                .foregroundColor(Color(hex: "F5EFE6")).tint(Color(hex: "E07B54")).padding(14)
                                .background(Color(hex: "16213E")).cornerRadius(12).lineLimit(3...5)
                        }

                        Button("Add Task") {
                            vm.addTask(title: title, date: date, status: status, notes: notes)
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(title.isEmpty ? Color.gray.opacity(0.3) : Color(hex: "E07B54"))
                        .cornerRadius(16)
                        .shadow(color: title.isEmpty ? .clear : Color(hex: "E07B54").opacity(0.4), radius: 12, y: 6)
                        .buttonStyle(SpringButtonStyle()).disabled(title.isEmpty)
                    }
                    .padding(20).padding(.bottom, 40)
                }
            }
            .navigationTitle("New Task").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Color(hex: "E07B54")) } }
        }
    }
}
