import SwiftUI
import UIKit

struct HDWindowsCursorOverlay: View {
    @ObservedObject private var state = HDCursorState.shared
    @ObservedObject private var pack = HDCursorPackManager.shared
    @AppStorage("hd.cursorStyle") private var cursorStyle = "iPadOS"

    var body: some View {
        GeometryReader { _ in
            if cursorStyle == "Windows 11",
               pack.hasUsablePack,
               let location = state.location,
               let asset = pack.asset(for: state.kind) {
                let renderSize = renderSize(for: asset)
                let scaleX = renderSize.width / max(asset.sourceSize.width, 1)
                let scaleY = renderSize.height / max(asset.sourceSize.height, 1)

                Image(uiImage: asset.image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: renderSize.width, height: renderSize.height)
                    .position(
                        x: location.x
                            + renderSize.width / 2
                            - asset.hotspot.x * scaleX,
                        y: location.y
                            + renderSize.height / 2
                            - asset.hotspot.y * scaleY
                    )
                    .allowsHitTesting(false)
            }
        }
        .allowsHitTesting(false)
    }

    private func renderSize(for asset: HDCursorAsset) -> CGSize {
        let maxDimension = max(asset.sourceSize.width, asset.sourceSize.height)
        guard maxDimension > 0 else { return CGSize(width: 32, height: 32) }
        let scale = 32.0 / maxDimension
        return CGSize(
            width: max(12, asset.sourceSize.width * scale),
            height: max(12, asset.sourceSize.height * scale)
        )
    }
}

struct HDPointerHider: UIViewRepresentable {
    let enabled: Bool

    func makeUIView(context: Context) -> HDPointerInstallerView {
        let view = HDPointerInstallerView(frame: .zero)
        view.isHidden = true
        view.cursorEnabled = enabled
        return view
    }

    func updateUIView(_ uiView: HDPointerInstallerView, context: Context) {
        uiView.cursorEnabled = enabled
        uiView.installIfNeeded()
    }
}

final class HDPointerInstallerView: UIView, UIPointerInteractionDelegate {
    var cursorEnabled = false
    private weak var installedOn: UIView?
    private var pointerInteraction: UIPointerInteraction?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        installIfNeeded()
    }

    func installIfNeeded() {
        guard let target = window else { return }

        if installedOn !== target {
            if let oldTarget = installedOn,
               let interaction = pointerInteraction {
                oldTarget.removeInteraction(interaction)
            }

            let interaction = UIPointerInteraction(delegate: self)
            target.addInteraction(interaction)
            installedOn = target
            pointerInteraction = interaction
        }
    }

    func pointerInteraction(
        _ interaction: UIPointerInteraction,
        regionFor request: UIPointerRegionRequest,
        defaultRegion: UIPointerRegion
    ) -> UIPointerRegion? {
        guard cursorEnabled, let view = interaction.view else { return nil }
        return UIPointerRegion(rect: view.bounds, identifier: "HyperDroidWindowsCursor" as NSString)
    }

    func pointerInteraction(
        _ interaction: UIPointerInteraction,
        styleFor region: UIPointerRegion
    ) -> UIPointerStyle? {
        cursorEnabled ? UIPointerStyle.hidden() : nil
    }

    deinit {
        if let installedOn, let pointerInteraction {
            installedOn.removeInteraction(pointerInteraction)
        }
    }
}
