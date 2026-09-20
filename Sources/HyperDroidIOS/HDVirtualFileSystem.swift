import Foundation
import SwiftUI

enum HDVFSItemKind: Sendable, Hashable {
    case directory
    case file
}

struct HDVFSItem: Identifiable, Sendable, Hashable {
    let virtualPath: String
    let name: String
    let kind: HDVFSItemKind
    let size: UInt64
    let modifiedAt: Date?

    var id: String { virtualPath }
    var isDirectory: Bool { kind == .directory }
}

struct HDVFSDriveInfo: Sendable, Equatable {
    let name: String
    let driveLetter: String
    let rootPath: String
    let totalBytes: UInt64
    let freeBytes: UInt64

    var usedBytes: UInt64 {
        totalBytes > freeBytes ? totalBytes - freeBytes : 0
    }

    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1, max(0, Double(usedBytes) / Double(totalBytes)))
    }
}

enum HDVFSError: Error, CustomStringConvertible {
    case unavailable
    case invalidPath(String)
    case outsideRoot
    case itemNotFound(String)
    case notDirectory(String)
    case invalidName(String)

    var description: String {
        switch self {
        case .unavailable:
            return "The virtual file system is unavailable."
        case .invalidPath(let path):
            return "Invalid Windows path: \(path)"
        case .outsideRoot:
            return "The requested path escapes the virtual C: drive."
        case .itemNotFound(let path):
            return "Item not found: \(path)"
        case .notDirectory(let path):
            return "Not a directory: \(path)"
        case .invalidName(let name):
            return "Invalid file name: \(name)"
        }
    }
}

protocol HDFileSystemProvider: AnyObject {
    var displayName: String { get }
    var driveLetter: String { get }
    var driveRootVirtualPath: String { get }

    func prepare() throws
    func listDirectory(at virtualPath: String) throws -> [HDVFSItem]
    func driveInfo() throws -> HDVFSDriveInfo
    func createDirectory(named name: String, in parentPath: String) throws
    func deleteItem(at virtualPath: String) throws
    func renameItem(at virtualPath: String, to newName: String) throws
    func hostURL(for virtualPath: String) throws -> URL
}

/// Maps a Windows C: namespace onto a host directory.
///
/// In standalone HyperDroid this points at Documents/HyperDroidVFS/drive_c.
/// When the shell is embedded in WinPad, WinPad can point it directly at the
/// active bottle's real Bottles/<name>/drive_c URL.
final class HDHostMappedFileSystemProvider: HDFileSystemProvider {
    let displayName: String
    let driveLetter = "C:"
    let driveRootVirtualPath = "C:\\"

    private let driveCURL: URL
    private let fileManager: FileManager
    private let userName: String

    init(
        driveCURL: URL,
        displayName: String = "Local Disk",
        userName: String = "winpad",
        fileManager: FileManager = .default
    ) {
        self.driveCURL = driveCURL.standardizedFileURL
        self.displayName = displayName
        self.userName = userName
        self.fileManager = fileManager
    }

    func prepare() throws {
        let directories = [
            driveCURL,
            driveCURL.appendingPathComponent("Program Files", isDirectory: true),
            driveCURL.appendingPathComponent("Program Files (x86)", isDirectory: true),
            driveCURL.appendingPathComponent("windows", isDirectory: true),
            driveCURL.appendingPathComponent("windows/temp", isDirectory: true),
            driveCURL.appendingPathComponent("users", isDirectory: true),
            driveCURL.appendingPathComponent("users/\(userName)", isDirectory: true),
            driveCURL.appendingPathComponent("users/\(userName)/Desktop", isDirectory: true),
            driveCURL.appendingPathComponent("users/\(userName)/Documents", isDirectory: true),
            driveCURL.appendingPathComponent("users/\(userName)/Downloads", isDirectory: true),
            driveCURL.appendingPathComponent("users/\(userName)/Music", isDirectory: true),
            driveCURL.appendingPathComponent("users/\(userName)/Pictures", isDirectory: true),
            driveCURL.appendingPathComponent("users/\(userName)/Videos", isDirectory: true)
        ]

        for directory in directories {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }
    }

