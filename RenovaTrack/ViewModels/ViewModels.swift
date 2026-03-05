import Foundation
import SwiftUI
import Combine

// MARK: - DataStore (replaces Core Data + PersistenceController)

class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var projects: [RenovaProject] = []
    @Published var tasks:    [RenovaTask]    = []
    @Published var photos:   [RenovaPhoto]   = []

    private let projectsKey = "renovatrack.projects"
    private let tasksKey    = "renovatrack.tasks"
    private let photosKey   = "renovatrack.photos"

    init() { load() }

    // MARK: - Load
    func load() {
        projects = decode(key: projectsKey) ?? []
        tasks    = decode(key: tasksKey)    ?? []
        photos   = decode(key: photosKey)   ?? []
    }

    // MARK: - Save
    func save() {
        encode(projects, key: projectsKey)
        encode(tasks,    key: tasksKey)
        encode(photos,   key: photosKey)
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func decode<T: Decodable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Projects
    func addProject(_ project: RenovaProject) {
        projects.insert(project, at: 0)
        save()
    }

    func updateProject(_ project: RenovaProject) {
        if let i = projects.firstIndex(where: { $0.id == project.id }) {
            projects[i] = project
            save()
        }
    }

    func deleteProject(id: UUID) {
        projects.removeAll { $0.id == id }
        photos.removeAll   { $0.projectID == id }
        save()
    }

    // MARK: - Tasks
    func addTask(_ task: RenovaTask) {
        tasks.append(task)
        tasks.sort { $0.date < $1.date }
        save()
    }

    func updateTask(_ task: RenovaTask) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[i] = task
            save()
        }
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        save()
    }

    // MARK: - Photos
    func addPhoto(_ photo: RenovaPhoto) {
        photos.insert(photo, at: 0)
        save()
    }

    func deletePhoto(id: UUID) {
        photos.removeAll { $0.id == id }
        save()
    }

    // MARK: - Nuke all data
    func clearAll() {
        projects = []; tasks = []; photos = []
        [projectsKey, tasksKey, photosKey].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }
}

// MARK: - ProjectsViewModel
class ProjectsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var filterStatus: ProjectStatus? = nil

    private let store: DataStore

    init(store: DataStore = .shared) {
        self.store = store
    }

    var filteredProjects: [RenovaProject] {
        var list = store.projects
        if let s = filterStatus { list = list.filter { $0.status == s } }
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText) ||
                $0.renovationType.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    func addProject(name: String, address: String, areaSqM: Double, renovationType: String,
                    status: ProjectStatus, startDate: Date, endDate: Date,
                    totalBudget: Double, coverPhoto: Data?) {
        let stages = AppSettings.shared.stageTemplates.enumerated().map {
            RenovaStage(name: $1.name, order: $0)
        }
        let budget = ["Materials","Labor","Permits","Furniture","Other"].map {
            RenovaBudgetItem(category: $0, planned: 0, spent: 0)
        }
        let project = RenovaProject(
            name: name, address: address, areaSqM: areaSqM,
            renovationType: renovationType, status: status,
            startDate: startDate, endDate: endDate,
            totalBudget: totalBudget, coverPhotoData: coverPhoto,
            stages: stages, budgetItems: budget, contractors: []
        )
        store.addProject(project)
    }

    func update(_ project: RenovaProject) { store.updateProject(project) }
    func delete(id: UUID)                 { store.deleteProject(id: id) }
}

// MARK: - CalendarViewModel
class CalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()

    private let store: DataStore
    let notificationManager = NotificationManager.shared

    init(store: DataStore = .shared) { self.store = store }

    var tasks: [RenovaTask] { store.tasks }

    var tasksForSelectedDate: [RenovaTask] {
        store.tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    func dotColors(for date: Date) -> [Color] {
        store.tasks
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .map { $0.statusColor }
    }

    func addTask(title: String, date: Date, status: String, notes: String = "") {
        let notifID = notificationManager.scheduleNotification(title: title, date: date)
        let task = RenovaTask(title: title, date: date, status: status,
                              notes: notes, notificationID: notifID)
        store.addTask(task)
    }

    func toggleDone(_ task: RenovaTask) {
        var t = task
        t.status = t.status == "done" ? "planned" : "done"
        store.updateTask(t)
    }

    func delete(_ task: RenovaTask) {
        if let nid = task.notificationID {
            notificationManager.cancelNotification(id: nid)
        }
        store.deleteTask(id: task.id)
    }
}

// MARK: - PhotoLogViewModel
class PhotoLogViewModel: ObservableObject {
    @Published var viewMode: ViewMode = .grid
    @Published var filterProjectID: UUID? = nil

    enum ViewMode { case grid, list }

    private let store: DataStore
    init(store: DataStore = .shared) { self.store = store }

    var filtered: [RenovaPhoto] {
        guard let pid = filterProjectID else { return store.photos }
        return store.photos.filter { $0.projectID == pid }
    }

    func addPhoto(data: Data, stageName: String, note: String, isBefore: Bool, projectID: UUID) {
        let photo = RenovaPhoto(projectID: projectID, imageData: data,
                                stageName: stageName, note: note, isBeforePhoto: isBefore)
        store.addPhoto(photo)
    }

    func delete(_ photo: RenovaPhoto) {
        store.deletePhoto(id: photo.id)
    }
}
