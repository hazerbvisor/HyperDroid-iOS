import SwiftUI
import UIKit

struct HDMetrics {
    let landscape: Bool

    var taskbarHeight: CGFloat { landscape ? 52 : 78 }
    var taskbarAppSize: CGFloat { landscape ? 26 : 40 }
    var taskbarAppPaddingHorizontal: CGFloat { landscape ? 8.6 : 10 }
    var taskbarMarginBottom: CGFloat { landscape ? 0 : 8 }
    var taskbarMarginHorizontal: CGFloat { landscape ? 0 : 14 }

    var startAppIconSize: CGFloat { landscape ? 32 : 48 }
    var startAppWidth: CGFloat { landscape ? 76 : 80 }
    var startAppHeight: CGFloat { landscape ? 74 : 80 }
    var startGridHeight: CGFloat { landscape ? 222 : 320 }
    var startGridPaddingHorizontal: CGFloat { landscape ? 28 : 8 }
    var startRadius: CGFloat { landscape ? 10 : 14 }
    var startHeaderFontSize: CGFloat { landscape ? 12.8 : 15.4 }
    var startMarginBottom: CGFloat { landscape ? 52 : 86 }
    var startBodyPaddingHorizontal: CGFloat { landscape ? 44 : 26 }
    var startFooterPadding: CGFloat { landscape ? 8.6 : 6 }
    var startTitlePaddingHorizontal: CGFloat { landscape ? 50 : 26 }
    var startMaxHeight: CGFloat { 600 }
    var startMinHeight: CGFloat { 418 }

    static func forSize(_ size: CGSize) -> HDMetrics {
        HDMetrics(landscape: size.width > size.height)
    }
}

struct HDPalette {
    let scheme: ColorScheme

    var text: Color { scheme == .dark ? .white : .black }
    var mutedText: Color { scheme == .dark ? Color.white.opacity(0.70) : Color.black.opacity(0.70) }
    var startMenu: Color { scheme == .dark ? Color(hex: 0x242424) : Color(hex: 0xF2F2F2) }
    var taskbar: Color { scheme == .dark ? Color(hex: 0x1C1C1C) : Color(hex: 0xEEEEEE) }
    var explorer: Color { scheme == .dark ? Color(hex: 0x191919) : .white }
    var dialog: Color { scheme == .dark ? Color(hex: 0x202020) : Color(hex: 0xF3F3F3) }
    var dialogDark: Color { scheme == .dark ? Color(hex: 0x202020) : Color(hex: 0xE8E8E8) }
    var dialogBody: Color { scheme == .dark ? Color(hex: 0x272727) : Color(hex: 0xF9F9F9) }
    var border: Color { scheme == .dark ? Color(hex: 0x323232) : Color(hex: 0xCFCFCF) }
    var footer: Color { scheme == .dark ? Color.black.opacity(0.22) : Color(hex: 0xEAEAEA).opacity(0.30) }
    var primary: Color { Color(red: 0.0, green: 0.47, blue: 0.84) }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255.0,
            green: Double((hex >> 8) & 0xff) / 255.0,
            blue: Double(hex & 0xff) / 255.0,
            opacity: alpha
        )
    }
}

enum HDAsset {
    private static let atlas: UIImage? = {
        guard let url = Bundle.main.url(forResource: "hyperdroid_ui_atlas", withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }()

    static func uiImage(_ name: String, template: Bool = false) -> UIImage? {
        if let atlas, let rect = HDAtlas.rects[name], let cg = atlas.cgImage {
            let scaleX = CGFloat(cg.width) / atlas.size.width
            let scaleY = CGFloat(cg.height) / atlas.size.height
            let pixelRect = CGRect(
                x: rect.origin.x * scaleX,
                y: rect.origin.y * scaleY,
                width: rect.size.width * scaleX,
                height: rect.size.height * scaleY
            ).integral
            if let cropped = cg.cropping(to: pixelRect) {
                let image = UIImage(cgImage: cropped, scale: atlas.scale, orientation: .up)
                return template ? image.withRenderingMode(.alwaysTemplate) : image
            }
        }
        return HDExtraAssets.image(name, template: template)
    }
}

struct HDImage: View {
    let name: String
    var template = false
    var tint: Color = .primary
    var contentMode: ContentMode = .fit

    var body: some View {
        if let image = HDAsset.uiImage(name, template: template) {
            Image(uiImage: image)
                .resizable()
                .renderingMode(template ? .template : .original)
                .foregroundColor(template ? tint : nil)
                .aspectRatio(contentMode: contentMode)
        } else {
            Color.clear
        }
    }
}