    func listDirectory(at virtualPath: String) throws -> [HDVFSItem] {
        let directoryURL = try hostURL(for: virtualPath)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory) else {
            throw HDVFSError.itemNotFound(virtualPath)
        }
        guard isDirectory.boolValue else {
            throw HDVFSError.notDirectory(virtualPath)
        }

        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .isHiddenKey
        ]
        let children = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: Array(keys),
            options: []
        )

        return children.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: keys) else { return nil }
            if values.isHidden == true { return nil }

            let name = url.lastPathComponent
            let childPath = Self.appendingComponent(name, to: Self.normalizeVirtualPath(virtualPath))
            return HDVFSItem(
                virtualPath: childPath,
                name: name,
                kind: values.isDirectory == true ? .directory : .file,
                size: UInt64(max(0, values.fileSize ?? 0)),
                modifiedAt: values.contentModificationDate
            )
        }
        .sorted {
            if $0.isDirectory != $1.isDirectory { return $0.isDirectory && !$1.isDirectory }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    func driveInfo() throws -> HDVFSDriveInfo {
        try prepare()
        let attributes = try fileManager.attributesOfFileSystem(forPath: driveCURL.path)
        let total = (attributes[.systemSize] as? NSNumber)?.uint64Value ?? 0
        let free = (attributes[.systemFreeSize] as? NSNumber)?.uint64Value ?? 0

        return HDVFSDriveInfo(
            name: displayName,
            driveLetter: driveLetter,
            rootPath: driveCURL.path,
            totalBytes: total,
            freeBytes: free
        )
    }

    func createDirectory(named name: String, in parentPath: String) throws {
        try Self.validateLeafName(name)
        let parentURL = try hostURL(for: parentPath)
        let childURL = parentURL.appendingPathComponent(name, isDirectory: true)
        try ensureInsideRoot(childURL)
        try fileManager.createDirectory(at: childURL, withIntermediateDirectories: false)
    }

    func deleteItem(at virtualPath: String) throws {
        let normalized = Self.normalizeVirtualPath(virtualPath)
        guard normalized.caseInsensitiveCompare(driveRootVirtualPath) != .orderedSame else {
            throw HDVFSError.invalidPath("Cannot delete the C: drive root")
        }
        let url = try hostURL(for: normalized)
        guard fileManager.fileExists(atPath: url.path) else {
            throw HDVFSError.itemNotFound(normalized)
        }
        try fileManager.removeItem(at: url)
    }

    func renameItem(at virtualPath: String, to newName: String) throws {
        try Self.validateLeafName(newName)
        let source = try hostURL(for: virtualPath)
        let destination = source.deletingLastPathComponent().appendingPathComponent(newName)
        try ensureInsideRoot(destination)
        try fileManager.moveItem(at: source, to: destination)
    }

    func hostURL(for virtualPath: String) throws -> URL {
        let normalized = Self.normalizeVirtualPath(virtualPath)
        guard normalized.count >= 2,
              normalized.prefix(2).caseInsensitiveCompare(driveLetter) == .orderedSame else {
            throw HDVFSError.invalidPath(virtualPath)
        }

        var components = normalized.dropFirst(2)
        if components.first == "\\" { components.removeFirst() }

        var url = driveCURL
        if !components.isEmpty {
            for raw in components.split(separator: "\\", omittingEmptySubsequences: true) {
                let component = String(raw)
                guard component != ".", component != "..", !component.contains("/") else {
                    throw HDVFSError.outsideRoot
                }
                url.appendPathComponent(component)
            }
        }

        try ensureInsideRoot(url)
        return url
    }

    private func ensureInsideRoot(_ url: URL) throws {
        let root = driveCURL.standardizedFileURL.path
        let candidate = url.standardizedFileURL.path
        guard candidate == root || candidate.hasPrefix(root + "/") else {
            throw HDVFSError.outsideRoot
        }
    }

    static func normalizeVirtualPath(_ raw: String) -> String {
        var path = raw.replacingOccurrences(of: "/", with: "\\")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if path.isEmpty { return "C:\\" }
        if path.caseInsensitiveCompare("C:") == .orderedSame { return "C:\\" }
        if path.count >= 2, path.prefix(2).caseInsensitiveCompare("C:") == .orderedSame {
            path = "C:" + path.dropFirst(2)
        }
        if path.count == 2 { path += "\\" }
        while path.contains("\\\\") {
            path = path.replacingOccurrences(of: "\\\\", with: "\\")
        }
        if path.count > 3, path.hasSuffix("\\") {
            path.removeLast()
        }
        return path
    }

    static func appendingComponent(_ component: String, to parent: String) -> String {
        let normalized = normalizeVirtualPath(parent)
        if normalized.hasSuffix("\\") { return normalized + component }
        return normalized + "\\" + component
    }

    private static func validateLeafName(_ name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let invalid = CharacterSet(charactersIn: "\\/:*?\"<>|")
        guard !trimmed.isEmpty,
              trimmed != ".",
              trimmed != "..",
              trimmed.rangeOfCharacter(from: invalid) == nil else {
            throw HDVFSError.invalidName(name)
        }
    }
}

@MainActor
final class HDVirtualFileSystem: ObservableObject {
    static let shared = HDVirtualFileSystem()

    @Published private(set) var generation = 0
    private(set) var provider: HDFileSystemProvider

    private init() {
        provider = HDHostMappedFileSystemProvider(
            driveCURL: Self.standaloneDriveCURL(),
            displayName: "Local Disk"
        )
        try? provider.prepare()
    }

    /// WinPad calls this before presenting HyperDroid's DesktopView.
    /// The Explorer will then browse the active Wine bottle directly.
    func configureDriveC(rootURL: URL, displayName: String = "Local Disk") {
        provider = HDHostMappedFileSystemProvider(
            driveCURL: rootURL,
            displayName: displayName
        )
        try? provider.prepare()
        generation &+= 1
    }

