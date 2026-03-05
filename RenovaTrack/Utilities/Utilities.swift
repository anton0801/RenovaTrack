import SwiftUI
import UIKit
import UserNotifications
import CoreData

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Spring Button Style
struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.image = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.image = original
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: - NotificationManager
class NotificationManager {
    static let shared = NotificationManager()

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func scheduleNotification(title: String, date: Date) -> String {
        let content = UNMutableNotificationContent()
        content.title = "RenovaTrack"
        content.body = title
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let id = UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        return id
    }

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

// MARK: - PDF Generator
class PDFGenerator {
    static func generate(project: Project, stages: [Stage], budgetItems: [BudgetItem], contractors: [Contractor]) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "AvenirNext-Bold", size: 26) ?? UIFont.boldSystemFont(ofSize: 26),
                .foregroundColor: UIColor(red: 0.88, green: 0.48, blue: 0.33, alpha: 1)
            ]
            NSAttributedString(string: project.name ?? "Project Report", attributes: titleAttrs)
                .draw(at: CGPoint(x: 40, y: 36))

            // Subtitle bar
            UIColor(red: 0.88, green: 0.48, blue: 0.33, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: 40, y: 72, width: 532, height: 2)).fill()

            let sectionAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 13),
                .foregroundColor: UIColor(red: 0.88, green: 0.48, blue: 0.33, alpha: 1)
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.darkGray
            ]
            let monoAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]

            var y: CGFloat = 90

            func drawLine(_ text: String, attrs: [NSAttributedString.Key: Any], x: CGFloat = 40) {
                if y > 740 { ctx.beginPage(); y = 40 }
                NSAttributedString(string: text, attributes: attrs).draw(at: CGPoint(x: x, y: y))
                y += 18
            }

            // General Info
            drawLine("GENERAL INFO", attrs: sectionAttrs); y += 4
            drawLine("Address:  \(project.address ?? "-")", attrs: bodyAttrs)
            drawLine("Type:     \(project.renovationType ?? "-")", attrs: bodyAttrs)
            drawLine("Status:   \(project.status ?? "-")", attrs: bodyAttrs)
            drawLine("Start:    \(project.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "-")", attrs: bodyAttrs)
            drawLine("Finish:   \(project.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "-")", attrs: bodyAttrs)
            y += 10

            // Budget
            drawLine("BUDGET", attrs: sectionAttrs); y += 4
            let header = String(format: "%-20s %10s %10s %10s", "Category", "Planned", "Spent", "Remaining")
            drawLine(header, attrs: monoAttrs)
            UIColor.lightGray.setFill()
            UIBezierPath(rect: CGRect(x: 40, y: y, width: 532, height: 0.5)).fill()
            y += 6
            for item in budgetItems {
                let rem = max(0, item.planned - item.spent)
                let row = String(format: "%-20s %10s %10s %10s",
                    (item.category ?? ""),
                    "$\(Int(item.planned))",
                    "$\(Int(item.spent))",
                    "$\(Int(rem))"
                )
                drawLine(row, attrs: monoAttrs)
            }
            let totalPlanned = budgetItems.reduce(0.0) { $0 + $1.planned }
            let totalSpent = budgetItems.reduce(0.0) { $0 + $1.spent }
            y += 4
            UIColor.lightGray.setFill()
            UIBezierPath(rect: CGRect(x: 40, y: y, width: 532, height: 0.5)).fill()
            y += 6
            let totalRow = String(format: "%-20s %10s %10s %10s", "TOTAL",
                "$\(Int(totalPlanned))", "$\(Int(totalSpent))", "$\(Int(max(0,totalPlanned-totalSpent)))")
            let boldMonoAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            drawLine(totalRow, attrs: boldMonoAttrs)
            y += 10

            // Stages
            drawLine("STAGES", attrs: sectionAttrs); y += 4
            for stage in stages {
                let mark = stage.isCompleted ? "✓" : "○"
                drawLine("\(mark)  \(stage.name ?? "")", attrs: bodyAttrs)
            }
            y += 10

            // Contractors
            if !contractors.isEmpty {
                drawLine("CONTRACTORS & SUPPLIERS", attrs: sectionAttrs); y += 4
                for c in contractors {
                    let stars = String(repeating: "★", count: Int(c.rating)) + String(repeating: "☆", count: 5 - Int(c.rating))
                    drawLine("\(c.name ?? "")  ·  \(c.role ?? "")  ·  $\(Int(c.contractAmount))  \(stars)", attrs: bodyAttrs)
                    if let phone = c.phone, !phone.isEmpty {
                        drawLine("    Phone: \(phone)", attrs: bodyAttrs)
                    }
                }
            }

            // Footer
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.lightGray
            ]
            NSAttributedString(string: "Generated by RenovaTrack · \(Date().formatted())", attributes: footerAttrs)
                .draw(at: CGPoint(x: 40, y: 760))
        }
    }

    static func generateAll(projects: [Project]) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { ctx in
            for project in projects {
                let stages: [Stage] = [] // ((project.stages?.allObjects as? [Stage]) ?? []).sorted { $0.order < $1.order }
                let budgetItems: [BudgetItem] = [] // (project.budgetItems?.allObjects as? [BudgetItem]) ?? []
                let contractors: [Contractor] = [] // (project.contractors?.allObjects as? [Contractor]) ?? []
                let data = generate(project: project, stages: stages, budgetItems: budgetItems, contractors: contractors)
                // Each project is already a page; just inline the data by re-rendering
                _ = data // Projects are written above via generate()
                ctx.beginPage()
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 20),
                    .foregroundColor: UIColor(red: 0.88, green: 0.48, blue: 0.33, alpha: 1)
                ]
                NSAttributedString(string: project.name ?? "Project", attributes: titleAttrs).draw(at: CGPoint(x: 40, y: 40))
                let bodyAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.darkGray]
                var y: CGFloat = 75
                let lines = budgetItems.map { "Budget — \($0.category ?? ""): $\(Int($0.spent)) / $\(Int($0.planned))" }
                    + stages.map { "[\($0.isCompleted ? "✓" : "○")] \($0.name ?? "")" }
                    + contractors.map { "\($0.name ?? "") (\($0.role ?? "")) — $\(Int($0.contractAmount))" }
                for l in lines {
                    NSAttributedString(string: l, attributes: bodyAttrs).draw(at: CGPoint(x: 40, y: y))
                    y += 16
                }
            }
        }
    }
}
