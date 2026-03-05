import SwiftUI

struct PhotoLogView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = PhotoLogViewModel()
    @State private var showAddPhoto = false
    @State private var selectedPhoto: RenovaPhoto? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1A2E").ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Photo Log").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundColor(Color(hex: "F5EFE6"))
                            Text("\(store.photos.count) photo\(store.photos.count == 1 ? "" : "s") captured").font(.system(size: 14)).foregroundColor(.white.opacity(0.45))
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            Button { withAnimation { vm.viewMode = vm.viewMode == .grid ? .list : .grid } } label: {
                                Image(systemName: vm.viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                                    .font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.6))
                                    .frame(width: 38, height: 38).background(Color(hex: "16213E")).cornerRadius(10)
                            }.buttonStyle(SpringButtonStyle())
                            Button { showAddPhoto = true } label: {
                                ZStack {
                                    Circle().fill(Color(hex: "E07B54").opacity(0.15)).frame(width: 44, height: 44)
                                    Image(systemName: "camera.fill").font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: "E07B54"))
                                }
                            }.buttonStyle(SpringButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)

                    // Project filter
                    if !store.projects.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(label: "All Projects", isSelected: vm.filterProjectID == nil) { vm.filterProjectID = nil }
                                ForEach(store.projects) { p in
                                    FilterChip(label: p.name, isSelected: vm.filterProjectID == p.id) { vm.filterProjectID = p.id }
                                }
                            }.padding(.horizontal, 20)
                        }.padding(.bottom, 12)
                    }

                    if vm.filtered.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "camera.fill").font(.system(size: 48)).foregroundColor(.white.opacity(0.1))
                            Text("No Photos Yet").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(Color(hex: "F5EFE6"))
                            Text("Tap the camera button to\nadd your first photo.").font(.system(size: 15)).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
                            Spacer()
                        }
                    } else if vm.viewMode == .grid {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 3), GridItem(.flexible(), spacing: 3), GridItem(.flexible(), spacing: 3)], spacing: 3) {
                                ForEach(vm.filtered) { photo in
                                    PhotoGridCell(photo: photo)
                                        .onTapGesture { selectedPhoto = photo }
                                        .contextMenu { Button(role: .destructive) { vm.delete(photo) } label: { Label("Delete", systemImage: "trash") } }
                                }
                            }
                            .padding(.bottom, 120)
                        }
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(vm.filtered) { photo in
                                    PhotoListRow(photo: photo, projectName: store.projects.first { $0.id == photo.projectID }?.name ?? "Unknown")
                                        .onTapGesture { selectedPhoto = photo }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) { vm.delete(photo) } label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }
                            .padding(.horizontal, 20).padding(.bottom, 120)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddPhoto) {
            AddPhotoSheet(vm: vm, projects: store.projects)
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
        }
    }
}

// MARK: - Grid Cell
struct PhotoGridCell: View {
    let photo: RenovaPhoto
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let img = UIImage(data: photo.imageData) {
                Image(uiImage: img).resizable().scaledToFill().frame(minWidth: 0, maxWidth: .infinity).aspectRatio(1, contentMode: .fill).clipped()
            } else {
                Color(hex: "16213E").aspectRatio(1, contentMode: .fill)
            }
            Text(photo.isBeforePhoto ? "B" : "A")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 3)
                .background(photo.isBeforePhoto ? Color.black.opacity(0.65) : Color(hex: "4CAF84").opacity(0.9))
                .cornerRadius(5).padding(4)
        }
        .clipShape(Rectangle())
    }
}

// MARK: - List Row
struct PhotoListRow: View {
    let photo: RenovaPhoto
    let projectName: String
    var body: some View {
        HStack(spacing: 14) {
            if let img = UIImage(data: photo.imageData) {
                Image(uiImage: img).resizable().scaledToFill().frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10).fill(Color(hex: "16213E")).frame(width: 72, height: 72)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(photo.stageName.isEmpty ? "No Stage" : photo.stageName).font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: "F5EFE6"))
                    Text(photo.isBeforePhoto ? "Before" : "After").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(photo.isBeforePhoto ? Color.gray.opacity(0.4) : Color(hex: "4CAF84").opacity(0.7)).cornerRadius(6)
                }
                Text(projectName).font(.system(size: 12)).foregroundColor(Color(hex: "E07B54"))
                if !photo.note.isEmpty { Text(photo.note).font(.system(size: 12)).foregroundColor(.white.opacity(0.45)).lineLimit(1) }
                Text(photo.timestamp.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 11)).foregroundColor(.white.opacity(0.3))
            }
            Spacer()
        }
        .padding(12).background(Color(hex: "16213E")).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Photo Detail
