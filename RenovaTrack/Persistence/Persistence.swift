import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    // MARK: - Preview
    static var preview: PersistenceController = {
        let ctrl = PersistenceController(inMemory: true)
        let ctx = ctrl.container.viewContext
        let p = Project(context: ctx)
        p.id = UUID(); p.name = "Kitchen Renovation"; p.address = "123 Main St"
        p.areaSqM = 24; p.renovationType = "Kitchen"
        p.status = ProjectStatus.inProgress.rawValue
        p.startDate = Date()
        p.endDate = Date().addingTimeInterval(60*60*24*60)
        p.totalBudget = 18000; p.createdAt = Date()
        for (i, t) in AppSettings.shared.stageTemplates.enumerated() {
            let s = Stage(context: ctx)
            s.id = UUID(); s.name = t.name; s.isCompleted = i < 2
            s.order = Int16(i); s.project = p
        }
        for (cat, pl, sp) in [("Materials", 6000.0, 5200.0),
                               ("Labor",     8000.0, 4000.0),
                               ("Permits",    500.0,  500.0)] {
            let b = BudgetItem(context: ctx)
            b.id = UUID(); b.category = cat; b.planned = pl; b.spent = sp; b.project = p
        }
        try? ctx.save()
        return ctrl
    }()

    // MARK: - Container
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RenovaTrack")

        if inMemory {
            container.persistentStoreDescriptions.first?.url =
                URL(fileURLWithPath: "/dev/null")
        } else {
            // Lightweight migration handles added/removed optional attributes
            // without requiring a manual mapping model
            let desc = container.persistentStoreDescriptions.first
            desc?.shouldMigrateStoreAutomatically    = true
            desc?.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { [self] _, error in
            if let error = error as NSError? {
                destroyAndRecreate()
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save
    func save() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            print("❌ Core Data save error: \(error)")
            ctx.rollback()
        }
    }

    // MARK: - Nuclear reset (last resort)
    private func destroyAndRecreate() {
        guard let url = container.persistentStoreDescriptions.first?.url else { return }
        let coord = container.persistentStoreCoordinator
        try? coord.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType)
        try? coord.addPersistentStore(ofType: NSSQLiteStoreType,
                                      configurationName: nil,
                                      at: url,
                                      options: [
                                          NSMigratePersistentStoresAutomaticallyOption: true,
                                          NSInferMappingModelAutomaticallyOption: true
                                      ])
    }
}
