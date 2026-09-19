import SwiftUI
import Foundation

enum HyperWindowKind: String, CaseIterable {
    case files
    case browser
    case settings
    case about

    var title: String {
        switch self {
        case .files: return "File Explorer"
        case .browser: return "Browser"
        case .settings: return "Settings"
        case .about: return "About HyperDroid"
        }
    }

    var symbol: String {
        switch self {
        case .files: return "folder.fill"
        case .browser: return "globe"
        case .settings: return "gearshape.fill"
        case .about: return "info.circle.fill"
        }
    }
}

struct HyperWindow: Identifiable, Equatable {
    let id: UUID
    let kind: HyperWindowKind
    var position: CGPoint
    var size: CGSize
    var zIndex: Int

    init(kind: HyperWindowKind, position: CGPoint, size: CGSize, zIndex: Int) {
        self.id = UUID()
        self.kind = kind
        self.position = position
        self.size = size
        self.zIndex = zIndex
    }
}

@MainActor
final class DesktopModel: ObservableObject {
    @Published var windows: [HyperWindow] = []
    @Published var startMenuPresented = false
    @Published var activeWindowID: UUID?

    private var nextZIndex = 1

    func open(_ kind: HyperWindowKind, in desktopSize: CGSize) {
        if let existing = windows.first(where: { $0.kind == kind }) {
            focus(existing.id)
            return
        }

        let width = min(max(desktopSize.width * 0.58, 520), 920)
        let height = min(max(desktopSize.height * 0.62, 380), 680)
        let stagger = CGFloat(windows.count % 5) * 26

        let window = HyperWindow(
            kind: kind,
            position: CGPoint(
                x: max(width / 2 + 20, desktopSize.width / 2 + stagger),
                y: max(height / 2 + 20, desktopSize.height / 2 - 22 + stagger)
            ),
            size: CGSize(width: width, height: height),
            zIndex: nextZIndex
        )

        nextZIndex += 1
        windows.append(window)
        activeWindowID = window.id
        startMenuPresented = false
    }

    func focus(_ id: UUID) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].zIndex = nextZIndex
        nextZIndex += 1
        activeWindowID = id
    }

    func close(_ id: UUID) {
        windows.removeAll { $0.id == id }
        activeWindowID = windows.max(by: { $0.zIndex < $1.zIndex })?.id
    }

    func move(_ id: UUID, to position: CGPoint) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].position = position
    }

    func resize(_ id: UUID, to size: CGSize) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].size = CGSize(
            width: max(360, size.width),
            height: max(260, size.height)
        )
    }
}

struct DesktopView: View {
    @StateObject private var model = DesktopModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DesktopWallpaper()

                desktopIcons(in: geometry.size)

                ForEach(model.windows.sorted(by: { $0.zIndex < $1.zIndex })) { window in
                    DesktopWindowView(
                        window: window,
                        isActive: model.activeWindowID == window.id,
                        onFocus: { model.focus(window.id) },
                        onClose: { model.close(window.id) },
                        onMove: { model.move(window.id, to: $0) },
                        onResize: { model.resize(window.id, to: $0) }
                    )
                    .zIndex(Double(window.zIndex))
                }

                if model.startMenuPresented {
                    StartMenu(
                        onOpen: { model.open($0, in: geometry.size) },
                        onDismiss: { model.startMenuPresented = false }
                    )
                    .transition(.scale(scale: 0.96, anchor: .bottom))
                    .zIndex(10_000)
                }

                VStack {
                    Spacer()
                    Taskbar(
                        windows: model.windows.sorted(by: { $0.zIndex < $1.zIndex }),
                        activeWindowID: model.activeWindowID,
                        startMenuPresented: model.startMenuPresented,
                        onStart: {
                            withAnimation(.easeOut(duration: 0.16)) {
                                model.startMenuPresented.toggle()
                            }
                        },
                        onOpen: { model.open($0, in: geometry.size) },
                        onWindowTap: { model.focus($0) }
                    )
                }
                .zIndex(20_000)
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                if model.startMenuPresented {
                    withAnimation(.easeOut(duration: 0.12)) {
                        model.startMenuPresented = false
                    }
                }
            }
        }
    }

    private func desktopIcons(in size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            DesktopIcon(title: "Files", symbol: "folder.fill") {
                model.open(.files, in: size)
            }

            DesktopIcon(title: "Browser", symbol: "globe") {
                model.open(.browser, in: size)
            }

            DesktopIcon(title: "Settings", symbol: "gearshape.fill") {
                model.open(.settings, in: size)
            }

            Spacer()
        }
        .padding(.top, 44)
        .padding(.leading, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct DesktopWallpaper: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.025, green: 0.08, blue: 0.18),
                    Color(red: 0.03, green: 0.28, blue: 0.52),
                    Color(red: 0.06, green: 0.12, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.cyan.opacity(0.18))
                .frame(width: 560, height: 560)
                .blur(radius: 90)
                .offset(x: 250, y: -110)

            Circle()
                .fill(Color.blue.opacity(0.16))
                .frame(width: 420, height: 420)
                .blur(radius: 70)
                .offset(x: -260, y: 180)
        }
    }
}

