import SwiftUI
import UIKit

final class HDWallpaperManager: ObservableObject {
    static let shared = HDWallpaperManager()

    @Published private(set) var image: UIImage?

    private let fileURL: URL

    private init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent("HyperDroid", isDirectory: true)

        try? fm.createDirectory(
            at: folder,
            withIntermediateDirectories: true,
            attributes: nil
        )

        fileURL = folder.appendingPathComponent("custom_wallpaper.jpg")

        if let data = try? Data(contentsOf: fileURL),
           let loaded = UIImage(data: data) {
            image = loaded
        }
    }

    var hasCustomWallpaper: Bool {
        image != nil
    }

    func install(data: Data) throws {
        guard let decoded = UIImage(data: data) else {
            throw HDWallpaperError.invalidImage
        }

        guard let encoded = decoded.jpegData(compressionQuality: 0.92) else {
            throw HDWallpaperError.encodingFailed
        }

        try encoded.write(to: fileURL, options: .atomic)
        image = decoded
    }

    func clear() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: fileURL.path) {
            try fm.removeItem(at: fileURL)
        }
        image = nil
    }
}

private enum HDWallpaperError: LocalizedError {
    case invalidImage
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected file is not a supported image."
        case .encodingFailed:
            return "HyperDroid could not save that image as a wallpaper."
        }
    }
}
