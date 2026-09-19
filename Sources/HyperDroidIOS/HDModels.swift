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

    init(kind: HDWindowKind, center: CGPoint, size: CGSize, z: Int) {
        self.id = UUID()
        self.kind = kind
        self.center = center
        self.size = size
        self.z = z
        self.maximized = false
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
            focus(existing.id)
            startMenuVisible = false
            return
        }
        let availableHeight = max(360, desktop.height - taskbarHeight)
        let size = CGSize(width: min(920, desktop.width * 0.82), height: min(640, availableHeight * 0.82))
        let state = HDWindowState(kind: kind,
                                  center: CGPoint(x: desktop.width / 2, y: availableHeight / 2),
                                  size: size,
                                  z: nextZ)
        nextZ += 1
        windows.append(state)
        activeWindowID = state.id
        startMenuVisible = false
    }

    func focus(_ id: UUID) {
        guard let i = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[i].z = nextZ
        nextZ += 1
        activeWindowID = id
    }

    func close(_ id: UUID) {
        windows.removeAll { $0.id == id }
        activeWindowID = windows.max(by: { $0.z < $1.z })?.id
    }

    func move(_ id: UUID, by delta: CGSize) {
        guard let i = windows.firstIndex(where: { $0.id == id }), !windows[i].maximized else { return }
        windows[i].center.x += delta.width
        windows[i].center.y += delta.height
    }

    func toggleMaximize(_ id: UUID) {
        guard let i = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[i].maximized.toggle()
        focus(id)
    }
}