struct DesktopIcon: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 34, weight: .semibold))
                    .frame(width: 58, height: 58)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }
            .frame(width: 78)
        }
        .buttonStyle(.plain)
    }
}

struct DesktopWindowView: View {
    let window: HyperWindow
    let isActive: Bool
    let onFocus: () -> Void
    let onClose: () -> Void
    let onMove: (CGPoint) -> Void
    let onResize: (CGSize) -> Void

    @State private var dragTranslation: CGSize = .zero
    @State private var resizeTranslation: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            windowContent
        }
        .frame(
            width: window.size.width + resizeTranslation.width,
            height: window.size.height + resizeTranslation.height
        )
        .background(Color(red: 0.055, green: 0.065, blue: 0.085))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(isActive ? Color.white.opacity(0.28) : Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(isActive ? 0.44 : 0.27), radius: isActive ? 24 : 14, y: 8)
        .overlay(alignment: .bottomTrailing) {
            resizeHandle
        }
        .position(
            x: window.position.x + dragTranslation.width,
            y: window.position.y + dragTranslation.height
        )
        .onTapGesture(perform: onFocus)
    }

    private var titleBar: some View {
        HStack(spacing: 10) {
            Image(systemName: window.kind.symbol)
                .foregroundStyle(.white.opacity(0.9))

            Text(window.kind.title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 36, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color.red.opacity(0.001))
        }
        .padding(.leading, 12)
        .padding(.trailing, 5)
        .frame(height: 38)
        .background(isActive ? Color.white.opacity(0.095) : Color.white.opacity(0.055))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    onFocus()
                    dragTranslation = value.translation
                }
                .onEnded { value in
                    onMove(
                        CGPoint(
                            x: window.position.x + value.translation.width,
                            y: window.position.y + value.translation.height
                        )
                    )
                    dragTranslation = .zero
                }
        )
    }

    @ViewBuilder
    private var windowContent: some View {
        switch window.kind {
        case .files:
            FileExplorerPane()
        case .browser:
            BrowserPane()
        case .settings:
            SettingsPane()
        case .about:
            AboutPane()
        }
    }

    private var resizeHandle: some View {
        Image(systemName: "arrow.down.right.and.arrow.up.left")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white.opacity(0.35))
            .frame(width: 30, height: 30)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        resizeTranslation = CGSize(
                            width: max(360 - window.size.width, value.translation.width),
                            height: max(260 - window.size.height, value.translation.height)
                        )
                    }
                    .onEnded { value in
                        onResize(
                            CGSize(
                                width: window.size.width + value.translation.width,
                                height: window.size.height + value.translation.height
                            )
                        )
                        resizeTranslation = .zero
                    }
            )
    }
}

struct Taskbar: View {
    let windows: [HyperWindow]
    let activeWindowID: UUID?
    let startMenuPresented: Bool
    let onStart: () -> Void
    let onOpen: (HyperWindowKind) -> Void
    let onWindowTap: (UUID) -> Void

