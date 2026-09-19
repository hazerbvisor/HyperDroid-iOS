import SwiftUI

struct HDActionCenterView: View {
    let onOpenSettings: () -> Void

    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var system = HDSystemStatus.shared

    @AppStorage("hd.bluetooth") private var bluetooth = true
    @AppStorage("hd.nearbySharing") private var nearbySharing = true
    @AppStorage("hd.webAccess") private var webAccess = true
    @AppStorage("hd.theme") private var theme = "Dark"
    @AppStorage("hd.transparency") private var transparency = true

    @State private var accessibility = false
    @State private var detail: String?

    private var p: HDPalette { HDPalette(scheme: scheme) }

    private let items: [(String, String)] = [
        ("Wi-Fi", "menu_ic_wifi_4_20_regular"),
        ("Internet", "menu_ic_internet_20_regular"),
        ("Bluetooth", "menu_ic_bluetooth_20_regular"),
        ("Nearby sharing", "menu_ic_share_20_regular"),
        ("Theme", "menu_ic_theme_current_20_regular"),
        ("Accessibility", "menu_ic_accessibility_20_regular")
    ]

    var body: some View {
        VStack(spacing: 0) {
            if let detail {
                networkDetail(detail)
                    .padding(14)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                    spacing: 12
                ) {
                    ForEach(items, id: \.0) { item in
                        VStack(spacing: 6) {
                            Button {
                                activate(item.0)
                            } label: {
                                HDImage(
                                    name: item.1,
                                    template: true,
                                    tint: isEnabled(item.0) ? .white : p.text
                                )
                                .frame(width: 20, height: 20)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(isEnabled(item.0) ? p.primary : p.dialogBody.opacity(0.72))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(p.border.opacity(0.45), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            Text(item.0)
                                .font(.system(size: 11))
                                .foregroundColor(p.text)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
                .padding(20)
            }

            VStack(spacing: 7) {
                HStack {
                    HDImage(
                        name: "ui_tb_speaker_2_24_regular",
                        template: true,
                        tint: p.text
                    )
                    .frame(width: 20, height: 20)

                    HDSystemVolumeView()
                        .frame(height: 30)

                    Text("\(Int((system.outputVolume * 100).rounded()))%")
                        .font(.system(size: 10.5))
                        .foregroundColor(p.mutedText)
                        .frame(width: 34, alignment: .trailing)
                }

                HStack {
                    Image(systemName: system.networkConnected ? "network" : "network.slash")
                        .font(.system(size: 11))
                    Text(system.networkConnected ? system.networkKind : "Offline")
                        .font(.system(size: 10.5))
                    Spacer()
                }
                .foregroundColor(p.mutedText)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)

            HStack {
                HStack(spacing: 6) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: batterySymbol)
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 22, height: 20)

                        if system.charging {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(p.primary)
                                .offset(x: 4, y: -3)
                        }
                    }

                    Text("\(system.batteryPercent)%")
                        .font(.system(size: 11.5))
                }

                Spacer()

                Button(action: onOpenSettings) {
                    HDImage(name: "ic_settings_24_regular", template: true, tint: p.text)
                        .frame(width: 20, height: 20)
                        .frame(width: 38, height: 36)
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(p.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(p.footer)
        }
        .frame(width: 330)
        .background {
            HDGlassSurface(
                tint: p.startMenu,
                enabled: transparency,
                tintOpacity: scheme == .dark ? 0.64 : 0.78
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(p.border.opacity(0.8), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 12, y: 5)
    }

    private var batterySymbol: String {
        switch system.batteryPercent {
        case 0..<13: return "battery.0"
        case 13..<38: return "battery.25"
        case 38..<63: return "battery.50"
        case 63..<88: return "battery.75"
        default: return "battery.100"
        }
    }

    @ViewBuilder
    private func networkDetail(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(p.text)
                Spacer()
                Button("Done") {
                    detail = nil
                }
                .font(.system(size: 11.5, weight: .semibold))
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 10) {
                Image(systemName: system.networkConnected ? "wifi" : "network.slash")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(system.networkConnected ? p.primary : p.mutedText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(system.networkConnected ? system.networkKind : "Offline")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(p.text)
                    Text(system.networkConnected ? "iPadOS reports an active connection" : "No active network connection")
                        .font(.system(size: 10.5))
                        .foregroundColor(p.mutedText)
                }
                Spacer()
            }

            Toggle("HyperDroid web access", isOn: $webAccess)
                .font(.system(size: 11.5))
                .foregroundColor(p.text)

            Button("See more") {
                onOpenSettings()
            }
            .font(.system(size: 11.5, weight: .semibold))
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(p.dialogBody.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(p.border.opacity(0.45), lineWidth: 1)
        )
    }

    private func activate(_ item: String) {
        switch item {
        case "Wi-Fi", "Internet":
            detail = item
        default:
            toggle(item)
        }
    }

    private func isEnabled(_ item: String) -> Bool {
        switch item {
        case "Wi-Fi", "Internet":
            return system.networkConnected && webAccess
        case "Bluetooth":
            return bluetooth
        case "Nearby sharing":
            return nearbySharing
        case "Theme":
            return theme == "Dark"
        case "Accessibility":
            return accessibility
        default:
            return false
        }
    }

    private func toggle(_ item: String) {
        switch item {
        case "Wi-Fi", "Internet":
            webAccess.toggle()
        case "Bluetooth":
            bluetooth.toggle()
        case "Nearby sharing":
            nearbySharing.toggle()
        case "Theme":
            theme = theme == "Dark" ? "Light" : "Dark"
        case "Accessibility":
            accessibility.toggle()
        default:
            break
        }
    }
}

struct HDCalendarPanelView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var date = Date()
    @AppStorage("hd.transparency") private var transparency = true

    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 14))
                    .foregroundColor(p.text)

                Spacer()

                HDImage(name: "ic_arrow_down_14_light", template: true, tint: p.text)
                    .frame(width: 14, height: 14)
                    .frame(width: 26, height: 26)
                    .background(p.dialogBody.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(p.footer)

            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .frame(width: 340)
        .background {
            HDGlassSurface(
                tint: p.startMenu,
                enabled: transparency,
                tintOpacity: scheme == .dark ? 0.64 : 0.78
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(p.border.opacity(0.8), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 12, y: 5)
    }
}

struct HDMoreIconsPanelView: View {
    let onOpenInstaller: () -> Void

    @Environment(\.colorScheme) private var scheme
    @AppStorage("hd.transparency") private var transparency = true

    private var p: HDPalette { HDPalette(scheme: scheme) }

    var body: some View {
        HStack(spacing: 0) {
            popupButton("img_defender", action: {})
            popupButton("img_mouse", action: {})
            popupButton("img_file_apk", action: onOpenInstaller)
        }
        .padding(4)
        .background {
            HDGlassSurface(
                tint: p.startMenu,
                enabled: transparency,
                tintOpacity: scheme == .dark ? 0.64 : 0.78
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(p.border.opacity(0.8), lineWidth: 1))
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
    }

    private func popupButton(_ asset: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HDImage(name: asset)
                .frame(width: 22, height: 22)
                .frame(width: 42, height: 42)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
