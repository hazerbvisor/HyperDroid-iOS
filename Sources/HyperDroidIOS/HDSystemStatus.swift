import SwiftUI
import UIKit
import Network
import AVFoundation
import MediaPlayer

final class HDSystemStatus: ObservableObject, @unchecked Sendable {
    static let shared = HDSystemStatus()

    @Published private(set) var batteryPercent: Int = 100
    @Published private(set) var charging = false
    @Published private(set) var networkConnected = true
    @Published private(set) var networkKind = "Network"
    @Published private(set) var outputVolume: Float = 0.5

    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "HyperDroid.SystemStatus")
    private var timer: Timer?

    private init() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let kind: String
            if path.usesInterfaceType(.wifi) {
                kind = "Wi-Fi"
            } else if path.usesInterfaceType(.cellular) {
                kind = "Cellular"
            } else if path.usesInterfaceType(.wiredEthernet) {
                kind = "Ethernet"
            } else {
                kind = connected ? "Network" : "Offline"
            }

            DispatchQueue.main.async {
                self?.networkConnected = connected
                self?.networkKind = kind
            }
        }
        pathMonitor.start(queue: monitorQueue)

        DispatchQueue.main.async { [weak self] in
            UIDevice.current.isBatteryMonitoringEnabled = true
            self?.refreshLiveState()
            self?.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.refreshLiveState()
            }
        }
    }

    private func refreshLiveState() {
        let device = UIDevice.current
        let level = device.batteryLevel
        if level >= 0 {
            batteryPercent = min(100, max(0, Int((level * 100).rounded())))
        }

        switch device.batteryState {
        case .charging, .full:
            charging = true
        default:
            charging = false
        }

        outputVolume = AVAudioSession.sharedInstance().outputVolume
    }
}

struct HDSystemVolumeView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.showsRouteButton = false
        view.showsVolumeSlider = true
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