    var body: some View {
        HStack(spacing: 7) {
            TaskbarButton(symbol: "square.grid.2x2.fill", selected: startMenuPresented, action: onStart)

            TaskbarButton(symbol: "folder.fill", selected: windows.contains(where: { $0.kind == .files && $0.id == activeWindowID })) {
                if let window = windows.first(where: { $0.kind == .files }) {
                    onWindowTap(window.id)
                } else {
                    onOpen(.files)
                }
            }

            TaskbarButton(symbol: "globe", selected: windows.contains(where: { $0.kind == .browser && $0.id == activeWindowID })) {
                if let window = windows.first(where: { $0.kind == .browser }) {
                    onWindowTap(window.id)
                } else {
                    onOpen(.browser)
                }
            }

            TaskbarButton(symbol: "gearshape.fill", selected: windows.contains(where: { $0.kind == .settings && $0.id == activeWindowID })) {
                if let window = windows.first(where: { $0.kind == .settings }) {
                    onWindowTap(window.id)
                } else {
                    onOpen(.settings)
                }
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 1) {
                Text(Date.now, format: .dateTime.hour().minute())
                    .font(.system(size: 12, weight: .medium))
                Text(Date.now, format: .dateTime.day().month().year())
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 52)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider().opacity(0.4)
        }
    }
}

struct TaskbarButton: View {
    let symbol: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .semibold))
                .frame(width: 40, height: 38)
                .background(
                    selected ? Color.white.opacity(0.15) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 9)
                )
        }
        .buttonStyle(.plain)
    }
}

struct StartMenu: View {
    let onOpen: (HyperWindowKind) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("HyperDroid")
                    .font(.title3.bold())
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }

            TextField("Search apps", text: .constant(""))
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 12)], spacing: 16) {
                StartApp(kind: .files, onOpen: onOpen)
                StartApp(kind: .browser, onOpen: onOpen)
                StartApp(kind: .settings, onOpen: onOpen)
                StartApp(kind: .about, onOpen: onOpen)
            }

            Spacer(minLength: 0)

            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                Text("HyperDroid")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: "power")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .frame(width: 430, height: 430)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.36), radius: 28, y: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 62)
        .onTapGesture {}
    }
}

struct StartApp: View {
    let kind: HyperWindowKind
    let onOpen: (HyperWindowKind) -> Void

    var body: some View {
        Button {
            onOpen(kind)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 28, weight: .semibold))
                    .frame(width: 54, height: 54)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                Text(kind.title)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct FileExplorerPane: View {
    @State private var entries: [URL] = []

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Home", systemImage: "house.fill")
                Label("Documents", systemImage: "doc.fill")
                Label("Downloads", systemImage: "arrow.down.circle.fill")
                Spacer()
            }
            .font(.system(size: 13))
            .padding(14)
            .frame(width: 150, alignment: .leading)
            .background(Color.white.opacity(0.035))

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 16)], spacing: 18) {
                    ForEach(entries, id: \.path) { url in
                        VStack(spacing: 8) {
                            Image(systemName: url.hasDirectoryPath ? "folder.fill" : "doc.fill")
                                .font(.system(size: 30))
                                .foregroundColor(url.hasDirectoryPath ? Color.yellow : Color.white.opacity(0.8))
                            Text(url.lastPathComponent)
                                .font(.caption)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 96)
                    }

                    if entries.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "folder")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("No files yet")
                                .font(.headline)
                            Text("Files in HyperDroid's Documents folder will appear here.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(minWidth: 320, minHeight: 220)
                    }
                }
                .padding(20)
            }
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            entries = []
            return
        }

        entries = (try? FileManager.default.contentsOfDirectory(
            at: documents,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []
    }
}

struct SettingsPane: View {
    @AppStorage("hyperdroid.density") private var density = 1.0
    @AppStorage("hyperdroid.transparency") private var transparency = true

    var body: some View {
        Form {
            Section("Display") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Desktop scale: \(density, specifier: "%.2f")x")
                    Slider(value: $density, in: 0.8...1.3, step: 0.05)
                }

                Toggle("Glass effects", isOn: $transparency)
            }

            Section("Input") {
                Label("Touch, trackpad, mouse and keyboard use standard iPadOS input.", systemImage: "cursorarrow.motionlines")
            }

            Section("Port status") {
                LabeledContent("Desktop shell", value: "Working")
                LabeledContent("Floating windows", value: "Working")
                LabeledContent("Web apps", value: "Prototype")
                LabeledContent("System launcher replacement", value: "Not available on iOS")
            }
        }
    }
}

struct AboutPane: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.3.group.fill")
                .font(.system(size: 58))
                .foregroundStyle(.cyan)

            Text("HyperDroid for iOS")
                .font(.title2.bold())

            Text("An iPad-first desktop-style shell inspired by the HyperDroid Android launcher.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)

            Text("Phase 1 • Native SwiftUI port")
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
