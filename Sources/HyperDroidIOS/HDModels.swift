import SwiftUI

struct HDAppEntry: Identifiable, Hashable {
    enum Kind: Hashable { case explorer, settings, chrome, photos, music, notepad, installer }
    let id = UUID()
    let title: String
    let asset: String
    let kind: Kind
}

extension HDAppEntry {
    static let builtIns: [HDAppEntry] = [
        .init(title: "File Explorer", asset: "img_app_explorer", kind: .explorer),
        .init(title: "Chrome", asset: "img_app_chrome", kind: .chrome),
        .init(title: "Settings", asset: "img_app_settings", kind: .settings),
        .init(title: "Photos", asset: "img_app_photos", kind: .photos),
        .init(title: "Music", asset: "img_app_music", kind: .music),
        .init(title: "Notepad", asset: "img_app_notepad", kind: .notepad),
        .init(title: "Installer", asset: "img_app_installer", kind: .installer)
    ]
}

enum HDWindowKind: Hashable {
    case explorer, settings, chrome, photos, music, notepad, installer

    var title: String {
        switch self {
        case .explorer: return "This PC"
        case .settings: return "Settings"
        case .chrome: return "Chrome"
        case .photos: return "Photos"
        case .music: return "Music"
        case .notepad: return "Notepad"
        case .installer: return "App Installer"
        }
    }

    var asset: String {
        switch self {
        case .explorer: return "img_app_explorer"
        case .settings: return "img_app_settings"
        case .chrome: return "img_app_chrome"
        case .photos: return "img_app_photos"
        case .music: return "img_app_music"
        case .notepad: return "img_app_notepad"
        case .installer: return "img_app_installer"
        }
    }
}

struct HDWindowState: Identifiable, Equatable {
    let id: UUID
    let kind: HDWindowKind
    var center: CGPoint
    var size: CGSize
    var z: Int
    var maximized: Bool
    var minimized: Bool

    init(kind: HDWindowKind, center: CGPoint, size: CGSize, z: Int) {
        self.id = UUID()
        self.kind = kind
        self.center = center
        self.size = size
        self.z = z
        self.maximized = false
        self.minimized = false
    }
}

@MainActor
final class HDDesktopController: ObservableObject {
    @Published var startMenuVisible = false
    @Published var windows: [HDWindowState] = []
    @Published var activeWindowID: UUID?
    private var nextZ = 1

    func open(_ kind: HDWindowKind, desktop: CGSize, taskbarHeight: CGFloat) {
        if let existing = windows.first(where: { $0.kind == kind }) {
            restore(existing.id)
            startMenuVisible = false
            return
        }

        let availableHeight = max(360, desktop.height - taskbarHeight)
        let size = CGSize(
            width: min(920, desktop.width * 0.82),
            height: min(640, availableHeight * 0.82)
        )

        if UserDefaults.standard.object(forKey: "hd.multitasking") != nil,
           !UserDefaults.standard.bool(forKey: "hd.multitasking") {
            windows.removeAll()
            activeWindowID = nil
        }

        let state = HDWindowState(
            kind: kind,
            center: CGPoint(x: desktop.width / 2, y: availableHeight / 2),
            size: size,
            z: nextZ
        )
        nextZ += 1

        withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
            windows.append(state)
            activeWindowID = state.id
            startMenuVisible = false
        }
    }

    func focus(_ id: UUID) {
        guard let i = windows.firstIndex(where: { $0.id == id }), !windows[i].minimized else { return }
        if activeWindowID == id { return }
        windows[i].z = nextZ
        nextZ += 1
        activeWindowID = id
    }

    func minimize(_ id: UUID) {
        guard let i = windows.firstIndex(where: { $0.id == id }), !windows[i].minimized else { return }
        withAnimation(.easeInOut(duration: 0.20)) {
            windows[i].minimized = true
            if activeWindowID == id {
                activeWindowID = topVisibleWindow(excluding: id)?.id
            }
        }
    }

    func restore(_ id: UUID) {
        guard let i = windows.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.26, dampingFraction: 0.90)) {
            windows[i].minimized = false
            windows[i].z = nextZ
            nextZ += 1
            activeWindowID = id
        }
    }

    func taskbarAction(_ id: UUID) {
        guard let window = windows.first(where: { $0.id == id }) else { return }
        if window.minimized {
            restore(id)
        } else if activeWindowID == id {
            minimize(id)
        } else {
            focus(id)
        }
    }

    func close(_ id: UUID) {
        withAnimation(.easeIn(duration: 0.22)) {
            windows.removeAll { $0.id == id }
            if activeWindowID == id {
                activeWindowID = topVisibleWindow(excluding: id)?.id
            }
        }
    }

    func move(_ id: UUID, by delta: CGSize, desktop: CGSize, taskbarHeight: CGFloat) {
        guard let i = windows.firstIndex(where: { $0.id == id }),
              !windows[i].maximized,
              !windows[i].minimized else { return }

        let availableHeight = max(1, desktop.height - taskbarHeight)
        let nextX = windows[i].center.x + delta.width
        let nextY = windows[i].center.y + delta.height

        windows[i].center.x = min(max(nextX, 90), max(90, desktop.width - 90))
        windows[i].center.y = min(max(nextY, 20), max(20, availableHeight - 20))
    }

    func toggleMaximize(_ id: UUID) {
        guard let i = windows.firstIndex(where: { $0.id == id }), !windows[i].minimized else { return }
        focus(id)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.90)) {
            windows[i].maximized.toggle()
        }
    }

    private func topVisibleWindow(excluding id: UUID? = nil) -> HDWindowState? {
        windows
            .filter { !$0.minimized && $0.id != id }
            .max(by: { $0.z < $1.z })
    }
}
