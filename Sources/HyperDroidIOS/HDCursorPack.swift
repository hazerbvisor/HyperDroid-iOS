import SwiftUI
import UIKit

enum HDCursorKind: String, CaseIterable {
    case arrow
    case hand
    case ibeam
    case sizeWE = "sizewe"
    case sizeNS = "sizens"
    case sizeNWSE = "sizenwse"
    case sizeNESW = "sizenesw"
    case sizeAll = "sizeall"
    case no
    case help
    case crosshair
    case upArrow = "uparrow"
    case pen = "nwpen"
    case person
    case pin

    var fileName: String { rawValue + ".cur" }
}

struct HDCursorAsset {
    let image: UIImage
    let hotspot: CGPoint
    let sourceSize: CGSize
}

@MainActor
final class HDCursorPackManager: ObservableObject {
    static let shared = HDCursorPackManager()

    @Published private(set) var installedNames: Set<String> = []
    private var cache: [HDCursorKind: HDCursorAsset] = [:]

    private init() {
        reload()
    }

    var installedCount: Int { installedNames.count }
    var hasUsablePack: Bool { installedNames.contains(HDCursorKind.arrow.fileName) }

    func asset(for kind: HDCursorKind) -> HDCursorAsset? {
        if let cached = cache[kind] {
            return cached
        }

        let url = packDirectory.appendingPathComponent(kind.fileName)
        guard let data = try? Data(contentsOf: url),
              let asset = Self.decodeCUR(data) else {
            return kind == .arrow ? nil : asset(for: .arrow)
        }

        cache[kind] = asset
        return asset
    }

    @discardableResult
    func importCursorFiles(_ urls: [URL]) throws -> Int {
        try FileManager.default.createDirectory(
            at: packDirectory,
            withIntermediateDirectories: true
        )

        var imported = 0
        let supported = Set(HDCursorKind.allCases.map(\.fileName))

        for url in urls {
            let name = url.lastPathComponent.lowercased()
            guard supported.contains(name) else { continue }

            let scoped = url.startAccessingSecurityScopedResource()
            defer {
                if scoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let destination = packDirectory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: url, to: destination)
            imported += 1
        }

        reload()
        return imported
    }

    func clearImportedPack() throws {
        if FileManager.default.fileExists(atPath: packDirectory.path) {
            try FileManager.default.removeItem(at: packDirectory)
        }
        reload()
    }

    func reload() {
        cache.removeAll()
        let names = (try? FileManager.default.contentsOfDirectory(
            atPath: packDirectory.path
        )) ?? []
        installedNames = Set(names.map { $0.lowercased() })
    }

    private var packDirectory: URL {
        let root = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return root
            .appendingPathComponent("HyperDroid", isDirectory: true)
            .appendingPathComponent("Windows11CursorPack", isDirectory: true)
    }

    private struct Entry {
        let width: Int
        let height: Int
        let hotspotX: Int
        let hotspotY: Int
        let byteCount: Int
        let offset: Int
    }

    private static func decodeCUR(_ data: Data) -> HDCursorAsset? {
        guard data.count >= 6,
              readUInt16(data, 0) == 0,
              readUInt16(data, 2) == 2 else {
            return UIImage(data: data).map {
                HDCursorAsset(
                    image: $0,
                    hotspot: .zero,
                    sourceSize: $0.size
                )
            }
        }

        let count = Int(readUInt16(data, 4))
        guard count > 0, data.count >= 6 + (count * 16) else { return nil }

        var candidates: [(entry: Entry, image: UIImage, png: Bool)] = []

        for index in 0..<count {
            let base = 6 + (index * 16)
            let widthByte = Int(data[base])
            let heightByte = Int(data[base + 1])
            let width = widthByte == 0 ? 256 : widthByte
            let height = heightByte == 0 ? 256 : heightByte
            let hotspotX = Int(readUInt16(data, base + 4))
            let hotspotY = Int(readUInt16(data, base + 6))
            let byteCount = Int(readUInt32(data, base + 8))
            let offset = Int(readUInt32(data, base + 12))

            guard byteCount > 0,
                  offset >= 0,
                  offset + byteCount <= data.count else { continue }

            let payload = data.subdata(in: offset..<(offset + byteCount))
            let isPNG = payload.count >= 8
                && Array(payload.prefix(8)) == [137, 80, 78, 71, 13, 10, 26, 10]

            if let image = UIImage(data: payload) {
                candidates.append((
                    Entry(
                        width: width,
                        height: height,
                        hotspotX: hotspotX,
                        hotspotY: hotspotY,
                        byteCount: byteCount,
                        offset: offset
                    ),
                    image,
                    isPNG
                ))
            }
        }

        guard !candidates.isEmpty else {
            return UIImage(data: data).map {
                HDCursorAsset(
                    image: $0,
                    hotspot: .zero,
                    sourceSize: $0.size
                )
            }
        }

        // Prefer a Windows-like 32 px cursor. If only the high-DPI PNG
        // representation is decodable, use it and scale the hotspot with it.
        let selected = candidates.min { lhs, rhs in
            let lhsPenalty = abs(lhs.entry.width - 32) + (lhs.png ? 0 : 6)
            let rhsPenalty = abs(rhs.entry.width - 32) + (rhs.png ? 0 : 6)
            return lhsPenalty < rhsPenalty
        }!

        return HDCursorAsset(
            image: selected.image,
            hotspot: CGPoint(
                x: selected.entry.hotspotX,
                y: selected.entry.hotspotY
            ),
            sourceSize: CGSize(
                width: selected.entry.width,
                height: selected.entry.height
            )
        )
    }

    private static func readUInt16(_ data: Data, _ offset: Int) -> UInt16 {
        guard offset + 2 <= data.count else { return 0 }
        return UInt16(data[offset])
            | (UInt16(data[offset + 1]) << 8)
    }

    private static func readUInt32(_ data: Data, _ offset: Int) -> UInt32 {
        guard offset + 4 <= data.count else { return 0 }
        return UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}

@MainActor
final class HDCursorState: ObservableObject {
    static let shared = HDCursorState()

    @Published var location: CGPoint?
    @Published var kind: HDCursorKind = .arrow

    private init() {}

    func update(_ phase: HoverPhase) {
        switch phase {
        case .active(let location):
            self.location = location
        case .ended:
            location = nil
            kind = .arrow
        }
    }

    func setKind(_ kind: HDCursorKind, active: Bool) {
        self.kind = active ? kind : .arrow
    }
}

private struct HDCursorHoverModifier: ViewModifier {
    let kind: HDCursorKind

    func body(content: Content) -> some View {
        content.onHover { inside in
            HDCursorState.shared.setKind(kind, active: inside)
        }
    }
}

extension View {
    func hdCursor(_ kind: HDCursorKind) -> some View {
        modifier(HDCursorHoverModifier(kind: kind))
    }
}
