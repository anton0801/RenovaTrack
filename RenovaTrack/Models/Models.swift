import Foundation
import SwiftUI

// MARK: - Project Status
enum ProjectStatus: String, CaseIterable, Codable {
    case inProgress = "InProgress"
    case completed  = "Completed"
    case onHold     = "OnHold"

    var displayName: String {
        switch self {
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .onHold:     return "On Hold"
        }
    }
}

// MARK: - Data Models (all Codable, no Core Data)

struct RenovaProject: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var address: String
    var areaSqM: Double
    var renovationType: String
    var status: ProjectStatus
    var startDate: Date
    var endDate: Date
    var totalBudget: Double
    var coverPhotoData: Data?
    var createdAt: Date = Date()
    var stages: [RenovaStage]
    var budgetItems: [RenovaBudgetItem]
    var contractors: [RenovaContractor]

    var progress: Double {
        guard !stages.isEmpty else { return 0 }
        return Double(stages.filter { $0.isCompleted }.count) / Double(stages.count)
    }

    var spentBudget: Double {
        budgetItems.reduce(0) { $0 + $1.spent }
    }

    var daysRemaining: Int? {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day
    }
}

struct RenovaStage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var isCompleted: Bool = false
    var order: Int
}

struct RenovaBudgetItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var category: String
    var planned: Double
    var spent: Double
}

struct RenovaContractor: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var phone: String
    var role: String
    var contractAmount: Double
    var rating: Int
}

struct RenovaTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var status: String   // "planned" | "urgent" | "done"
    var notes: String
    var notificationID: String?

    var statusColor: Color {
        switch status {
        case "urgent": return Color(hex: "E05454")
        case "done":   return Color(hex: "4CAF84")
        default:       return Color(hex: "6B9EFF")
        }
    }
}

struct RenovaPhoto: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var projectID: UUID
    var imageData: Data
    var timestamp: Date = Date()
    var stageName: String
    var note: String
    var isBeforePhoto: Bool
}

// MARK: - Stage Template
struct StageTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var checklistItems: [String]

    static var defaultTemplates: [StageTemplate] {
        [
            StageTemplate(id: UUID(), name: "Demolition", checklistItems: [
                "Remove old flooring","Remove old fixtures","Tear down walls (if needed)",
                "Haul debris","Inspect subfloor","Check for mold or water damage"
            ]),
            StageTemplate(id: UUID(), name: "Rough-in", checklistItems: [
                "Frame new walls","Install insulation","Rough plumbing layout",
                "Rough electrical layout","HVAC ductwork","Inspector approval"
            ]),
            StageTemplate(id: UUID(), name: "Electrical", checklistItems: [
                "Install outlets & switches","Panel work","Light fixture rough-in",
                "Ground fault circuit interrupters (GFCI)","Smoke & CO detectors","Electrical inspection"
            ]),
            StageTemplate(id: UUID(), name: "Plumbing", checklistItems: [
                "Install supply pipes","Install drain pipes","Water heater connection",
                "Fixture rough-in","Pressure test","Plumbing inspection"
            ]),
            StageTemplate(id: UUID(), name: "Finishing", checklistItems: [
                "Hang & tape drywall","Prime walls","Paint walls & ceiling",
                "Install flooring","Install trim & molding","Install doors & hardware","Final paint touch-ups"
            ]),
            StageTemplate(id: UUID(), name: "Furniture & Decor", checklistItems: [
                "Assemble & place furniture","Hang artwork & mirrors","Install window treatments",
                "Place lighting fixtures","Accessorize & style","Final walkthrough & punch list"
            ])
        ]
    }
}

// MARK: - App Settings
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var useMetricUnits: Bool {
        didSet { UserDefaults.standard.set(useMetricUnits, forKey: "useMetricUnits") }
    }
    @Published var stageTemplates: [StageTemplate] {
        didSet { save(stageTemplates, key: "stageTemplates") }
    }

    init() {
        self.useMetricUnits = UserDefaults.standard.bool(forKey: "useMetricUnits")
        if let data = UserDefaults.standard.data(forKey: "stageTemplates"),
           let v = try? JSONDecoder().decode([StageTemplate].self, from: data) {
            self.stageTemplates = v
        } else {
            self.stageTemplates = StageTemplate.defaultTemplates
        }
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