    func resetToStandaloneStorage() {
        provider = HDHostMappedFileSystemProvider(
            driveCURL: Self.standaloneDriveCURL(),
            displayName: "Local Disk"
        )
        try? provider.prepare()
        generation &+= 1
    }

    static func standaloneDriveCURL() -> URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        return documents
            .appendingPathComponent("HyperDroidVFS", isDirectory: true)
            .appendingPathComponent("drive_c", isDirectory: true)
    }
}

@MainActor
final class HDExplorerModel: ObservableObject {
    enum Location: Hashable {
        case home
        case folder(String)
    }

    @Published private(set) var location: Location = .home
    @Published private(set) var items: [HDVFSItem] = []
    @Published private(set) var driveInfo: HDVFSDriveInfo?
    @Published private(set) var errorMessage: String?
    @Published var searchText = ""

    private var backStack: [Location] = []
    private var forwardStack: [Location] = []
    private var observedGeneration = -1

    init() {
        reload(forceProviderRefresh: true)
    }

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }
    var canGoUp: Bool {
        guard case .folder(let path) = location else { return false }
        return HDHostMappedFileSystemProvider.normalizeVirtualPath(path)
            .caseInsensitiveCompare("C:\\") != .orderedSame
    }

    var addressText: String {
        switch location {
        case .home: return "Home"
        case .folder(let path): return HDHostMappedFileSystemProvider.normalizeVirtualPath(path)
        }
    }

    var visibleItems: [HDVFSItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var homeFolders: [(String, String, String)] {
        let base = "C:\\users\\winpad"
        return [
            ("Desktop", "img_folder_sm", "\(base)\\Desktop"),
            ("Documents", "img_folder_documents", "\(base)\\Documents"),
            ("Downloads", "img_folder_downloads", "\(base)\\Downloads"),
            ("Music", "img_folder_music", "\(base)\\Music"),
            ("Pictures", "img_folder_images", "\(base)\\Pictures"),
            ("Videos", "img_folder_videos", "\(base)\\Videos")
        ]
    }

    func openHome(recordHistory: Bool = true) {
        navigate(to: .home, recordHistory: recordHistory)
    }

    func openPath(_ path: String, recordHistory: Bool = true) {
        navigate(
            to: .folder(HDHostMappedFileSystemProvider.normalizeVirtualPath(path)),
            recordHistory: recordHistory
        )
    }

    func open(_ item: HDVFSItem) {
        guard item.isDirectory else { return }
        openPath(item.virtualPath)
    }

    func goBack() {
        guard let destination = backStack.popLast() else { return }
        forwardStack.append(location)
        location = destination
        reload()
    }

    func goForward() {
        guard let destination = forwardStack.popLast() else { return }
        backStack.append(location)
        location = destination
        reload()
    }

    func goUp() {
        guard case .folder(let path) = location else { return }
        let normalized = HDHostMappedFileSystemProvider.normalizeVirtualPath(path)
        if normalized.caseInsensitiveCompare("C:\\") == .orderedSame {
            openHome()
            return
        }

        var components = normalized.split(separator: "\\").map(String.init)
        guard components.count > 1 else {
            openHome()
            return
        }
        components.removeLast()
        let parent = components.count == 1 ? "C:\\" : components.joined(separator: "\\")
        openPath(parent)
    }

    func reload(forceProviderRefresh: Bool = false) {
        let service = HDVirtualFileSystem.shared
        if forceProviderRefresh || observedGeneration != service.generation {
            observedGeneration = service.generation
        }

        do {
            try service.provider.prepare()
            driveInfo = try service.provider.driveInfo()
            switch location {
            case .home:
                items = []
            case .folder(let path):
                items = try service.provider.listDirectory(at: path)
            }
            errorMessage = nil
        } catch {
            items = []
            errorMessage = String(describing: error)
        }
    }

    func createFolder(named name: String) {
        guard case .folder(let path) = location else { return }
        do {
            try HDVirtualFileSystem.shared.provider.createDirectory(named: name, in: path)
            reload()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func delete(_ item: HDVFSItem) {
        do {
            try HDVirtualFileSystem.shared.provider.deleteItem(at: item.virtualPath)
            reload()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func rename(_ item: HDVFSItem, to newName: String) {
        do {
            try HDVirtualFileSystem.shared.provider.renameItem(at: item.virtualPath, to: newName)
            reload()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func hostURL(for item: HDVFSItem) -> URL? {
        try? HDVirtualFileSystem.shared.provider.hostURL(for: item.virtualPath)
    }

    private func navigate(to destination: Location, recordHistory: Bool) {
        if destination == location {
            reload()
            return
        }
        if recordHistory {
            backStack.append(location)
            forwardStack.removeAll()
        }
        location = destination
        searchText = ""
        reload()
    }
}