struct PhotoDetailView: View {
    @Environment(\.dismiss) var dismiss
    let photo: RenovaPhoto
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let img = UIImage(data: photo.imageData) {
                Image(uiImage: img).resizable().scaledToFit()
            }
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundColor(.white.opacity(0.8))
                    }.padding(20)
                }
                Spacer()
                if !photo.note.isEmpty || !photo.stageName.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        if !photo.stageName.isEmpty { Text(photo.stageName).font(.system(size: 15, weight: .bold)).foregroundColor(.white) }
                        if !photo.note.isEmpty { Text(photo.note).font(.system(size: 13)).foregroundColor(.white.opacity(0.75)) }
                        Text(photo.timestamp.formatted(date: .long, time: .shortened)).font(.system(size: 11)).foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                    .background(.black.opacity(0.55)).cornerRadius(12).padding()
                }
            }
        }
    }
}

// MARK: - Add Photo Sheet
struct AddPhotoSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: PhotoLogViewModel
    let projects: [RenovaProject]

    @State private var selectedProjectID: UUID?
    @State private var stageName = ""
    @State private var note = ""
    @State private var isBefore = true
    @State private var selectedImage: UIImage?
    @State private var showPicker = false

    var stageNames: [String] { AppSettings.shared.stageTemplates.map { $0.name } }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1A2E").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Image picker
                        Button { showPicker = true } label: {
                            ZStack {
                                if let img = selectedImage {
                                    Image(uiImage: img).resizable().scaledToFill().frame(height: 200).clipped()
                                        .overlay(LinearGradient(colors: [.clear, Color(hex: "1A1A2E").opacity(0.4)], startPoint: .top, endPoint: .bottom))
                                } else {
                                    ZStack {
                                        Color(hex: "16213E").frame(height: 200)
                                        VStack(spacing: 10) {
                                            Image(systemName: "photo.badge.plus").font(.system(size: 36)).foregroundColor(.white.opacity(0.2))
                                            Text("Tap to select photo").font(.system(size: 14)).foregroundColor(.white.opacity(0.3))
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 200).cornerRadius(16).buttonStyle(SpringButtonStyle())

                        // Project picker
                        if !projects.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionLabel("Project")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(projects) { p in
                                            Button { selectedProjectID = p.id } label: {
                                                Text(p.name).font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(selectedProjectID == p.id ? Color(hex: "1A1A2E") : .white.opacity(0.6))
                                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                                    .background(selectedProjectID == p.id ? Color(hex: "E07B54") : Color(hex: "16213E"))
                                                    .cornerRadius(20)
                                                    .overlay(Capsule().stroke(Color.white.opacity(selectedProjectID == p.id ? 0 : 0.08), lineWidth: 1))
                                            }.buttonStyle(SpringButtonStyle())
                                        }
                                    }
                                }
                            }
                        }

                        // Stage
                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Stage")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(stageNames, id: \.self) { s in
                                        Button { stageName = s } label: {
                                            Text(s).font(.system(size: 13, weight: .medium))
                                                .foregroundColor(stageName == s ? Color(hex: "1A1A2E") : .white.opacity(0.6))
                                                .padding(.horizontal, 14).padding(.vertical, 8)
                                                .background(stageName == s ? Color(hex: "C9A84C") : Color(hex: "16213E"))
                                                .cornerRadius(20)
                                                .overlay(Capsule().stroke(Color.white.opacity(stageName == s ? 0 : 0.08), lineWidth: 1))
                                        }.buttonStyle(SpringButtonStyle())
                                    }
                                }
                            }
                        }

                        // Before / After
                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Photo Type")
                            HStack(spacing: 10) {
                                ForEach([(true, "Before"), (false, "After")], id: \.1) { val, label in
                                    Button { isBefore = val } label: {
                                        Text(label).font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(isBefore == val ? .white : .white.opacity(0.5))
                                            .frame(maxWidth: .infinity).frame(height: 44)
                                            .background(isBefore == val ? Color(hex: "E07B54").opacity(0.35) : Color(hex: "16213E"))
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isBefore == val ? Color(hex: "E07B54").opacity(0.6) : Color.white.opacity(0.07), lineWidth: 1))
                                    }.buttonStyle(SpringButtonStyle())
                                }
                            }
                        }

                        FormField(title: "Note (optional)", placeholder: "Describe what's shown...", text: $note)

                        Button("Save Photo") {
                            guard let img = selectedImage, let data = img.jpegData(compressionQuality: 0.8) else { return }
                            let pid = selectedProjectID ?? projects.first?.id ?? UUID()
                            vm.addPhoto(data: data, stageName: stageName, note: note, isBefore: isBefore, projectID: pid)
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(selectedImage == nil ? Color.gray.opacity(0.3) : Color(hex: "E07B54"))
                        .cornerRadius(16)
                        .shadow(color: selectedImage == nil ? .clear : Color(hex: "E07B54").opacity(0.4), radius: 12, y: 6)
                        .buttonStyle(SpringButtonStyle()).disabled(selectedImage == nil)
                    }
                    .padding(20).padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Photo").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(Color(hex: "E07B54")) } }
        }
        .sheet(isPresented: $showPicker) { ImagePicker(image: $selectedImage) }
        .onAppear { selectedProjectID = projects.first?.id }
    }
}
