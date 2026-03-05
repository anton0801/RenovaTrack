import Foundation
import CoreData

// MARK: - NSSet/NSOrderedSet → typed Array (safe for both)
private func cdArray<T: NSManagedObject>(_ value: Any?) -> [T] {
    switch value {
    case let o as NSOrderedSet: return o.array.compactMap { $0 as? T }
    case let s as NSSet:        return s.allObjects.compactMap { $0 as? T }
    default:                    return []
    }
}

// MARK: - Project
@objc(Project) public class Project: NSManagedObject {}
extension Project {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Project> {
        NSFetchRequest<Project>(entityName: "Project")
    }
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var address: String?
    @NSManaged public var areaSqM: Double
    @NSManaged public var renovationType: String?
    @NSManaged public var status: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var totalBudget: Double
    @NSManaged public var coverPhotoData: Data?
    @NSManaged public var createdAt: Date?
    @NSManaged public var stages: NSObject?
    @NSManaged public var budgetItems: NSObject?
    @NSManaged public var contractors: NSObject?
    @NSManaged public var photos: NSObject?

    var stagesArray: [Stage] {
        cdArray(stages).sorted { $0.order < $1.order }
    }
    var budgetItemsArray: [BudgetItem] {
        cdArray(budgetItems).sorted { ($0.category ?? "") < ($1.category ?? "") }
    }
    var contractorsArray: [Contractor] {
        cdArray(contractors).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    var photosArray: [ProjectPhoto] {
        cdArray(photos).sorted { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }
    }
}
extension Project: Identifiable {}

// MARK: - Stage
@objc(Stage) public class Stage: NSManagedObject {}
extension Stage {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Stage> {
        NSFetchRequest<Stage>(entityName: "Stage")
    }
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var order: Int16
    @NSManaged public var project: Project?
}
extension Stage: Identifiable {}

// MARK: - BudgetItem
@objc(BudgetItem) public class BudgetItem: NSManagedObject {}
extension BudgetItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BudgetItem> {
        NSFetchRequest<BudgetItem>(entityName: "BudgetItem")
    }
    @NSManaged public var id: UUID?
    @NSManaged public var category: String?
    @NSManaged public var planned: Double
    @NSManaged public var spent: Double
    @NSManaged public var project: Project?
}
extension BudgetItem: Identifiable {}

// MARK: - Contractor
@objc(Contractor) public class Contractor: NSManagedObject {}
extension Contractor {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Contractor> {
        NSFetchRequest<Contractor>(entityName: "Contractor")
    }
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var phone: String?
    @NSManaged public var role: String?
    @NSManaged public var contractAmount: Double
    @NSManaged public var rating: Int16
    @NSManaged public var project: Project?
}
extension Contractor: Identifiable {}

// MARK: - CalendarTask
// NOTE: 'notes' and 'notificationID' use KVC accessors instead of @NSManaged
// to avoid crashes when the on-disk SQLite store was created before these
// attributes were added to the model (lightweight migration adds them as NULL).
@objc(CalendarTask) public class CalendarTask: NSManagedObject {}
extension CalendarTask {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CalendarTask> {
        NSFetchRequest<CalendarTask>(entityName: "CalendarTask")
    }
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var date: Date?
    @NSManaged public var status: String?

    /// Safe KVC accessor – survives missing attribute in old store
    var notes: String {
        get { (value(forKey: "notes") as? String) ?? "" }
        set { setValue(newValue.isEmpty ? nil : newValue, forKey: "notes") }
    }
    var notificationID: String? {
        get { value(forKey: "notificationID") as? String }
        set { setValue(newValue, forKey: "notificationID") }
    }
}
extension CalendarTask: Identifiable {}

// MARK: - ProjectPhoto
// Same pattern: imageData, stageName, note, isBeforePhoto use KVC
@objc(ProjectPhoto) public class ProjectPhoto: NSManagedObject {}
extension ProjectPhoto {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProjectPhoto> {
        NSFetchRequest<ProjectPhoto>(entityName: "ProjectPhoto")
    }
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var project: Project?

    var imageData: Data? {
        get { value(forKey: "imageData") as? Data }
        set { setValue(newValue, forKey: "imageData") }
    }
    var stageName: String? {
        get { value(forKey: "stageName") as? String }
        set { setValue(newValue, forKey: "stageName") }
    }
    var note: String? {
        get { value(forKey: "note") as? String }
        set { setValue(newValue, forKey: "note") }
    }
    var isBeforePhoto: Bool {
        get { (value(forKey: "isBeforePhoto") as? Bool) ?? false }
        set { setValue(newValue, forKey: "isBeforePhoto") }
    }
}
extension ProjectPhoto: Identifiable {}
