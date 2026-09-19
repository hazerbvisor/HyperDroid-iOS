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
        var firstFailure: Error?
        let supported = Set(HDCursorKind.allCases.map(\.fileName))

        for url in urls {
            let name = url.lastPathComponent.lowercased()
            guard supported.contains(name) else { continue }

            let secured = url.startAccessingSecurityScopedResource()
            defer {
                if secured {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: url)

                guard data.count >= 6,
                      Self.readUInt16(data, 0) == 0,
                      Self.readUInt16(data, 2) == 2 else {
                    throw NSError(
                        domain: "HyperDroid.CursorImport",
                        code: 2,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "\(url.lastPathComponent) is not a valid Windows .cur file."
                        ]
                    )
                }

                let destination = packDirectory.appendingPathComponent(name)
                try data.write(to: destination, options: .atomic)
                imported += 1
            } catch {
                if firstFailure == nil {
                    firstFailure = error
                }
            }
        }

        reload()

        if imported == 0, let firstFailure {
            throw firstFailure
        }

        return imported
    }

    func installFromSource(variant: String) async throws -> Int {
        let normalizedVariant = variant.lowercased() == "dark" ? "dark" : "light"
        let base = "https://raw.githubusercontent.com/SullensCR/Windows-11-Hdpi-Tail-Cursor-Concept-by-jepriCreations/v2/cursor/assets/\(normalizedVariant)"

        try FileManager.default.createDirectory(
            at: packDirectory,
            withIntermediateDirectories: true
        )

        var installed = 0

        for kind in HDCursorKind.allCases {
            guard let url = URL(string: base + "/" + kind.fileName) else {
                continue
            }

            let (data, response) = try await URLSession.shared.data(from: url)

            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200 else {
                throw NSError(
                    domain: "HyperDroid.CursorInstall",
                    code: 20,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Failed to download \(kind.fileName) from the cursor source."
                    ]
                )
            }

            guard data.count >= 6,
                  Self.readUInt16(data, 0) == 0,
                  Self.readUInt16(data, 2) == 2 else {
                throw NSError(
                    domain: "HyperDroid.CursorInstall",
                    code: 21,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Downloaded \(kind.fileName) is not a valid Windows cursor."
                    ]
                )
            }

            let destination = packDirectory.appendingPathComponent(kind.fileName)
            try data.write(to: destination, options: .atomic)
            installed += 1
        }

        reload()
        return installed
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

            if let image = decodeCursorImage(payload) {
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

    private static func decodeCursorImage(_ payload: Data) -> UIImage? {
        if let image = UIImage(data: payload) {
            return image
        }
        return decodeDIB(payload)
    }

    private static func decodeDIB(_ data: Data) -> UIImage? {
        guard data.count >= 40 else { return nil }

        let headerSize = Int(readUInt32(data, 0))
        let widthValue = Int32(bitPattern: readUInt32(data, 4))
        let heightValue = Int32(bitPattern: readUInt32(data, 8))
        let planes = readUInt16(data, 12)
        let bitsPerPixel = readUInt16(data, 14)
        let compression = readUInt32(data, 16)

        guard headerSize >= 40,
              widthValue > 0,
              heightValue != 0,
              planes == 1,
              bitsPerPixel == 32,
              compression == 0 else {
            return nil
        }

        let width = Int(widthValue)
        let storedHeight = abs(Int(heightValue))
        let height = storedHeight / 2
        guard width > 0, height > 0 else { return nil }

        let pixelOffset = headerSize
        let rowBytes = width * 4
        let xorByteCount = rowBytes * height
        guard pixelOffset + xorByteCount <= data.count else { return nil }

        let maskRowBytes = ((width + 31) / 32) * 4
        let maskOffset = pixelOffset + xorByteCount
        let hasMask = maskOffset + (maskRowBytes * height) <= data.count
        let topDown = heightValue < 0

        var rgba = Data(count: width * height * 4)
        var sawAlpha = false

        rgba.withUnsafeMutableBytes { destinationRaw in
            data.withUnsafeBytes { sourceRaw in
                let destination = destinationRaw.bindMemory(to: UInt8.self)
                let source = sourceRaw.bindMemory(to: UInt8.self)

                for y in 0..<height {
                    let sourceY = topDown ? y : (height - 1 - y)

                    for x in 0..<width {
                        let sourceIndex = pixelOffset + (sourceY * rowBytes) + (x * 4)
                        let destinationIndex = ((y * width) + x) * 4

                        let blue = source[sourceIndex]
                        let green = source[sourceIndex + 1]
                        let red = source[sourceIndex + 2]
                        let alpha = source[sourceIndex + 3]

                        if alpha != 0 {
                            sawAlpha = true
                        }

                        destination[destinationIndex] = red
                        destination[destinationIndex + 1] = green
                        destination[destinationIndex + 2] = blue
                        destination[destinationIndex + 3] = alpha
                    }
                }
            }
        }

        if !sawAlpha && hasMask {
            rgba.withUnsafeMutableBytes { destinationRaw in
                data.withUnsafeBytes { sourceRaw in
                    let destination = destinationRaw.bindMemory(to: UInt8.self)
                    let source = sourceRaw.bindMemory(to: UInt8.self)

                    for y in 0..<height {
                        let sourceY = topDown ? y : (height - 1 - y)
                        let maskRow = maskOffset + (sourceY * maskRowBytes)

                        for x in 0..<width {
                            let byte = source[maskRow + (x / 8)]
                            let bit = (byte >> UInt8(7 - (x % 8))) & 1
                            let destinationIndex = ((y * width) + x) * 4
                            destination[destinationIndex + 3] = bit == 0 ? 255 : 0
                        }
                    }
                }
            }
        }

        guard let provider = CGDataProvider(data: rgba as CFData) else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)

        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
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
